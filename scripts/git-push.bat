@echo off
echo Git Commit and Push Script
echo.

cd /d "C:\Users\Hamed\Documents\smart-factory-app"

REM Check git status
echo Checking git status...
for /f %%i in ('git status --porcelain') do goto :has_changes
echo No changes to commit.
pause
exit /b 0
:has_changes

REM Show what will be committed
echo.
echo Changes to be committed:
git status --short
echo.

REM Prompt for commit message
set /p COMMIT_MSG="Enter commit message (or press Enter for default): "

if "%COMMIT_MSG%"=="" (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
    set datetime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
    set COMMIT_MSG=Update: %datetime%
    echo Using default commit message: %COMMIT_MSG%
)

REM Stage all changes
echo.
echo Staging all changes...
git add -A
REM Force add APK files to ensure they're included
if exist releases\*.apk (
    git add releases\*.apk
    echo Added APK files from releases folder
)

REM Commit
echo Committing changes...
git commit -m "%COMMIT_MSG%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Changes committed successfully!
    echo.
    
    REM Push to remote
    echo Pushing to origin/main...
    git push origin main
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ✅ Successfully pushed to origin/main!
    ) else (
        echo.
        echo ❌ Failed to push to remote. Check your connection and try again.
        pause
        exit /b 1
    )
) else (
    echo.
    echo ❌ Commit failed. Check the error messages above.
    pause
    exit /b 1
)

echo.
echo Done!
pause

