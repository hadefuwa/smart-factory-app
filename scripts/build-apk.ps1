# Build APK for Android Phone Installation
Write-Host "Building APK for Android..." -ForegroundColor Green
Write-Host ""

# Navigate to project directory
Set-Location "C:\Users\Hamed\Documents\smart-factory-app"

# Read version from pubspec.yaml
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match "version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)") {
    $major = $matches[1]
    $minor = $matches[2]
    $patch = $matches[3]
    $build = $matches[4]
    $version = "$major.$minor.$patch"
    Write-Host "Found version in pubspec.yaml: $version (build $build)" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  Could not parse version from pubspec.yaml, using default v1.0.0" -ForegroundColor Yellow
    $version = "1.0.0"
}

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
    $newApkName = "SmartFactory-v$version.apk"
    $newApkPath = "build\app\outputs\flutter-apk\$newApkName"
    $releasesApkName = "smart-factory-v$version.apk"
    $releasesPath = "releases\$releasesApkName"

    if (Test-Path $apkPath) {
        # Ensure releases folder exists
        if (-not (Test-Path "releases")) {
            New-Item -ItemType Directory -Path "releases" | Out-Null
            Write-Host "Created releases folder" -ForegroundColor Cyan
        }

        # Copy APK to releases folder with new name
        Write-Host "Copying APK to releases folder as $releasesApkName..." -ForegroundColor Cyan
        Copy-Item -Path $apkPath -Destination $releasesPath -Force
        Write-Host ""
        Write-Host "✅ APK copied to releases folder!" -ForegroundColor Green
        Write-Host ""
        
        # Add APK to git staging
        Write-Host "Adding APK to git staging..." -ForegroundColor Cyan
        git add $releasesPath
        Write-Host "✅ APK added to git staging!" -ForegroundColor Green
        Write-Host ""

        # Also copy to build folder with new name
        Write-Host "Renaming APK in build folder to $newApkName..." -ForegroundColor Cyan
        Copy-Item -Path $apkPath -Destination $newApkPath -Force
        Write-Host ""
        Write-Host "✅ APK renamed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "APK Locations:" -ForegroundColor Yellow
        Write-Host "  Build folder: $newApkPath" -ForegroundColor Cyan
        Write-Host "  Releases folder: $releasesPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Transfer the APK to your phone (email, USB, cloud storage)" -ForegroundColor White
        Write-Host "  2. Enable 'Unknown sources' in phone settings" -ForegroundColor White
        Write-Host "  3. Open the APK file on your phone and install" -ForegroundColor White
        Write-Host ""

        # Open the releases folder
        Write-Host "Opening releases folder..." -ForegroundColor Cyan
        Start-Process explorer.exe -ArgumentList (Resolve-Path "releases")
    } else {
        Write-Host "⚠️  APK file not found at expected location." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "❌ Build failed. Check the error messages above." -ForegroundColor Red
}

