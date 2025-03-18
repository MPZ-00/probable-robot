# System Customization Script
# This script applies various settings to customize Windows behavior and streamline workflows.

# Function to Disable Secure Desktop for UAC
Function Disable-SecureDesktop {
    Write-Output "Disabling Secure Desktop for UAC prompts..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PromptOnSecureDesktop" -Value 0
    Write-Output "Secure Desktop disabled."
}

# Function to Install Chocolatey
Function Install-Chocolatey {
    if (-Not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Output "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        Write-Output "Chocolatey installed successfully."
    } else {
        Write-Output "Chocolatey is already installed. Skipping."
    }
}

# Function to Install CoreUtils for GNU Commands
Function Install-CoreUtils {
    Write-Output "Installing GNU CoreUtils..."
    Install-Chocolatey
    choco install gnuwin32-coreutils.install -y
    Write-Output "GNU CoreUtils installed successfully."
}

# Function to Enable Windows Subsystem for Linux (WSL)
Function Enable-WSL {
    Write-Output "Enabling Windows Subsystem for Linux..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    wsl --install
    Write-Output "WSL enabled and default Linux distribution installed."
}

# Function to Install Common Tools
Function Install-CommonTools {
    Write-Output "Installing common tools..."
    choco install thunderbird brave signal wireshark tailscale onionshare postman jetbrainstoolbox -y
    Write-Output "Common tools installed."
}

# Execution of Customizations
Disable-SecureDesktop
Install-Chocolatey
Install-CoreUtils
Enable-WSL
Install-CommonTools

Write-Output "System customizations completed successfully."

# Prompt for Restart
Write-Output "A system restart is required to apply all changes. Do you want to restart now? (Y/N)"
$response = Read-Host "Enter Y to restart or N to skip"
if ($response -eq "Y") {
    Write-Output "Restarting system..."
    Restart-Computer -Force
} else {
    Write-Output "Please restart your system manually to apply all changes."
}
