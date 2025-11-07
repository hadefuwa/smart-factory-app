# Git Commit and Push Script
Write-Host "Git Commit and Push Script" -ForegroundColor Green
Write-Host ""

# Navigate to project directory
Set-Location "C:\Users\Hamed\Documents\smart-factory-app"

# Check git status
Write-Host "Checking git status..." -ForegroundColor Cyan
$status = git status --porcelain

if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "No changes to commit." -ForegroundColor Yellow
    exit 0
}

# Show what will be committed
Write-Host ""
Write-Host "Changes to be committed:" -ForegroundColor Yellow
git status --short
Write-Host ""

# Prompt for commit message
$commitMessage = Read-Host "Enter commit message (or press Enter for default)"

if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $commitMessage = "Update: $timestamp"
    Write-Host "Using default commit message: $commitMessage" -ForegroundColor Cyan
}

# Stage all changes
Write-Host ""
Write-Host "Staging all changes..." -ForegroundColor Cyan
git add -A
# Force add APK files to ensure they're included
$apkFiles = Get-ChildItem -Path "releases" -Filter "*.apk" -ErrorAction SilentlyContinue
if ($apkFiles) {
    git add releases\*.apk
    Write-Host "Added APK files from releases folder" -ForegroundColor Cyan
}

# Commit
Write-Host "Committing changes..." -ForegroundColor Cyan
git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Changes committed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Push to remote
    Write-Host "Pushing to origin/main..." -ForegroundColor Cyan
    git push origin main
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Successfully pushed to origin/main!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Failed to push to remote. Check your connection and try again." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "❌ Commit failed. Check the error messages above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green

