# Snap7 Native Library Setup Guide

This document explains how to verify and fix Snap7 native library issues on Android.

## Current Configuration

✅ **INTERNET Permission**: Already configured in `AndroidManifest.xml`
✅ **jniLibs Configuration**: Properly configured in `build.gradle`
✅ **ProGuard Rules**: Added to prevent JNI stripping
✅ **ABI Filters**: Configured for armeabi-v7a, arm64-v8a, and x86_64

## Critical Issues to Check

### 1. Verify Native Library Files (.so)

**Location**: `android/app/src/main/jniLibs/`

You MUST have the correct `.so` files for each ABI:
- `arm64-v8a/libsnap7.so` - For 64-bit ARM devices (most modern phones)
- `armeabi-v7a/libsnap7.so` - For 32-bit ARM devices (older phones)
- `x86_64/libsnap7.so` - For emulator testing (optional but recommended)

**⚠️ IMPORTANT**: Both files currently have the same size (698758 bytes) and timestamp. This is suspicious - they might be duplicates or wrong ABIs.

**How to verify**:
1. Use `file` command on Linux/Mac: `file libsnap7.so`
2. Use `readelf -h` to check ELF header: `readelf -h libsnap7.so | grep Machine`
   - Should show "ARM" for armeabi-v7a
   - Should show "AArch64" for arm64-v8a
   - Should show "x86-64" for x86_64

**On Windows**, you can:
- Use WSL to run `file` command
- Use a hex editor to check the ELF header (first few bytes)
- Download correct libraries from Snap7 source

### 2. Download Correct Libraries

If your libraries are incorrect, download from:
- Official Snap7 releases: https://sourceforge.net/projects/snap7/files/
- Or build from source: https://snap7.sourceforge.net/

**Required files**:
- `libsnap7.so` compiled for ARM 32-bit (armeabi-v7a)
- `libsnap7.so` compiled for ARM 64-bit (arm64-v8a)
- `libsnap7.so` compiled for x86_64 (for emulator)

### 3. Common Errors and Solutions

#### Error: "dlopen failed: library 'libsnap7.so' not found"
**Solution**: 
- Verify `.so` files exist in `jniLibs/[ABI]/` directories
- Ensure `jniLibs.srcDirs` is configured in `build.gradle`
- Do a clean rebuild: `flutter clean && flutter build apk --release`
- Fully uninstall and reinstall the app (hot reload won't work)

#### Error: "wrong ELF class: ELFCLASS64" or "ELFCLASS32"
**Solution**: 
- The `.so` file ABI doesn't match the device ABI
- Replace with correct ABI version
- Most modern phones are arm64-v8a (64-bit)

#### Error: Library loads but connection fails
**Solution**:
- Check INTERNET permission (already configured ✅)
- Verify network connectivity
- Check PLC IP address and port
- Review ProGuard rules (already configured ✅)

### 4. Build and Test Steps

1. **Clean build**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Build APK**:
   ```bash
   flutter build apk --release
   ```

3. **Install on device**:
   - Uninstall any existing version first
   - Install the new APK
   - Test connection

4. **Check logs**:
   ```bash
   adb logcat | grep -i snap7
   adb logcat | grep -i "dlopen\|jni"
   ```

### 5. Verification Checklist

- [ ] `libsnap7.so` exists in `jniLibs/arm64-v8a/`
- [ ] `libsnap7.so` exists in `jniLibs/armeabi-v7a/`
- [ ] `libsnap7.so` exists in `jniLibs/x86_64/` (for emulator)
- [ ] Files are correct ABIs (not duplicates)
- [ ] `build.gradle` has `jniLibs.srcDirs` configured
- [ ] `build.gradle` has correct `abiFilters`
- [ ] `AndroidManifest.xml` has INTERNET permission
- [ ] ProGuard rules file exists and is referenced
- [ ] App is fully reinstalled (not hot reloaded)

### 6. Next Steps

1. **Verify your .so files are correct ABIs** - This is the most likely issue
2. If files are wrong, download/build correct versions
3. Place them in the correct `jniLibs/[ABI]/` directories
4. Clean rebuild and test

## Additional Resources

- Snap7 Documentation: https://snap7.sourceforge.net/
- Android NDK Guide: https://developer.android.com/ndk/guides
- Flutter Native Libraries: https://docs.flutter.dev/development/platform-integration/android/c-interop

