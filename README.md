# Smart Factory Control App

A teaching and control companion for the Smart Factory training rig. This mobile app provides students and instructors with comprehensive control, monitoring, and learning tools for Industry 4.0 manufacturing education.

## Features

### 🏠 Home Screen
- Real-time system status monitoring
- Live metrics display (Produced, Rejects, FPY, Throughput, Uptime)
- Quick control buttons (Start, Stop, Reset Faults)
- Connection status indicator (Simulation mode)

### ▶️ Run Control
- Recipe management (Steel/Aluminium/Plastic Sorting)
- Conveyor speed control (0-100%)
- Batch target configuration
- Live material counters (Steel, Aluminium, Plastic, Rejects, Remaining)
- Manual jog controls for all actuators
- Safety interlocks enforcement

### 🔌 I/O Live
- Real-time input monitoring (First Gate, Inductive, Capacitive, Photo Gate, E-Stop, Gantry Home)
- Output control (Conveyor, Paddles, Plunger, Vacuum, Gantry)
- Interactive output activation with confirmation dialogs
- Visual status indicators with animated lights
- Safety blocking notifications

### 📚 Worksheets
- 17 comprehensive learning activities
- Progress tracking (percentage completion)
- Step-by-step guided instructions
- Topics include:
  - Data logging and analytics
  - Conveyor and sensor control
  - Material sorting operations
  - Manual jog procedures
  - FPY and throughput analysis
  - Safety interlock understanding
  - Emergency stop procedures
  - Batch production
  - Pneumatic systems
  - Fault diagnosis
  - Predictive maintenance
  - IO-Link technology
  - Advanced analytics

### 📊 Analytics
- Real-time KPI tiles (Throughput, FPY, Rejects)
- Performance charts visualization
- CSV data export functionality
  - Metrics export (timestamp, throughput, FPY, rejects, total)
  - Event log export (timestamp, name, value, type)
- Configurable time windows (15 min, 1 hour, today)

### ⚙️ Settings
- **Mode Selection**: Simulation (live hardware coming later)
- **Simulator Configuration**:
  - Speed scaling (0.1x - 2.0x)
  - Material mix adjustment (Steel, Aluminium, Plastic percentages)
- **Fault Injection**:
  - Random faults toggle
  - Manual fault triggers (E-Stop, Sensor Stuck, Paddle Jam, Vacuum Leak)
- **About Information**: App version, quick help guide

## Version 0 - Simulation Mode

This initial release runs entirely on simulated data and works without physical hardware. The simulator accurately models:

- **Conveyor System**: Virtual parts moving along the belt at configurable speeds
- **Sensor Behavior**: First gate, inductive (steel detection), capacitive (aluminium detection), photo gate
- **Sorting Logic**: Automatic paddle actuation based on material type
- **Metrics Calculation**: Real-time FPY and throughput computation
- **Fault Simulation**: E-Stop, sensor stuck, paddle jam, vacuum leak
- **Safety Interlocks**:
  - Plunger blocked while conveyor running
  - All outputs disabled during E-Stop
  - Clear blocking notifications

## Technical Details

### Architecture
- **Framework**: Flutter (Dart)
- **Design**: Material Design 3 with dark theme
- **State Management**: Stream-based reactive architecture
- **Simulation**: 10Hz update rate with virtual part tracking
- **Data Logging**: Automatic metrics and event capture

### Color Scheme
- **Green**: Running/OK states
- **Amber**: Warning or paused states
- **Red**: Fault or E-Stop states
- **Blue**: Neutral information
- **Purple**: Primary brand color

### Safety Features
- Comprehensive interlock system preventing unsafe operations
- Clear visual and text feedback for blocked actions
- Single Reset Faults button on Home screen
- Emergency stop simulation and recovery

## Future Development

### Planned Features (Post-v0)
- Live hardware connection via PLC/Raspberry Pi gateway
- Real-time chart visualization with fl_chart library
- Enhanced OEE (Overall Equipment Effectiveness) calculations
- Multi-language support
- User authentication for instructor/student roles
- Cloud data synchronization
- Custom worksheet creation tools

## Building the App

### Prerequisites
- Flutter SDK (>=3.0.0 <4.0.0)
- Android SDK for Android builds
- Xcode for iOS builds (macOS only)

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  webview_flutter: ^4.4.2
  youtube_player_iframe: ^4.0.4
  url_launcher: ^6.2.5
  timezone: ^0.9.2
  flutter_svg: ^2.0.9
  video_player: ^2.8.2
  chewie: ^1.7.4
  path_provider: ^2.1.1
```

### Build Commands
```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build Android APK
flutter build apk --release

# Build iOS app
flutter build ios --release
```

## App Structure

```
lib/
├── main.dart                          # App entry point with routing
├── models/
│   ├── simulator_state.dart           # State enums and SimulatorState class
│   ├── metrics_data.dart              # MetricsSnapshot, EventLogEntry, BatchRecord
│   ├── worksheet.dart                 # Worksheet model and data
│   └── product.dart                   # Legacy product model (for reference)
├── services/
│   └── simulator_service.dart         # Core simulation engine
├── screens/
│   ├── smart_factory_main.dart        # Main app with bottom navigation
│   ├── sf_home_screen.dart            # Home/Dashboard screen
│   ├── sf_run_screen.dart             # Run control screen
│   ├── sf_io_screen.dart              # I/O monitoring screen
│   ├── sf_worksheets_screen.dart      # Worksheets list and detail
│   ├── sf_analytics_screen.dart       # Analytics and export
│   └── sf_settings_screen.dart        # Settings and configuration
└── widgets/
    ├── hexagon_background.dart        # Animated background
    └── logo_widget.dart               # App logo component
```

## Educational Value

The Smart Factory app provides hands-on experience with:
- **Industry 4.0 Concepts**: Real-time monitoring, data analytics, automation
- **Manufacturing Metrics**: FPY, throughput, OEE, uptime tracking
- **Control Systems**: PLC-style logic, interlocks, fault handling
- **Quality Control**: Sensor-based sorting, reject tracking
- **Predictive Maintenance**: Trend analysis, fault pattern recognition
- **Data Analysis**: CSV export for external analysis tools
- **Safety Protocols**: Emergency stop procedures, interlock compliance

## Support

For issues, questions, or contributions:
- GitHub: https://github.com/hadefuwa/matrix-android-app
- Email: support@matrixtsl.com
- Website: https://www.matrixtsl.com/smartfactory/

## License

© 2025 Matrix TSL. All rights reserved.

## Acknowledgments

Built with Flutter for cross-platform mobile deployment. Designed for Matrix TSL Smart Factory training systems.

---

**Version**: 1.0.5
**Last Updated**: 2025-11-07
**Mode**: Simulation (v0)
**Status**: Production Ready
