param(
    [Parameter(Mandatory=$true)]
    [string]$encryptionKeyBase64,
    [string]$encryptedHashPath = "C:\ProgramData\EncryptedHash_FFI.xml",
    [Parameter(Mandatory=$true)]
    [string]$scriptPath = "",
    [switch]$help
)

if ($help) {
    Write-Output "This script checks the integrity of a target script by comparing its hash with a pre-encrypted hash value."
    Write-Output "Usage: VerifyScriptIntegrity.ps1 [-encryptionKeyBase64 <key>] [-encryptedHashPath <path>] [-scriptPath <path>] [-help]"
    Write-Output "  -encryptionKeyBase64  : The Base64 encoded encryption key used to decrypt the pre-encrypted hash value."
    Write-Output "  -encryptedHashPath    : The path to the file containing the pre-encrypted hash value and encryption details."
    Write-Output "  -scriptPath           : The path to the target script whose integrity will be verified."
    Write-Output "  -help                 : Display this help message."
    Exit
}

try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-Warning "This script requires administrative privileges. Please run it as an administrator."
        Exit
    }

    # Import the encrypted hash and decryption details
    $decryptionDetails = Get-Content -Path $encryptedHashPath | ConvertFrom-Json
    $encryptedHashBase64 = $decryptionDetails.EncryptedHash
    $IVBase64 = $decryptionDetails.IV

    # Decode the encryption key and IV from Base64
    $encryptionKey = [Convert]::FromBase64String($encryptionKeyBase64)
    $IV = [Convert]::FromBase64String($IVBase64)
    
    # Decrypt the hash
    $aesProvider = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $aesProvider.Key = $encryptionKey
    $aesProvider.IV = $IV
    $decryptor = $aesProvider.CreateDecryptor()

    $encryptedHashBytes = [Convert]::FromBase64String($encryptedHashBase64)
    $expectedHashBytes = $decryptor.TransformFinalBlock($encryptedHashBytes, 0, $encryptedHashBytes.Length)
    $expectedHash = [System.Text.Encoding]::UTF8.GetString($expectedHashBytes)

    # Compute the current hash of the script
    $currentHash = (Get-FileHash -Algorithm SHA256 -Path $scriptPath).Hash

    if ($currentHash -eq $expectedHash) {
        # Hashes match, proceed with executing the script
        & $scriptPath
    }
    else {
        Write-Error "Script integrity check failed. Aborting execution."
    }
}
catch {
    Write-Error "An error occurred: $_"
}