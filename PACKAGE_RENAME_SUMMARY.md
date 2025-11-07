# Package Rename and Library Fix Summary

## ✅ Changes Completed

### 1. Package Renamed from `matrix_app` to `smart_factory`

**Files Updated:**
- ✅ `pubspec.yaml` - Package name changed to `smart_factory_app`
- ✅ `android/app/build.gradle` - Namespace and applicationId changed to `com.matrixtsl.smart_factory`
- ✅ `android/app/proguard-rules.pro` - Updated package reference
- ✅ `test/widget_test.dart` - Updated import statement
- ✅ `android/app/src/main/kotlin/com/matrixtsl/smart_factory/MainActivity.kt` - Created with new package name
- ✅ Old `matrix_app` directory removed

### 2. Library Loading Fix

**MainActivity.kt Updated:**
- Added explicit `System.loadLibrary("snap7")` call in the `init` block
- This ensures the library is loaded when the app starts
- Includes error handling for library loading failures

## ⚠️ Critical Next Steps

### 1. Clean Build Required

After changing the package name, you **MUST** do a complete clean rebuild:

```bash
# Clean Flutter build
flutter clean

# Clean Android build
cd android
./gradlew clean
cd ..

# Get dependencies
flutter pub get

# Rebuild APK
flutter build apk --release
```

### 2. Uninstall Old App

**IMPORTANT**: The old app with package name `com.matrixtsl.matrix_app` must be completely uninstalled from your device before installing the new one.

```bash
# Uninstall old app
adb uninstall com.matrixtsl.matrix_app

# Install new app
flutter install
```

Or manually uninstall from device settings, then install the new APK.

### 3. Verify Library Files

Ensure `libsnap7.so` files exist in:
- `android/app/src/main/jniLibs/arm64-v8a/libsnap7.so`
- `android/app/src/main/jniLibs/armeabi-v7a/libsnap7.so`
- `android/app/src/main/jniLibs/x86_64/libsnap7.so` (optional, for emulator)

If files are missing, you need to add them. The error "failed to load dynamic library" suggests:
1. The library files might not be bundled in the APK
2. Or the old package name is still cached

### 4. Check Library Bundling

After building, verify the libraries are included in the APK:

```bash
# Extract and check APK contents (on Linux/Mac or WSL)
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep libsnap7.so
```

You should see:
- `lib/arm64-v8a/libsnap7.so`
- `lib/armeabi-v7a/libsnap7.so`
- `lib/x86_64/libsnap7.so` (if included)

## 🔍 Troubleshooting

### If library still not found:

1. **Verify files exist:**
   ```powershell
   Get-ChildItem android/app/src/main/jniLibs -Recurse -Filter "*.so"
   ```

2. **Check build.gradle configuration:**
   - Ensure `main.jniLibs.srcDirs = ['src/main/jniLibs']` is set
   - Ensure `abiFilters` includes your target ABIs

3. **Check MainActivity:**
   - Verify `System.loadLibrary("snap7")` is called
   - Check logcat for loading errors: `adb logcat | grep -i "snap7\|loadlibrary"`

4. **Full clean rebuild:**
   - Delete `build/` directory
   - Delete `android/.gradle/` directory
   - Delete `android/app/build/` directory
   - Rebuild from scratch

## 📝 Files Changed

1. `pubspec.yaml` - Package name
2. `android/app/build.gradle` - Namespace and applicationId
3. `android/app/proguard-rules.pro` - Package reference
4. `android/app/src/main/kotlin/com/matrixtsl/smart_factory/MainActivity.kt` - New file with library loading
5. `test/widget_test.dart` - Import statement

## 🎯 Expected Result

After completing these steps:
- App package name will be `com.matrixtsl.smart_factory`
- Data directory will be `/data/data/com.matrixtsl.smart_factory/`
- Library should load from `/data/data/com.matrixtsl.smart_factory/lib/libsnap7.so`
- Snap7 communication should work correctly

## ⚠️ Important Notes

1. **Package name change is permanent** - You cannot have both package names installed
2. **Data will be lost** - Uninstalling the old app removes all app data
3. **Clean build is essential** - Old build artifacts can cause issues
4. **Library files must exist** - If `libsnap7.so` files are missing, download them from Snap7

