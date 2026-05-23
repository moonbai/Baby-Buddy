# Baby Buddy Client

[中文版本](README.md)

A Flutter mobile app client for [Baby Buddy](https://github.com/babybuddy/babybuddy), helping you easily track your baby's daily activities!

## ✨ Features

- 📱 **Modern Mobile UI**: Material Design 3, clean and intuitive
- 🌙 **Theme Settings**: Light/Dark/System theme support
- 🎨 **Full Dark Mode Support**: All pages fully support dark mode
- 🌐 **Multi-language Support**: Chinese and English, switchable in settings
- ⏱️ **Activity Timer**: Real-time timer for feeding, sleep, tummy time, fixed timer sync issues
- 🔐 **Secure Authentication**: Secure connection to Baby Buddy server via Token
- 👶 **Multi-child Management**: Support for multiple babies
- 📝 **Quick Recording**: One-tap recording for feeding, sleep, diapers, pumping
- ⚡ **Quick Report Mode**: Enable in settings for fast recording
- 📏 **Body Measurements**: Track weight, height, head circumference, temperature
- 📊 **Timeline View**: View complete timeline of baby activities
- ✏️ **Edit & Delete**: Modify and delete recorded activities
- 📦 **Auto APK Build**: Built-in GitHub Actions CI/CD

## 📁 Project Structure

```
lib/
├── api/
│   └── api_service.dart          # API service layer
├── screens/
│   ├── login_screen.dart         # Login screen
│   ├── home_screen.dart          # Main screen with timeline and timers
│   ├── child_select.dart         # Child selection screen
│   ├── quick_add.dart            # Quick add screen
│   ├── settings_screen.dart      # Settings screen
│   └── about_screen.dart         # About screen
├── theme/
│   └── app_theme.dart            # Theme configuration
├── utils/
│   ├── storage.dart              # Local storage utilities
│   ├── date_time_utils.dart      # DateTime utilities
│   └── timer_manager.dart        # Timer manager
├── widgets/
│   ├── animated_widgets.dart     # Animation widgets
│   └── timer_card.dart           # Timer card widget
├── generated/
│   ├── app_localizations.dart    # Internationalization main file
│   ├── app_localizations_zh.dart # Chinese translations
│   └── app_localizations_en.dart # English translations
├── l10n/
│   ├── app_zh.arb                # Chinese language resources
│   └── app_en.arb                # English language resources
└── main.dart                     # App entry point
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.24.0+
- **Design**: Material Design 3
- **Network**: Dio
- **Storage**: SharedPreferences
- **Date**: intl
- **Toast**: fluttertoast
- **HTML**: html
- **URL**: url_launcher
- **i18n**: flutter_localizations

## 🚀 Quick Start

### Prerequisites

- Flutter SDK installed (3.0+)
- Baby Buddy server running

### Installation & Running

1. Clone project：
   ```bash
   git clone https://github.com/moonbai/Baby-Buddy.git
   cd Baby-Buddy
   ```

2. Install dependencies：
   ```bash
   flutter pub get
   ```

3. Run app：
   ```bash
   flutter run
   ```

## 📖 User Guide

1. **Login**: Enter server address, username, password
2. **Select Baby**: Tap menu to select baby
3. **Start Timer**: Tap "+" button, select "Start Timer"
4. **Quick Record**: Tap "+" for quick recording
5. **View Timeline**: Main screen shows timeline, pull to refresh
6. **Edit Records**: Expand card to edit/delete
7. **Use Timer**: Tap timer card to record activity
8. **Theme Settings**: Menu > Settings to change theme
9. **Quick Report**: Enable in settings for quick options
10. **Language Switch**: Settings > Choose language

## 🎨 Theme & Animation

### Theme System
- Three modes: Light/Dark/System
- Switchable in settings
- Unified color scheme and component styles
- Full dark mode support

### Animation Components
- **AnimatedScroll**: Fade-in slide animation on scroll
- **AnimatedScale**: Scale animation
- **AnimatedFade**: Fade in/out effect
- **BouncingButton**: Bounce feedback on tap
- **ShakeWidget**: Shake effect (e.g., error hints)

## 🌐 Multi-language Support

This app supports Chinese and English.

Switch language: Settings > Language Settings > Choose language

To add more languages, extend arb files in `lib/l10n/`.

## 🔧 Build & Deploy

### Local Build

```bash
flutter build apk --release
```

### Auto Build

This project includes GitHub Actions workflow that automatically builds APK on push to `main`. APK artifacts are available in Actions page.

### APK Signing

For APK signing, configure these Secrets:

- `ANDROID_KEYSTORE_BASE64`: Base64 encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password
- `ANDROID_KEY_ALIAS`: Key alias
- `ANDROID_KEY_PASSWORD`: Key password

See [SIGNING.md](SIGNING.md) for details.

## 📚 Related Links

- Baby Buddy Official Project: https://github.com/babybuddy/babybuddy
- Flutter Official: https://flutter.dev
- Material Design 3: https://m3.material.io

## 📄 License

MIT License
