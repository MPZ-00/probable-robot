<#
.SYNOPSIS
Creates a range of season folders (Season 01, Season 02, etc.) in the current or specified directory.

.PARAMETER TargetPath
The directory where the season folders should be created. Defaults to the current directory.

.PARAMETER Start
The starting season number. Defaults to 1.

.PARAMETER End
The ending season number. Defaults to 10.

.EXAMPLE
.\CreateSeasonFolders.ps1 -TargetPath "C:\Shows\MySeries" -Start 1 -End 5

Creates "Season 01" to "Season 05" inside "C:\Shows\MySeries".

.EXAMPLE
.\CreateSeasonFolders.ps1

Creates "Season 01" to "Season 10" in the current directory.

.NOTES
Author: Martin
Date: 2025-02-22
Version: 1.0
#>

param (
    [Parameter(Mandatory = $false, HelpMessage = "Target directory for season folders.")]
    [string]$TargetPath = (Get-Location).Path,

    [Parameter(Mandatory = $false, HelpMessage = "Starting season number.")]
    [int]$Start = 1,

    [Parameter(Mandatory = $false, HelpMessage = "Ending season number.")]
    [int]$End = 10
)

# Ensure the target path exists
if (-Not (Test-Path -Path $TargetPath)) {
    Write-Error "The target directory '$TargetPath' does not exist."
    exit
}

# Create the season folders
for ($i = $Start; $i -le $End; $i++) {
    $seasonFolder = "Season {0:D2}" -f $i
    $fullPath = Join-Path -Path $TargetPath -ChildPath $seasonFolder

    if (-Not (Test-Path -Path $fullPath)) {
        New-Item -Path $fullPath -ItemType Directory | Out-Null
        Write-Host "Created: $fullPath"
    }
    else {
        Write-Host "Skipped (already exists): $fullPath"
    }
}

Write-Host "All season folders have been created!"
