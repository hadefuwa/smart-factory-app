# PowerShell script to run the Smart Factory app on Android Emulator
Write-Host "Starting Android Emulator and running Smart Factory app..." -ForegroundColor Green
Write-Host ""

# Navigate to project directory
Set-Location "C:\Users\Hamed\Documents\smart-factory-app"

# Check if Flutter is available
$flutterCmd = "flutter"
try {
    $null = Get-Command flutter -ErrorAction Stop
} catch {
    Write-Host "Flutter not found in PATH. Using full path..." -ForegroundColor Yellow
    $flutterCmd = "C:\Users\Hamed\Documents\flutter\bin\flutter.bat"
}

# Check if emulator is already running
Write-Host "Checking for running emulators..." -ForegroundColor Cyan
$devices = & $flutterCmd devices 2>&1
if ($devices -match "emulator") {
    Write-Host "Emulator already running!" -ForegroundColor Green
} else {
    # Launch the Android emulator
    Write-Host "Launching Android emulator..." -ForegroundColor Cyan
    & $flutterCmd emulators --launch Medium_Phone_API_36.1
    
    # Wait for emulator to start and be ready
    Write-Host "Waiting for emulator to start..." -ForegroundColor Yellow
    $maxWait = 60
    $waitCount = 0
    $emulatorReady = $false
    
    while ($waitCount -lt $maxWait) {
        Start-Sleep -Seconds 2
        $devices = & $flutterCmd devices 2>&1
        if ($devices -match "emulator") {
            Write-Host "Emulator is ready!" -ForegroundColor Green
            $emulatorReady = $true
            break
        }
        $waitCount++
    }
    
    if (-not $emulatorReady) {
        Write-Host "Timeout waiting for emulator to start." -ForegroundColor Red
        Write-Host "Please check if the emulator is starting correctly." -ForegroundColor Yellow
        exit 1
    }
}

# Run the app
Write-Host ""
Write-Host "Running app on emulator..." -ForegroundColor Cyan
& $flutterCmd run

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ App launched successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Failed to launch app." -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure:" -ForegroundColor Yellow
    Write-Host "  1. The emulator is running" -ForegroundColor White
    Write-Host "  2. Flutter is properly configured" -ForegroundColor White
    Write-Host "  3. The app dependencies are installed (run 'flutter pub get')" -ForegroundColor White
    exit 1
}

