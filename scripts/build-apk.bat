@echo off
echo Building APK for Android...
echo.

cd /d "C:\Users\Hamed\Documents\smart-factory-app"

REM Read version from pubspec.yaml
for /f "tokens=2 delims=: " %%a in ('findstr /c:"version:" pubspec.yaml') do (
    set VERSION_LINE=%%a
    goto :version_found
)
:version_found
REM Extract version number (format: 1.0.5+1 -> 1.0.5)
for /f "tokens=1 delims=+" %%b in ("%VERSION_LINE%") do set VERSION=%%b
if "%VERSION%"=="" (
    echo ⚠️  Could not parse version from pubspec.yaml, using default v1.0.0
    set VERSION=1.0.0
) else (
    echo Found version in pubspec.yaml: %VERSION%
)
echo.

REM Try to find Java 17 and set JAVA_HOME
if exist "C:\Program Files\Eclipse Adoptium\jdk-17*" (
    for /d %%i in ("C:\Program Files\Eclipse Adoptium\jdk-17*") do (
        set "JAVA_HOME=%%i"
        echo Found Java 17 at: %%i
        goto :found
    )
)
if exist "C:\Program Files\Java\jdk-17*" (
    for /d %%i in ("C:\Program Files\Java\jdk-17*") do (
        set "JAVA_HOME=%%i"
        echo Found Java 17 at: %%i
        goto :found
    )
)

:found
if not defined JAVA_HOME (
    echo.
    echo ⚠️  Java 17 not found automatically.
    echo.
    echo Java 17 is required for Android builds.
    echo See FIX_JAVA.md for installation instructions.
    echo.
    pause
    exit /b 1
)

echo Using JAVA_HOME: %JAVA_HOME%
echo.

"C:\Users\Hamed\Documents\flutter\bin\flutter.bat" build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ APK built successfully!
    echo.

    set "APK_PATH=build\app\outputs\flutter-apk\app-release.apk"
    set "NEW_APK_NAME=SmartFactory-v%VERSION%.apk"
    set "NEW_APK_PATH=build\app\outputs\flutter-apk\%NEW_APK_NAME%"
    set "RELEASES_APK_NAME=smart-factory-v%VERSION%.apk"
    set "RELEASES_PATH=releases\%RELEASES_APK_NAME%"

    if exist "%APK_PATH%" (
        REM Ensure releases folder exists
        if not exist "releases" (
            mkdir releases
            echo Created releases folder
        )

        REM Copy APK to releases folder with new name
        echo Copying APK to releases folder as %RELEASES_APK_NAME%...
        copy "%APK_PATH%" "%RELEASES_PATH%" /Y
        echo.
        echo ✅ APK copied to releases folder!
        echo.
        
        REM Add APK to git staging
        echo Adding APK to git staging...
        git add "%RELEASES_PATH%"
        echo ✅ APK added to git staging!
        echo.

        REM Also rename in build folder
        echo Renaming APK in build folder to %NEW_APK_NAME%...
        copy "%APK_PATH%" "%NEW_APK_PATH%" /Y
        echo.
        echo ✅ APK renamed successfully!
        echo.
        echo APK Locations:
        echo   Build folder: %NEW_APK_PATH%
        echo   Releases folder: %RELEASES_PATH%
        echo.
        echo Next steps:
        echo   1. Transfer the APK to your phone (email, USB, cloud storage)
        echo   2. Enable 'Unknown sources' in phone settings
        echo   3. Open the APK file on your phone and install
        echo.
        echo Opening releases folder...
        start explorer.exe "releases"
    ) else (
        echo ⚠️  APK file not found at expected location.
    )
) else (
    echo.
    echo ❌ Build failed. Check the error messages above.
)

pause

