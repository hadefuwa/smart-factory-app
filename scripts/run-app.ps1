# PowerShell script to run the Smart Factory app on Android Emulator
Write-Host "Starting Android Emulator and running Smart Factory app..." -ForegroundColor Green
Write-Host ""

# Launch the Android emulator
Write-Host "Launching Android emulator..." -ForegroundColor Cyan
flutter emulators --launch Medium_Phone_API_36.1

# Wait a bit for emulator to start
Write-Host "Waiting for emulator to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Run the app
Write-Host "Running app on emulator..." -ForegroundColor Cyan
flutter run


