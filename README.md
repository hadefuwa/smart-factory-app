# Vice App - Fasting Reward Tracker

A beautiful Flutter app to track multiple good habits (fasting, YouTube videos, etc.) and reward yourself with growing daily amounts toward your goals.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Android](https://img.shields.io/badge/Android-21+-3DDC84?logo=android)
![License](https://img.shields.io/badge/license-MIT-blue)

## ✨ Features

### 🎯 Goal Management
- Create and manage reward goals (e.g., "50\" TV - £250")
- Add custom images to visualize your goals
- Track progress with visual progress bars
- Set target amounts, base rewards, and growth percentages

### 📊 Multiple Habit Tracking
- Track multiple good habits individually (fasting, YouTube videos, exercise, reading, etc.)
- Each habit has its own streak counter
- Select from 12+ built-in icons for your habits
- Activate/deactivate habits as needed

### 💰 Smart Reward System
- **Percentage-based growth**: Rewards increase by a set percentage each consecutive day
- **Same reward structure**: All habits earn the same reward amount (based on your goal settings)
- **Combined rewards**: Rewards from all habits combine toward your goal
- **Smart streak handling**: 
  - If you miss a day, your streak resets
  - Your reward rate stays the same until you surpass your previous longest streak
  - Then continues growing with percentage-based increases

### 📈 Progress Tracking
- Individual streak tracking for each habit
- Combined reward calculation from all active habits
- Visual progress indicators
- Estimated days remaining to reach goals
- Total saved amount tracking

### 🎨 Beautiful UI
- Material Design 3 theming
- Smooth animations and transitions
- Responsive layout
- Intuitive navigation

## 📱 Screenshots

*Add screenshots of your app here*

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Android Studio (for Android development)
- Android device or emulator (API 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/hadefuwa/habit-app.git
   cd habit-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # On Windows desktop (recommended for testing)
   flutter run -d windows
   
   # On Android device/emulator
   flutter run
   ```

### Quick Start Scripts

**Windows:**
- Double-click `run-app.bat` to launch the app
- Or use PowerShell: `.\run-app.ps1`

**Command Line:**
```bash
# Add Flutter to PATH for easier access
# Then simply run:
flutter run -d windows
```

## 📖 How to Use

### Creating a Goal

1. Navigate to the **Goals** tab
2. Tap the **"New Goal"** button
3. Enter:
   - Goal name (e.g., "50\" TV")
   - Target amount (e.g., £250)
   - Base reward per day (e.g., £5)
   - Growth percentage (e.g., 10%)
   - Optional: Add an image
4. Tap **"Create Goal"**

### Adding Habits

1. Navigate to the **Habits** tab
2. Tap **"New Habit"** or the floating action button
3. Enter habit name (e.g., "Exercise", "Reading")
4. Select an icon from the grid
5. Tap **"Create Habit"**

### Tracking Your Progress

1. Go to the **Home** tab
2. Select a habit from the habit chips
3. Tap **"Mark [Habit Name]"** to record completion for today
4. View your streak and reward progress
5. See combined rewards from all habits

### Understanding Rewards

**Example:**
- Base reward: £5/day
- Growth: 10% per day
- Day 1: £5.00
- Day 2: £5.50 (10% increase)
- Day 3: £6.05 (10% increase)
- Day 4: £6.66 (10% increase)
- And so on...

**If you miss a day:**
- Streak resets to 0
- Reward rate stays at the level from your longest streak
- Once you surpass your previous longest streak, rewards continue growing

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   ├── goal.dart               # Goal model
│   ├── habit.dart              # Habit model
│   └── streak.dart             # Streak model
├── providers/                   # State management
│   ├── goal_provider.dart      # Goal state management
│   ├── habit_provider.dart     # Habit state management
│   └── streak_provider.dart    # Streak state management
├── screens/                     # UI screens
│   ├── home_screen.dart        # Main home screen
│   ├── goals_screen.dart       # Goals list screen
│   ├── habits_screen.dart      # Habits list screen
│   ├── add_goal_screen.dart    # Add/edit goal form
│   └── add_habit_screen.dart   # Add/edit habit form
├── services/                    # Business logic
│   ├── local_storage_service.dart  # Data persistence
│   ├── reward_calculator.dart     # Reward calculations
│   └── image_service.dart         # Image handling
└── widgets/                     # Reusable widgets
    ├── goal_card.dart          # Goal display card
    └── streak_display.dart     # Streak display widget
```

## 🛠️ Technologies Used

- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **Shared Preferences** - Local data storage
- **Image Picker** - Image selection functionality
- **Path Provider** - File system access
- **Material Design 3** - Modern UI components

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  shared_preferences: ^2.2.2
  provider: ^6.1.1
  intl: ^0.19.0
  uuid: ^4.3.3
  image_picker: ^1.0.7
  path_provider: ^2.1.1
  path: ^1.8.3
```

## 🔧 Configuration

### Android Permissions

The app requires the following permissions (already configured in `AndroidManifest.xml`):
- `READ_EXTERNAL_STORAGE` - For accessing images
- `READ_MEDIA_IMAGES` - For Android 13+ image access

### Windows Support

For Windows desktop support:
```bash
flutter create --platforms=windows .
```

**Note:** Developer Mode must be enabled on Windows for plugin support.

## 💾 Data Storage

All data is stored locally on your device using:
- **SharedPreferences** - For goals, habits, and streaks
- **App Documents Directory** - For goal images

Data persists across app restarts and is stored locally (no cloud sync).

## 🎯 Features in Detail

### Reward Calculation

The reward system uses compound growth:
- Formula: `baseReward × (1 + growthPercentage/100) ^ (streakDays - 1)`
- Each consecutive day increases the reward by the specified percentage
- Rewards from all habits are combined toward your goal

### Streak Management

- **Current Streak**: Days you've completed the habit consecutively
- **Longest Streak**: Your best streak for that habit
- **Auto-reset**: Streaks reset if you miss a day
- **Reward Persistence**: Reward rate maintains until you beat your longest streak

### Habit Tracking

- Track unlimited habits
- Each habit tracked independently
- Visual indicators show which habits are completed today
- Easy activation/deactivation of habits

## 📱 Building for Android

### Quick Build

Use the provided build scripts:

**Windows (Command Prompt/PowerShell):**
```bash
.\build-apk.bat
```

Or manually:
```bash
flutter build apk --release
```

The APK will be created at: `build\app\outputs\flutter-apk\app-release.apk`

### Prerequisites for Android Build

**Java 17 Required:**

1. **Download Java 17:**
   - Visit: https://adoptium.net/temurin/releases/?version=17
   - Download Windows x64 installer (.msi)

2. **Install:**
   - Install to default location
   - ✅ Check "Add to PATH" during installation

3. **Set JAVA_HOME:**
   - Press `Win + X` → "System"
   - "Advanced system settings" → "Environment Variables"
   - Add new variable: `JAVA_HOME` = `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`
   - Restart terminal

4. **Verify:**
   ```bash
   java -version
   # Should show: openjdk version "17.x.x"
   ```

**Android SDK:**

The project is configured with:
- compileSdk: 36
- targetSdk: 36
- minSdk: 21 (Android 5.0+)
- Android Gradle Plugin: 8.6.0
- Kotlin: 2.1.0
- Gradle: 8.7

### Build Configuration

The build scripts automatically:
- Detect Java 17 installation
- Configure Android SDK paths
- Generate release APK (46MB)

## 📲 Installing on Your Phone

### Method 1: Transfer APK File (Recommended)

1. **Build the APK** (see above)

2. **Transfer to phone:**
   - Email the APK to yourself
   - Use Google Drive/Dropbox
   - Transfer via USB cable
   - Use Bluetooth

3. **Install on phone:**
   - Go to Settings → Security → Enable "Install unknown apps"
   - Open the APK file on your phone
   - Tap "Install"

### Method 2: Direct USB Install

1. **Enable USB Debugging on phone:**
   - Settings → About phone
   - Tap "Build number" 7 times
   - Go to Settings → Developer options
   - Enable "USB debugging"

2. **Connect phone to computer via USB**

3. **Install directly:**
   ```bash
   .\install-on-phone.bat
   ```

   Or manually:
   ```bash
   flutter run
   ```

### Method 3: Using Android Studio

1. Open project in Android Studio
2. Connect phone via USB (USB debugging enabled)
3. Click the green "Run" button (▶️)
4. Select your phone from device list

## 🐛 Troubleshooting

### Build Issues

**"Java 17 not found"**
- Install Java 17 from Adoptium (see Prerequisites)
- Ensure JAVA_HOME is set correctly
- Restart terminal after installation

**"Android SDK not found"**
- Install Android Studio
- The build will auto-download required SDK components

**"Device not showing up"**
- Enable USB debugging on phone
- Use a data cable (not charging-only)
- Try different USB port
- Install phone manufacturer's USB drivers

### Runtime Issues

**App won't run on Windows**

Enable Developer Mode:
1. Press `Win + X` → "System"
2. Go to "Privacy & Security" → "For developers"
3. Toggle "Developer Mode" ON
4. Restart your terminal
5. Run the app again

**Images not showing**

- Ensure app has storage permissions
- Check that images exist at the stored path
- Try re-adding the image to the goal

**Streaks not updating**

- Make sure you're marking habits on consecutive days
- Check that the app has the correct date/time
- Try refreshing the screen (pull down)

**"Install blocked" on phone**
- Go to Settings → Security → Unknown sources
- Enable installation from unknown sources
- Or enable for specific app (File Manager, Email)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with Flutter
- Material Design 3 components
- Icons from Material Icons

## 📞 Support

For issues, questions, or suggestions, please open an issue on GitHub.

---

**Made with ❤️ for tracking your good habits and rewarding yourself!**
