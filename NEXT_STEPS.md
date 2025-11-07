# Next Steps to Fix libsnap7.so Error

## What I Did

1. ✅ Identified the problem: `dart_snap7` doesn't include Android native libraries
2. ✅ Removed your incorrect duplicate `.so` files (they were same size for different ABIs)
3. ✅ Restored jniLibs configuration in [build.gradle](android/app/build.gradle)
4. ✅ Created proper jniLibs directory structure:
   - `android/app/src/main/jniLibs/arm64-v8a/`
   - `android/app/src/main/jniLibs/armeabi-v7a/`
   - `android/app/src/main/jniLibs/x86_64/`

## What You Need to Do

### Option 1: Get Correct libsnap7.so Files (Quick Fix)

You need CORRECT `libsnap7.so` files for each ABI. Your previous files were wrong.

**Where to get them:**
1. Build from source using Android NDK (see [SNAP7_ANDROID_SOLUTION.md](SNAP7_ANDROID_SOLUTION.md))
2. Find someone who has already built them (ask in Snap7 forums/communities)
3. Check if your PLC vendor provides Android libraries

**How to verify they're correct:**
- Different file sizes for arm64-v8a vs armeabi-v7a
- arm64-v8a is typically LARGER than armeabi-v7a
- Use `file` command on Linux: should show "ELF 64-bit" for arm64-v8a and "ELF 32-bit" for armeabi-v7a

**Place files here:**
```
android/app/src/main/jniLibs/
├── arm64-v8a/libsnap7.so      # For modern 64-bit phones
├── armeabi-v7a/libsnap7.so    # For older 32-bit phones
└── x86_64/libsnap7.so         # For emulator (optional)
```

**Then rebuild:**
```bash
flutter clean
flutter build apk --release
```

**Verify library is in APK:**
```bash
python -c "import zipfile; z = zipfile.ZipFile('build/app/outputs/flutter-apk/app-release.apk'); libs = [f for f in z.namelist() if 'libsnap7.so' in f]; print('Found:' if libs else 'NOT FOUND'); [print(f'  {f}') for f in libs]; z.close()"
```

### Option 2: Switch to Moka7 (RECOMMENDED for Production)

Moka7 is the official Java version of Snap7, designed for Android.

**Advantages:**
- ✅ No native library issues
- ✅ Officially supported
- ✅ Easier to maintain
- ✅ Better Android integration

**How to switch:**
1. Remove `dart_snap7` from [pubspec.yaml](pubspec.yaml)
2. Download Moka7 from https://snap7.sourceforge.net/
3. Add Moka7 JAR to your Android project
4. Create a MethodChannel bridge from Flutter to Android
5. Call Moka7 from Android native code

See [SNAP7_ANDROID_SOLUTION.md](SNAP7_ANDROID_SOLUTION.md) for detailed implementation.

## Testing Checklist

After getting correct libraries:

- [ ] `.so` files have DIFFERENT sizes for each ABI
- [ ] Files exist in jniLibs folders
- [ ] Clean build completed successfully
- [ ] APK contains lib/*/libsnap7.so (verify with Python script above)
- [ ] Fully uninstall old app from device
- [ ] Install new APK
- [ ] Test PLC connection on actual device

## Files Created

1. [SNAP7_ANDROID_SOLUTION.md](SNAP7_ANDROID_SOLUTION.md) - Complete guide with all solutions
2. [scripts/download-snap7-android.ps1](scripts/download-snap7-android.ps1) - Download script (needs NDK compilation)
3. This file - Quick next steps

## Need Help?

Check the Snap7 community:
- SourceForge Forums: https://sourceforge.net/p/snap7/discussion/
- Official Snap7 Site: https://snap7.sourceforge.net/

Or consider hiring someone with Android NDK experience to compile the libraries for you.
