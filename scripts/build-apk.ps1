# Build APK for Android Phone Installation
Write-Host "Building APK for Android..." -ForegroundColor Green
Write-Host ""

# Navigate to project directory
Set-Location "C:\Users\Hamed\Documents\matrix-app"

# Try to find and set Java 17
$java17Paths = @(
    "C:\Program Files\Eclipse Adoptium\jdk-17*",
    "C:\Program Files\Java\jdk-17*",
    "C:\Program Files\Microsoft\jdk-17*"
)

$javaHome = $null
foreach ($path in $java17Paths) {
    $found = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $javaHome = $found.FullName
        Write-Host "Found Java 17 at: $javaHome" -ForegroundColor Cyan
        $env:JAVA_HOME = $javaHome
        break
    }
}

if ($null -eq $javaHome) {
    Write-Host "⚠️  Java 17 not found automatically." -ForegroundColor Yellow
    Write-Host "Checking current Java version..." -ForegroundColor Yellow
    $javaVersion = java -version 2>&1 | Select-String "version"
    Write-Host "Current: $javaVersion" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Java 17 is required for Android builds." -ForegroundColor Yellow
    Write-Host "See FIX_JAVA.md for installation instructions." -ForegroundColor Cyan
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne "y") {
        exit 1
    }
}

# Build the APK
& "C:\Users\Hamed\Documents\flutter\bin\flutter.bat" build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ APK built successfully!" -ForegroundColor Green
    Write-Host ""
    
    $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
    $newApkName = "SmartFactory-v1.0.0.apk"
    $newApkPath = "build\app\outputs\flutter-apk\$newApkName"
    
    if (Test-Path $apkPath) {
        Write-Host "Renaming APK to $newApkName..." -ForegroundColor Cyan
        Rename-Item -Path $apkPath -NewName $newApkName -Force
        Write-Host ""
        Write-Host "✅ APK renamed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "APK Location:" -ForegroundColor Yellow
        Write-Host "  $newApkPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Transfer the APK to your phone (email, USB, cloud storage)" -ForegroundColor White
        Write-Host "  2. Enable 'Unknown sources' in phone settings" -ForegroundColor White
        Write-Host "  3. Open the APK file on your phone and install" -ForegroundColor White
        Write-Host ""
        
        # Open the APK folder
        $folderPath = Split-Path -Parent $newApkPath
        Write-Host "Opening APK folder..." -ForegroundColor Cyan
        Start-Process explorer.exe -ArgumentList $folderPath
    } else {
        Write-Host "⚠️  APK file not found at expected location." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "❌ Build failed. Check the error messages above." -ForegroundColor Red
}

