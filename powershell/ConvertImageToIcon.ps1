<#
.SYNOPSIS
    Konvertiert Bilddateien in ICO-Dateien mit einer angegebenen Größe.

.DESCRIPTION
    Dieses Skript verwendet ffmpeg, um Bilddateien im aktuellen Verzeichnis in ICO-Dateien zu konvertieren.
    Es unterstützt die Angabe eines Ausgabeordners, eines Eingabefilters und einer Icon-Größe.

.PARAMETER OutputDir
    Der Ordner, in dem die konvertierten ICO-Dateien gespeichert werden. Standard ist ".\ConvertedIcons".

.PARAMETER InputFilter
    Der Filter für die Eingabedateien (z. B. "*.png", "*.jpg"). Standard ist "*.png".

.PARAMETER IconSize
    Die Größe der ICO-Dateien im Format "BreitexHöhe" (z. B. "48x48"). Standard ist "48x48".

.EXAMPLE
    .\ConvertImageToIcon.ps1 -OutputDir ".\Icons" -InputFilter "*.jpg" -IconSize "64x64"
    Konvertiert alle JPG-Dateien im aktuellen Verzeichnis in ICO-Dateien mit der Größe 64x64 und speichert sie im Ordner ".\Icons".

.NOTES
    - ffmpeg muss installiert und im PATH verfügbar sein.
    - Bereits vorhandene ICO-Dateien werden übersprungen.

#>

param (
    [string]$OutputDir = ".\ConvertedIcons", # Default output directory
    [string]$InputFilter = "*.png", # Default input file type (change to "*.jpg", "*.bmp", etc.)
    [string]$IconSize = "48x48" # Default icon size
)

# Ensure ffmpeg is installed
$ffmpegExists = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegExists) {
    Write-Host "Error: ffmpeg is not installed or not in PATH!" -ForegroundColor Red
    exit 1
}

# Ensure output directory exists
if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Get input files
$inputFiles = Get-ChildItem -Path . -Filter $InputFilter

# Check if there are files to convert
if ($inputFiles.Count -eq 0) {
    Write-Host "No matching files found for filter '$InputFilter' in the current directory." -ForegroundColor Yellow
    exit 0
}

# Initialize progress bar
$totalFiles = $inputFiles.Count
$counter = 0
$skipped = 0

foreach ($file in $inputFiles) {
    $outputIco = "$OutputDir\$($file.BaseName).ico"

    # Skip if already converted
    if (Test-Path -Path $outputIco) {
        Write-Host "Skipping: $($file.Name) (Already exists)" -ForegroundColor Yellow
        $skipped++
        continue
    }

    # Adjust icon size based on filename suffix if IconSize is default
    $effectiveIconSize = $IconSize
    if ($IconSize -eq "48x48" -and $file.Name -match "@(\d+)x$") {
        $scaleFactor = [int]$matches[1]
        $baseSize = 48
        $effectiveIconSize = "$($baseSize * $scaleFactor)x$($baseSize * $scaleFactor)"
    }

    # Run ffmpeg silently with adjusted icon size
    Start-Process -NoNewWindow -Wait -FilePath "ffmpeg" -ArgumentList "-i `"$($file.FullName)`" -vf scale=$effectiveIconSize -y `"$outputIco`" -loglevel quiet"

    # Update progress bar
    $counter++
    Write-Progress -Activity "Converting images to ICO" -Status "Processing: $counter / $totalFiles" -PercentComplete (($counter / $totalFiles) * 100)
}

# Completion message
Write-Host "`nConversion complete! $counter files converted, $skipped files skipped." -ForegroundColor Green
Write-Host "Icons saved in: $OutputDir" -ForegroundColor Cyan
