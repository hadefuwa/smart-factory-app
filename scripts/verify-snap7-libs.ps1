# Snap7 Library Verification Script
# Run this script to check if your .so files are correctly placed

Write-Host "Checking Snap7 native libraries..." -ForegroundColor Cyan
Write-Host ""

$basePath = "android/app/src/main/jniLibs"
$abis = @("arm64-v8a", "armeabi-v7a", "x86_64")
$allGood = $true

foreach ($abi in $abis) {
    $libPath = Join-Path (Join-Path $basePath $abi) "libsnap7.so"
    
    if (Test-Path $libPath) {
        $file = Get-Item $libPath
        Write-Host "✅ Found: $abi/libsnap7.so" -ForegroundColor Green
        Write-Host "   Size: $($file.Length) bytes" -ForegroundColor Gray
        Write-Host "   Modified: $($file.LastWriteTime)" -ForegroundColor Gray
        
        # Check if file size is reasonable (should be > 100KB)
        if ($file.Length -lt 100000) {
            Write-Host "   ⚠️  WARNING: File seems too small!" -ForegroundColor Yellow
            $allGood = $false
        }
    } else {
        Write-Host "❌ Missing: $abi/libsnap7.so" -ForegroundColor Red
        $allGood = $false
    }
    Write-Host ""
}

# Check for duplicate files (same size and timestamp)
Write-Host "Checking for duplicate files..." -ForegroundColor Cyan
$files = @()
foreach ($abi in $abis) {
    $libPath = Join-Path (Join-Path $basePath $abi) "libsnap7.so"
    if (Test-Path $libPath) {
        $file = Get-Item $libPath
        $files += @{
            ABI = $abi
            Size = $file.Length
            Modified = $file.LastWriteTime
            Path = $libPath
        }
    }
}

$duplicates = $files | Group-Object Size, Modified | Where-Object { $_.Count -gt 1 }
if ($duplicates) {
    Write-Host "⚠️  WARNING: Found files with identical size and timestamp!" -ForegroundColor Yellow
    Write-Host "   This suggests they might be duplicates or wrong ABIs." -ForegroundColor Yellow
    Write-Host "   You should verify each file is compiled for the correct ABI." -ForegroundColor Yellow
    Write-Host ""
    foreach ($dup in $duplicates) {
        Write-Host "   Duplicate group:" -ForegroundColor Yellow
        foreach ($file in $dup.Group) {
            Write-Host "     - $($file.ABI): $($file.Size) bytes, $($file.Modified)" -ForegroundColor Yellow
        }
    }
    $allGood = $false
} else {
    Write-Host "✅ No duplicate files detected" -ForegroundColor Green
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
if ($allGood) {
    Write-Host "✅ All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Verify each .so file is compiled for the correct ABI" -ForegroundColor White
    Write-Host "2. If files are wrong, download correct versions from Snap7" -ForegroundColor White
    Write-Host "3. Run: flutter clean && flutter build apk --release" -ForegroundColor White
    Write-Host "4. Fully uninstall and reinstall the app on your device" -ForegroundColor White
} else {
    Write-Host "❌ Some issues found. Please review the warnings above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Most likely issue: .so files are wrong ABIs or duplicates" -ForegroundColor Yellow
    Write-Host "See SNAP7_SETUP.md for detailed instructions" -ForegroundColor Cyan
}

