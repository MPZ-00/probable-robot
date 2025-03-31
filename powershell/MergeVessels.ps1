<#
.SYNOPSIS
    Merge the newest versions of files found in 'Vessels' folders across multiple archive directories.

.DESCRIPTION
    This script searches recursively within each specified source archive for folders named 'Vessels'.
    It then gathers all files within those folders and subfolders, compares them by relative path,
    and selects the most recent version of each file based on LastWriteTime.
    Finally, it copies (or simulates copying with -DryRun) the latest versions into the specified TargetFolder.

.PARAMETER SourceArchives
    One or more folders (absolute or relative paths) that may contain subfolders with 'Vessels' data.
    Example: -SourceArchives @('.\Archive 2022\', '.\Archive 2023\')

.PARAMETER TargetFolder
    Destination folder for the merged result. Default is '.\MergedVessels'.

.PARAMETER DryRun
    If set, no files are actually copied. Useful for simulating and previewing what would be merged.

.PARAMETER LogPath
    Optional log file path. Defaults to '.\MergeVessels.log'.

.EXAMPLE
    .\MergeVessels.ps1 -SourceArchives @('.\Archive 2022\', '.\Archive 2023\') -TargetFolder '.\Output' -DryRun

.NOTES
    Trailing slashes and single quotes are handled gracefully. Requires PowerShell 5.0 or later.

    Author: Martin
    Date: 2025-03-30
    Version: 3.0
#>

param (
    [Parameter(Mandatory = $true)]
    [string[]]$SourceArchives,

    [Parameter(Mandatory = $false)]
    [string]$TargetFolder = ".\MergedVessels",

    [switch]$DryRun,

    [string]$LogPath = ".\MergeVessels.log"
)

function Get-NewestFilesFromVesselsFolder {
    param (
        [string]$ArchivePath,
        [ref]$ExpectedFileCount
    )

    $vesselFiles = @{}
    $vessels = Get-ChildItem -LiteralPath $ArchivePath -Recurse -Directory -Filter "Vessels" -ErrorAction SilentlyContinue

    foreach ($vesselDir in $vessels) {
        $files = Get-ChildItem -LiteralPath $vesselDir.FullName -Recurse -File
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($file.FullName.ToLower().IndexOf("vessels") + 8)
            $key = $relativePath.ToLower()

            if ($vesselFiles.ContainsKey($key)) {
                if ($file.LastWriteTime -gt $vesselFiles[$key].LastWriteTime) {
                    $vesselFiles[$key] = $file
                }
            } else {
                $vesselFiles[$key] = $file
            }
        }
    }

    $ExpectedFileCount.Value = $vesselFiles.Count
    return $vesselFiles
}

function Copy-VesselFiles {
    param (
        [hashtable]$Files,
        [string]$TargetRoot,
        [switch]$DryRun,
        [string]$LogPath,
        [string]$Archive
    )

    $count = 0
    $basePath = (Get-Location).ProviderPath.TrimEnd('\')

    $activity = "Copying files from [$Archive]..."

    foreach ($entry in $Files.GetEnumerator()) {
        $count++
        Write-Progress -Activity $activity -Status "$count / $($Files.Count)" -PercentComplete (($count / $Files.Count) * 100)

        $source = $entry.Value.FullName
        $relative = $entry.Key
        $destination = Join-Path -Path $TargetRoot -ChildPath $relative
        $destDir = Split-Path -Path $destination -Parent

        if (-not $DryRun) {
            if (-not (Test-Path -LiteralPath $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -LiteralPath $source -Destination $destination -Force
        }

        $shortSource = $source.Replace($basePath, '~')
        $logPrefix = if ($DryRun) { '[DryRun] ' } else { '' }
        "[$(Get-Date -Format "MM/dd/yyyy HH:mm:ss")] $logPrefix Copied: '$relative' from $shortSource" | Out-File -FilePath $LogPath -Append -Encoding UTF8
    }
    Write-Progress -Activity "Copying files..." -Completed
    Write-Host "Total $count files processed."
    return $count
}

# Ensure target exists (unless DryRun)
if (-not $DryRun -and -not (Test-Path -LiteralPath $TargetFolder)) {
    New-Item -ItemType Directory -Path $TargetFolder | Out-Null
}

# Ensure log directory exists
$logDir = Split-Path -Path $LogPath -Parent
if (-not (Test-Path -LiteralPath $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

"[$(Get-Date)] Merge started" | Out-File -FilePath $LogPath -Encoding UTF8

foreach ($archive in $SourceArchives) {
    $normalizedPath = Resolve-Path -LiteralPath $archive -ErrorAction SilentlyContinue
    $basePath = (Get-Location).ProviderPath.TrimEnd('\')
    $archiveShort = $archive.Replace($basePath, '~').TrimEnd('\','/')

    if (-not $normalizedPath) {
        Write-Warning "Archive not found: $archiveShort"
        continue
    }
    $archive = $normalizedPath.ProviderPath.TrimEnd('\','/')
    Write-Host "Processing archive: $archiveShort"

    $expectedCount = 0
    $filesToCopy = Get-NewestFilesFromVesselsFolder -ArchivePath $archive -ExpectedFileCount ([ref]$expectedCount)
    $actualCount = Copy-VesselFiles -Files $filesToCopy -TargetRoot $TargetFolder -DryRun:$DryRun -LogPath $LogPath -Archive $archiveShort

    if ($actualCount -lt $expectedCount) {
        Write-Warning "File count mismatch in $archive. Expected ~$expectedCount, but processed $actualCount."
    }
}

Write-Host "Merge complete. Log written to: $LogPath"
if ($DryRun) {
    Write-Host "Dry run mode: No files were copied."
}
