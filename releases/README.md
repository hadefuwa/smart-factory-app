# Smart Factory App Releases

## Version 1.0.9 (Latest) - 2025-11-07

**Download:** [smart-factory-v1.0.9.apk](smart-factory-v1.0.9.apk)

### Major Update: libsnap7.so Error Fixed Permanently!

This release completely solves the `Failed to load dynamic library libsnap7.so` error by migrating from dart_snap7 (native libraries) to **Moka7** (pure Java).

### What's New
- ✅ **Migrated to Moka7** - Pure Java S7 PLC communication library
- ✅ **Removed libsnap7.so** - No native libraries needed
- ✅ **Works on ALL Android devices** - No ABI compatibility issues
- ✅ **Added Moka7-live v0.0.11** - Official Java port of Snap7
- ✅ **Created PLCManager.kt** - Comprehensive PLC communication manager
- ✅ **MethodChannel bridge** - Flutter ↔ Android communication

### Features
- **PLC Communication**: Connect to S7-1200, S7-1500, S7-300, S7-400
- **Data Types**: Read/Write BOOL, INT, DINT, REAL, byte arrays
- **Reliability**: Automatic connection retry and status monitoring
- **Logging**: Data stream logging for debugging
- **Platform**: Android only (pure Java implementation)

### Installation
1. **Uninstall old version first (important!):**
   ```bash
   adb uninstall com.matrixtsl.smart_factory
   ```
2. Download and install `smart-factory-v1.0.9.apk`
3. Configure PLC settings in app:
   - Settings → PLC Configuration
   - Set IP address (e.g., 192.168.0.99)
   - Set Rack/Slot (S7-1200/1500: Rack 0, Slot 1)
   - Enable Live Mode

### What This Fixes
- ✅ libsnap7.so not found error (permanently fixed)
- ✅ ABI compatibility issues
- ✅ Native library loading errors
- ✅ Platform-specific build problems

### Documentation
- [MOKA7_IMPLEMENTATION.md](../MOKA7_IMPLEMENTATION.md) - Complete technical documentation
- [MOKA7_QUICK_START.md](../MOKA7_QUICK_START.md) - Quick start guide
- [MIGRATION_SUMMARY.md](../MIGRATION_SUMMARY.md) - Full migration details

### File Info
- **File**: smart-factory-v1.0.9.apk
- **Size**: 62.0 MB
- **Build Type**: Release
- **Version**: 1.0.9+2
- **Minimum SDK**: 21 (Android 5.0)
- **Target SDK**: 36 (Android 14)

---

## Version 1.0.6

**Download:** [smart-factory-v1.0.6.apk](smart-factory-v1.0.6.apk)

### What's New
- ✨ **Animated Splash Screen**: Beautiful logo animation on app launch
- 🍔 **Hamburger Menu**: Easy access to About and Contact screens from any screen
- 🎨 **Rebranded to Smart Factory**: Complete app rebranding from Matrix TSL
- 🎯 **Improved Navigation**: Consistent drawer menu across all screens

### Features
- **Animated Splash Screen**: Logo2.svg with fade, scale, rotation, pulse, and glow animations
- **Navigation Drawer**: Access About, Contact, and Settings from any screen
- **Smart Factory Branding**: Updated app name, labels, and all user-facing text
- **Complete Smart Factory Control App**: 5 main screens with bottom navigation
- **Full Simulation Engine**: 10Hz update rate with comprehensive metrics
- **17 Learning Worksheets**: Educational content for Industry 4.0 training
- **Real-time Metrics**: FPY, Throughput, Uptime tracking
- **CSV Data Export**: Export metrics and event logs for analysis
- **Safety Features**: Comprehensive interlocks and fault injection

### Installation
1. Download the APK file
2. Enable "Install from Unknown Sources" on your Android device
3. Install the APK
4. Launch Smart Factory app

### Requirements
- Android 5.0 (API 21) or higher
- ~60 MB storage space

### File Info
- **File**: smart-factory-v1.0.6.apk
- **Size**: 54.2 MB
- **Build Type**: Release
- **Minimum SDK**: 21 (Android 5.0)

---

## Version 1.0.5 (2025-11-07)

**Download:** [smart-factory-v1.0.5.apk](smart-factory-v1.0.5.apk)

### What's New
- Complete Smart Factory Control App implementation
- 5 main screens with bottom navigation (Home, Run, I/O, Worksheets, Analytics)
- Full simulation engine with 10Hz update rate
- 17 comprehensive learning worksheets
- Real-time metrics and CSV data export
- Safety interlocks and fault injection
- Material sorting simulation (Steel, Aluminium, Plastic)

### Features
- **Simulation Mode**: Runs entirely offline without hardware
- **Live Metrics**: FPY, Throughput, Uptime tracking
- **Interactive Controls**: Start/Stop, Manual jog, Output control
- **Educational Content**: Guided learning activities
- **Data Export**: CSV files for analysis
- **Safety Features**: Comprehensive interlocks

### File Info
- **File**: smart-factory-v1.0.5.apk
- **Size**: 51.3 MB
- **Build Type**: Release
- **Minimum SDK**: 21 (Android 5.0)

---

## Previous Versions

### Version 1.0.4
- Updated app bar layout
- Fixed video player
- Logo improvements

### Version 1.0.3
- Initial Matrix TSL product showcase
- WebView integration
- 3D model viewer
