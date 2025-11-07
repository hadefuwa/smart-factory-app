@echo off
echo Starting Android Emulator and running Smart Factory app...
echo.

REM Launch the Android emulator
echo Launching Android emulator...
flutter emulators --launch Medium_Phone_API_36.1

REM Wait a bit for emulator to start
echo Waiting for emulator to start...
timeout /t 10 /nobreak >nul

REM Run the app
echo Running app on emulator...
flutter run


