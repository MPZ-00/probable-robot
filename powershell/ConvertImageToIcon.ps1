param (
    [string]$OutputDir = ".\ConvertedIcons", # Default output directory
    [string]$InputFilter = "*.png" # Default input file type (change to "*.jpg", "*.bmp", etc.)
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

    # Run ffmpeg silently
    Start-Process -NoNewWindow -Wait -FilePath "ffmpeg" -ArgumentList "-i `"$($file.FullName)`" -vf scale=48:48 -y `"$outputIco`" -loglevel quiet"

    # Update progress bar
    $counter++
    Write-Progress -Activity "Converting images to ICO" -Status "Processing: $counter / $totalFiles" -PercentComplete (($counter / $totalFiles) * 100)
}

# Completion message
Write-Host "`nConversion complete! $counter files converted, $skipped files skipped." -ForegroundColor Green
Write-Host "Icons saved in: $OutputDir" -ForegroundColor Cyan
