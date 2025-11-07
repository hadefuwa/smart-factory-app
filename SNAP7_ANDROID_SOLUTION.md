# Snap7 Android Library - Complete Solution Guide

## Problem
Your app crashes with: `Failed to load dynamic library libsnap7.so: dlopen failed: not found`

## Root Cause
The `dart_snap7` package (v0.5.3) **does not include Android native libraries**. You must provide `libsnap7.so` manually for each Android ABI (arm64-v8a, armeabi-v7a, x86_64).

## Solutions (Choose ONE)

### Solution 1: Use Moka7 (Java) - RECOMMENDED ✅

Moka7 is the official Java port of Snap7, designed specifically for Android.

**Advantages:**
- Pure Java - no native library hassles
- Officially supported for Android
- No NDK compilation required
- Better compatibility

**Implementation:**
1. Switch from `dart_snap7` to platform channels
2. Use Android native code with Moka7
3. Call Moka7 from your Flutter app via MethodChannel

**Steps:**
```yaml
# Remove from pubspec.yaml
dependencies:
  # dart_snap7: ^0.5.3  # Remove this
```

Then implement Android-side using Moka7:
- Download Moka7 from: https://snap7.sourceforge.net/
- Add to your Android project as a library
- Create MethodChannel bridge to Flutter

### Solution 2: Compile libsnap7.so with Android NDK

If you need native performance, compile Snap7 yourself.

**Requirements:**
- Android NDK installed
- CMake or ndk-build
- Snap7 source code (v1.4.2)

**Build Script** (see [build-snap7-android.sh](scripts/build-snap7-android.sh)):

```bash
#!/bin/bash
# Download Snap7 source
wget https://sourceforge.net/projects/snap7/files/1.4.2/snap7-full-1.4.2.7z

# Extract
7z x snap7-full-1.4.2.7z

# Build for arm64-v8a
export ANDROID_NDK=/path/to/ndk
export ABI=arm64-v8a
export API=21

$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${API}-clang++ \
    -shared \
    -fPIC \
    -O3 \
    -o libsnap7.so \
    snap7-full-1.4.2/release/Wrappers/c-cpp/*.cpp \
    snap7-full-1.4.2/release/Src/core/*.cpp \
    snap7-full-1.4.2/release/Src/sys/*.cpp

# Copy to Flutter project
cp libsnap7.so android/app/src/main/jniLibs/arm64-v8a/

# Repeat for armeabi-v7a using armv7a-linux-androideabi${API}-clang++
```

**Issues:**
- Complex setup
- Must build for multiple ABIs
- Maintenance burden
- No official Android support from Snap7

### Solution 3: Find Pre-built Libraries (NOT RECOMMENDED)

**Warning:** Using unverified libraries is a security risk.

If you find pre-built `libsnap7.so` from third parties:
1. Verify the ABI matches your device
2. Check file integrity
3. Test thoroughly
4. Only use for development/testing

Place files in:
```
android/app/src/main/jniLibs/
├── arm64-v8a/
│   └── libsnap7.so
├── armeabi-v7a/
│   └── libsnap7.so
└── x86_64/
    └── libsnap7.so
```

Restore [build.gradle](android/app/build.gradle) configuration:
```gradle
sourceSets {
    main.java.srcDirs += 'src/main/kotlin'
    main.jniLibs.srcDirs = ['src/main/jniLibs']
}
```

## Your Previous Libraries Were Wrong

Your previous `libsnap7.so` files had:
- **Identical size** (698758 bytes) for both ABIs
- **Same timestamp** (April 17, 2014)

This indicates they were duplicates or wrong ABIs, not proper builds for each architecture.

## Testing Your Library

After placing `.so` files, verify they're in the APK:

```bash
python -c "import zipfile; z = zipfile.ZipFile('build/app/outputs/flutter-apk/app-release.apk'); libs = [f for f in z.namelist() if 'libsnap7.so' in f]; print('Libraries found:'); [print(f'  {f}') for f in libs]; z.close()"
```

## Recommended Action Plan

1. **Short term**: Use Solution 3 with correct pre-built libraries for testing
2. **Long term**: Migrate to Moka7 (Solution 1) for production

## Resources

- Snap7 Homepage: https://snap7.sourceforge.net/
- Moka7 (Java): https://snap7.sourceforge.net/
- Android NDK Guide: https://developer.android.com/ndk/guides
- dart_snap7 package: https://pub.dev/packages/dart_snap7

## Need Help?

If you have working `libsnap7.so` files from another project:
1. Verify they're correct ABIs using `file` command on Linux
2. Check size differences between arm64-v8a and armeabi-v7a versions
3. Test on actual device (not just emulator)
