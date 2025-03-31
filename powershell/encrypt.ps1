param(
    [Parameter(Mandatory=$true)]
    [string]$expectedHash = "0x1234567890abcdef1234567890abcdef",
    [Parameter(Mandatory=$false)]
    [string]$targetPath = "C:\ProgramData\EncryptedHash_$(Get-Date -Format 'ddMMyyyy').xml",
    [switch]$help
)

if ($help) {
    Write-Output "This script is used to encrypt a hash value and save it to a file."
    Write-Output "Usage: encrypt.ps1 [-expectedHash <hash>] [-targetPath <path>] [-help]"
    Write-Output "  -expectedHash  : The hash value to encrypt. Default is a sample hash."
    Write-Output "  -targetPath    : The path where the encrypted hash will be saved. Default includes the current Date."
    Write-Output "  -help          : Display this help message."
    Exit
}

try {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-Warning "This script requires administrative privileges. Please run it as an administrator."
        Exit
    }

    $aesProvider = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $aesProvider.KeySize = 256 # Use 256-bit AES encryption
    $aesProvider.GenerateKey()
    $aesProvider.GenerateIV()

    $encryptionKey = $aesProvider.Key
    $IV = $aesProvider.IV

    # Convert the hash to a byte array
    $hashBytes = [System.Text.Encoding]::UTF8.GetBytes($expectedHash)

    # Encrypt the hash
    $encryptor = $aesProvider.CreateEncryptor($encryptionKey, $IV)
    $encryptedHashBytes = $encryptor.TransformFinalBlock($hashBytes, 0, $hashBytes.Length)

    # Save the encrypted hash, key, and IV to the file
    $output = @{
        EncryptedHash = [Convert]::ToBase64String($encryptedHashBytes)
        Key = [Convert]::ToBase64String($encryptionKey)
        IV = [Convert]::ToBase64String($IV)
    } | ConvertTo-Json

    Set-Content -Path $targetPath -Value $output

    Write-Output "Hash Key: $output"
    Write-Output "Exported encrypted hash and encryption details to $targetPath."
}
catch {
    Write-Error "An error occurred: $_"
}