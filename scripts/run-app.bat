@echo off
echo Starting Android Emulator and running Smart Factory app...
echo.

cd /d "C:\Users\Hamed\Documents\smart-factory-app"

REM Check if Flutter is available
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Flutter not found in PATH. Using full path...
    set FLUTTER_CMD=C:\Users\Hamed\Documents\flutter\bin\flutter.bat
) else (
    set FLUTTER_CMD=flutter
)

REM Check if emulator is already running
echo Checking for running emulators...
%FLUTTER_CMD% devices | findstr /C:"emulator" >nul
if %ERRORLEVEL% EQU 0 (
    echo Emulator already running!
    goto :run_app
)

REM Launch the Android emulator
echo Launching Android emulator...
%FLUTTER_CMD% emulators --launch Medium_Phone_API_36.1

REM Wait for emulator to start and be ready
echo Waiting for emulator to start...
set MAX_WAIT=60
set WAIT_COUNT=0

:wait_loop
timeout /t 2 /nobreak >nul
%FLUTTER_CMD% devices | findstr /C:"emulator" >nul
if %ERRORLEVEL% EQU 0 (
    echo Emulator is ready!
    goto :run_app
)

set /a WAIT_COUNT+=1
if %WAIT_COUNT% GEQ %MAX_WAIT% (
    echo Timeout waiting for emulator to start.
    echo Please check if the emulator is starting correctly.
    pause
    exit /b 1
)

goto :wait_loop

:run_app
REM Run the app
echo.
echo Running app on emulator...
%FLUTTER_CMD% run

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ App launched successfully!
) else (
    echo.
    echo ❌ Failed to launch app.
    echo.
    echo Make sure:
    echo   1. The emulator is running
    echo   2. Flutter is properly configured
    echo   3. The app dependencies are installed (run 'flutter pub get')
    pause
    exit /b 1
)

pause

