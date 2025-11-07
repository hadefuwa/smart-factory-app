# Snap7 Android Setup - Summary of Fixes

## ✅ Issues Fixed

### 1. INTERNET Permission ✅
- **Status**: Already configured correctly
- **Location**: `android/app/src/main/AndroidManifest.xml`
- **Verification**: Line 2 contains `<uses-permission android:name="android.permission.INTERNET" />`

### 2. jniLibs Configuration ✅
- **Status**: Properly configured
- **Location**: `android/app/build.gradle` line 41
- **Configuration**: `main.jniLibs.srcDirs = ['src/main/jniLibs']`

### 3. ProGuard/R8 Rules ✅
- **Status**: Added and configured
- **Files Created**:
  - `android/app/proguard-rules.pro` - Contains JNI keep rules
- **Configuration**: Added to `build.gradle` release build type
- **Purpose**: Prevents R8/ProGuard from stripping JNI methods

### 4. ABI Filters ✅
- **Status**: Updated to include all necessary ABIs
- **Location**: `android/app/build.gradle` lines 50-54
- **ABIs Included**:
  - `armeabi-v7a` - 32-bit ARM devices
  - `arm64-v8a` - 64-bit ARM devices (most modern phones)
  - `x86_64` - Emulator support

### 5. NDK Configuration ✅
- **Status**: Properly configured
- **Location**: `android/app/build.gradle` line 28
- **Configuration**: Uses Flutter's NDK version automatically

## ⚠️ Critical Issue Found

### Native Library Files (.so) - DUPLICATES DETECTED

**Problem**: Both `.so` files have identical size (698758 bytes) and timestamp (04/17/2014 18:48:40). This strongly suggests:
1. They are duplicates (same file copied to both directories)
2. One or both are compiled for the wrong ABI
3. This will cause "wrong ELF class" errors on devices

**Current Files**:
- ✅ `android/app/src/main/jniLibs/arm64-v8a/libsnap7.so` - EXISTS but suspicious
- ✅ `android/app/src/main/jniLibs/armeabi-v7a/libsnap7.so` - EXISTS but suspicious  
- ❌ `android/app/src/main/jniLibs/x86_64/libsnap7.so` - MISSING (needed for emulator)

**Action Required**:
1. **Verify each .so file is compiled for the correct ABI**
   - Use `file` command (Linux/Mac) or WSL on Windows
   - Or use `readelf -h` to check ELF header
   - Or download verified libraries from Snap7

2. **Download/Build correct libraries**:
   - Official Snap7: https://sourceforge.net/projects/snap7/files/
   - Or build from source: https://snap7.sourceforge.net/
   - Ensure you get:
     - ARM 32-bit version for `armeabi-v7a`
     - ARM 64-bit version for `arm64-v8a`
     - x86_64 version for `x86_64` (emulator)

3. **Replace files**:
   - Delete existing files
   - Place correct ABI versions in respective directories
   - Run verification script: `powershell -ExecutionPolicy Bypass -File scripts/verify-snap7-libs.ps1`

## 📋 Verification Checklist

Run this checklist after fixing the .so files:

- [ ] All three .so files exist (arm64-v8a, armeabi-v7a, x86_64)
- [ ] Files have different sizes (or verified correct ABIs)
- [ ] Files are compiled for correct architectures
- [ ] `build.gradle` has correct `abiFilters`
- [ ] `build.gradle` references `proguard-rules.pro`
- [ ] `AndroidManifest.xml` has INTERNET permission
- [ ] Clean rebuild: `flutter clean && flutter build apk --release`
- [ ] Fully uninstall old app from device
- [ ] Install new APK and test connection

## 🔧 Testing Steps

1. **Clean Build**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Install on Device**:
   - Uninstall any existing version completely
   - Install the new APK
   - Do NOT use hot reload - fully reinstall

3. **Check Logs**:
   ```bash
   adb logcat | grep -i snap7
   adb logcat | grep -i "dlopen\|jni\|elf"
   ```

4. **Test Connection**:
   - Open app
   - Enable live mode
   - Set PLC IP address
   - Attempt connection
   - Check logs for errors

## 📚 Additional Resources

- **Setup Guide**: See `SNAP7_SETUP.md` for detailed instructions
- **Verification Script**: `scripts/verify-snap7-libs.ps1`
- **Snap7 Documentation**: https://snap7.sourceforge.net/
- **Android NDK Guide**: https://developer.android.com/ndk/guides

## 🎯 Next Steps

1. **IMMEDIATE**: Verify and replace the .so files with correct ABIs
2. **THEN**: Run verification script to confirm
3. **THEN**: Clean rebuild and test on device
4. **IF STILL FAILING**: Check logs and review `SNAP7_SETUP.md` for troubleshooting

---

**Note**: The configuration is now correct. The only remaining issue is ensuring the native library files are the correct ABIs. Once that's fixed, Snap7 should work properly.

