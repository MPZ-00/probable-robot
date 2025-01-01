# Define the script
param(
    [string]$TargetFolder = ".",
    [switch]$WriteToOriginal,
    [switch]$DeleteOutput,
    [switch]$DeleteOutputOld
)

# Define output folder paths
$outputFolder = Join-Path -Path $TargetFolder -ChildPath "output"
$outputOldFolder = Join-Path -Path $TargetFolder -ChildPath "output.old"

# Handle output folder cleanup
if (-not $WriteToOriginal) {
    # Delete output.old if specified
    if ($DeleteOutputOld -and (Test-Path -Path $outputOldFolder)) {
        Remove-Item -Path $outputOldFolder -Recurse -Force
        Write-Host "Deleted existing output.old folder."
    }

    # Rename output to output.old if it exists
    if (Test-Path -Path $outputFolder) {
        Rename-Item -Path $outputFolder -NewName "output.old"
        Write-Host "Renamed existing output folder to output.old."
    }

    # Delete output folder if specified
    if ($DeleteOutput -and (Test-Path -Path $outputFolder)) {
        Remove-Item -Path $outputFolder -Recurse -Force
        Write-Host "Deleted existing output folder."
    }

    # Create a new output folder
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Function to create metadata text from .nfo
function New-MetadataFile {
    param(
        [string]$nfoFile,
        [string]$metadataFile
    )

    # Read .nfo content
    $nfoContent = Get-Content -Path $nfoFile -Raw

    # Prepare metadata format for ffmpeg
    $metadata = ";FFMETADATA1`n"

    # Parse fields (modify as needed for your .nfo structure)
    if ($nfoContent -match "<title>(.*?)</title>") {
        $metadata += "title=$($matches[1])`n"
    }
    if ($nfoContent -match "<year>(.*?)</year>") {
        $metadata += "year=$($matches[1])`n"
    }
    if ($nfoContent -match "<plot>(.*?)</plot>") {
        $metadata += "description=$($matches[1])`n"
        $metadata += "summary=$($matches[1])`n"
    }
    if ($nfoContent -match "<genre>(.*?)</genre>") {
        $metadata += "genre=$($matches[1])`n"
    }
    if ($nfoContent -match "<studio>(.*?)</studio>") {
        $metadata += "studio=$($matches[1])`n"
    }
    if ($nfoContent -match "<certification>(.*?)</certification>") {
        $metadata += "mpaa=$($matches[1])`n"
    }
    if ($nfoContent -match "<premiered>(.*?)</premiered>") {
        $metadata += "date=$($matches[1])`n"
    }
    if ($nfoContent -match "<tags>(.*?)</tags>") {
        $metadata += "tags=$($matches[1])`n"
    }

    # Write metadata to a temporary file
    Set-Content -Path $metadataFile -Value $metadata
}

# Scan the target folder for video files and their .nfo files
Get-ChildItem -Path $TargetFolder -Recurse -File | Where-Object {
    $_.Extension -match "\.mp4|\.mkv|\.avi"
} | ForEach-Object {
    $videoFile = $_.FullName
    $nfoFile = [System.IO.Path]::ChangeExtension($videoFile, ".nfo")
    $metadataFile = [System.IO.Path]::Combine($TargetFolder, "temp_metadata.txt")
    $outputFile = if ($WriteToOriginal) { $videoFile } else { [System.IO.Path]::Combine($outputFolder, $_.Name) }
    $imageExtensions = @(".jpg", ".jpeg", ".png")

    if (Test-Path $nfoFile) {
        Write-Host "Processing: $($videoFile)"

        # Generate metadata file from .nfo
        New-MetadataFile -nfoFile $nfoFile -metadataFile $metadataFile

        # Embed metadata using ffmpeg
        ffmpeg -i $videoFile -i $metadataFile -map_metadata 1 -codec copy $outputFile

        # Remove temporary metadata file
        Remove-Item -Path $metadataFile -Force

        if (-not $WriteToOriginal) {
            # Move .nfo file to output
            Copy-Item -Path $nfoFile -Destination $outputFolder -Force
        }
    } else {
        Write-Host "No .nfo file found for: $($videoFile)"
    }

    # Move associated images (posters, fanart, etc.) to output if not writing to original
    if (-not $WriteToOriginal) {
        foreach ($ext in $imageExtensions) {
            $imageFile = [System.IO.Path]::ChangeExtension($videoFile, $ext)
            if (Test-Path $imageFile) {
                Copy-Item -Path $imageFile -Destination $outputFolder -Force
            }
        }
    }
}

Write-Host "Processing complete. Check the 'output' folder or original files for results."
