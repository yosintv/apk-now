$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host "Fetching releases from Flutter API..."
$releases = Invoke-RestMethod -Uri "https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json"
$stable_hash = $releases.current_release.stable
$stable_release = $releases.releases | Where-Object { $_.hash -eq $stable_hash }
$archive = $stable_release.archive
$version = $stable_release.version
$url = "https://storage.googleapis.com/flutter_infra_release/releases/" + $archive

Write-Host "Found stable version: $version"
Write-Host "Download URL: $url"

# Set destination path under D:\learning\flutter
$destDir = "D:\learning\flutter"
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir
}

$zipPath = Join-Path $destDir "flutter.zip"
Write-Host "Downloading Flutter SDK zip via BITS Transfer (highly reliable)..."

# Use Start-BitsTransfer for downloading large files
Import-Module BitsTransfer
Start-BitsTransfer -Source $url -Destination $zipPath -DisplayName "FlutterDownload"

Write-Host "Extracting Flutter SDK to $destDir..."
# Extract zip file
Expand-Archive -Path $zipPath -DestinationPath $destDir -Force

Write-Host "Cleaning up zip file..."
Remove-Item -Path $zipPath

Write-Host "Adding Flutter to user PATH..."
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$flutterBin = "D:\learning\flutter\flutter\bin"
if ($userPath -notlike "*$flutterBin*") {
    [Environment]::SetEnvironmentVariable("Path", $userPath + ";" + $flutterBin, "User")
    Write-Host "Added $flutterBin to user Path."
} else {
    Write-Host "Flutter already in user Path."
}

Write-Host "Flutter installation completed successfully!"
