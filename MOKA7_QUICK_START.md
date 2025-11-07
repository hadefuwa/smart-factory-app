# Moka7 Quick Start Guide

## What Just Happened?

Your app has been migrated from `dart_snap7` (native libraries) to **Moka7** (pure Java).

**Result:** The `libsnap7.so` error is **permanently fixed**! 🎉

## Build and Install

```bash
# 1. Clean and build
flutter clean
flutter build apk --release

# 2. Uninstall old app first (important!)
adb uninstall com.matrixtsl.smart_factory

# 3. Install new APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Quick Test

1. **Open App** → Settings → PLC Configuration

2. **Configure Connection:**
   - IP Address: `192.168.0.99` (your PLC IP)
   - Rack: `0`
   - Slot: `1` (for S7-1200/1500)
   - Enable Live Mode

3. **Check Connection:**
   - Go to Data Stream Log
   - Look for: "✓ Successfully connected to S7 PLC using Moka7!"

## PLC Rack/Slot Settings

| PLC Model    | Rack | Slot |
|-------------|------|------|
| S7-1200     | 0    | 1    |
| S7-1500     | 0    | 1    |
| S7-300      | 0    | 2    |
| S7-400      | 0    | 2    |

## Code Example

```dart
final plc = PLCCommunicationService();
await plc.initialize();
await plc.setPlcIpAddress('192.168.0.99');
await plc.setRackSlot(0, 1);
await plc.setLiveMode(true);

// Read DB1.DBX0.0 (boolean)
final isRunning = await plc.readDbBool(1, 0, 0);

// Write DB1.DBW2 = 100 (integer)
await plc.writeDbInt(1, 2, 100);

// Read DB1.DBD10 (float)
final temp = await plc.readDbReal(1, 10);
```

## Troubleshooting

### Still Getting Library Error?
**Uninstall old app completely:**
```bash
adb uninstall com.matrixtsl.smart_factory
```

### Connection Fails?
1. Check PLC IP is correct
2. Ensure PLC and phone on same network
3. Enable PUT/GET in TIA Portal
4. Check firewall settings

### Need Help?
- Check [MOKA7_IMPLEMENTATION.md](MOKA7_IMPLEMENTATION.md) for full details
- Review Data Stream Log for error messages

## What's Different?

| Before (dart_snap7)         | After (Moka7)              |
|----------------------------|----------------------------|
| ❌ Native .so libraries     | ✅ Pure Java               |
| ❌ NDK/ABI issues           | ✅ No native dependencies  |
| ❌ Hard to debug            | ✅ Clear error messages    |
| ❌ Platform-specific builds | ✅ Works on all Android    |

## Your Existing Code Still Works!

All your PLC communication code continues to work without changes. The migration is internal only.

## Done! 🚀

You can now:
- Build APKs without libsnap7.so errors
- Connect to S7 PLCs reliably
- Debug issues more easily
- Deploy to any Android device
