# Download and setup Snap7 Android native libraries
# This script downloads pre-built Snap7 libraries for Android

$ErrorActionPreference = "Stop"

Write-Host "=== Snap7 Android Library Setup ===" -ForegroundColor Cyan

# Create jniLibs directories
$jniLibsPath = "android\app\src\main\jniLibs"
$abis = @("armeabi-v7a", "arm64-v8a", "x86_64")

foreach ($abi in $abis) {
    $path = Join-Path $jniLibsPath $abi
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        Write-Host "Created directory: $path" -ForegroundColor Green
    }
}

Write-Host "`nDownloading Snap7 source..." -ForegroundColor Yellow
$snap7Url = "https://sourceforge.net/projects/snap7/files/1.4.2/snap7-full-1.4.2.7z/download"
$snap7Zip = "snap7-full-1.4.2.7z"
$extractPath = "build\snap7-source"

# Download Snap7
try {
    Invoke-WebRequest -Uri $snap7Url -OutFile $snap7Zip -UserAgent "Mozilla/5.0"
    Write-Host "Downloaded Snap7 source" -ForegroundColor Green
} catch {
    Write-Host "Failed to download Snap7: $_" -ForegroundColor Red
    Write-Host "`nManual steps required:" -ForegroundColor Yellow
    Write-Host "1. Download Snap7 from: https://sourceforge.net/projects/snap7/files/1.4.2/" -ForegroundColor Yellow
    Write-Host "2. Extract and build for Android using NDK" -ForegroundColor Yellow
    Write-Host "3. Copy libsnap7.so files to jniLibs folders" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=== IMPORTANT ===" -ForegroundColor Red
Write-Host "Snap7 doesn't provide pre-built Android libraries." -ForegroundColor Yellow
Write-Host "You need to:" -ForegroundColor Yellow
Write-Host "1. Use Android NDK to compile Snap7 for Android" -ForegroundColor White
Write-Host "2. Build for ARM 32-bit (armeabi-v7a)" -ForegroundColor White
Write-Host "3. Build for ARM 64-bit (arm64-v8a)" -ForegroundColor White
Write-Host "4. Place libsnap7.so in respective jniLibs folders" -ForegroundColor White
Write-Host "`nOR" -ForegroundColor Cyan
Write-Host "Use a pre-compiled version from the community (NOT RECOMMENDED for production)" -ForegroundColor Yellow
