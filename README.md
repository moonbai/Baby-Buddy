# Baby Buddy 客户端 / Baby Buddy Client

A Flutter mobile app client for [Baby Buddy](https://github.com/babybuddy/babybuddy), helping you easily track your baby's daily activities!

一个为 [Baby Buddy](https://github.com/babybuddy/babybuddy) 打造的 Flutter 移动应用客户端，帮助您轻松记录宝宝的日常活动！

## ✨ 功能特点 / Features

- 📱 **现代化移动端界面**：Material Design 3 设计，简洁直观 / **Modern Mobile UI**: Material Design 3, clean and intuitive
- 🌙 **主题设置**：支持浅色/深色/跟随系统三种主题模式 / **Theme Settings**: Light/Dark/System theme support
- 🎨 **深色模式完全支持**：所有页面都完美适配深色模式 / **Full Dark Mode Support**: All pages fully support dark mode
- 🌐 **多语言支持**：支持中文和英文，可在设置中切换 / **Multi-language Support**: Chinese and English, switchable in settings
- ⏱️ **活动计时器**：支持喂奶、睡眠、俯卧时间的实时计时，解决了计时器时间同步问题 / **Activity Timer**: Real-time timer for feeding, sleep, tummy time, fixed timer sync issues
- 🔐 **安全认证**：通过 Token 安全连接到您的 Baby Buddy 服务器 / **Secure Authentication**: Secure connection to Baby Buddy server via Token
- 👶 **多宝宝管理**：支持选择和管理多个宝宝 / **Multi-child Management**: Support for multiple babies
- 📝 **快速记录**：一键记录喂奶、睡眠、尿布、吸奶等日常活动 / **Quick Recording**: One-tap recording for feeding, sleep, diapers, pumping
- ⚡ **快速提报模式**：可在设置中开启，点击按钮直接弹出常用选项快速记录 / **Quick Report Mode**: Enable in settings for fast recording
- 📏 **身体测量**：记录体重、身高、头围和体温 / **Body Measurements**: Track weight, height, head circumference, temperature
- 📊 **时间线查看**：查看宝宝所有活动的完整时间线 / **Timeline View**: View complete timeline of baby activities
- ✏️ **编辑和删除**：支持修改和删除已记录的活动 / **Edit & Delete**: Modify and delete recorded activities
- 📦 **APK 自动打包**：内置 GitHub Actions 自动构建流程 / **Auto APK Build**: Built-in GitHub Actions CI/CD

## 📁 项目结构 / Project Structure

```
lib/
├── api/
│   └── api_service.dart          # API 服务层，处理所有与服务器的通信 / API service layer
├── screens/
│   ├── login_screen.dart         # 登录界面 / Login screen
│   ├── home_screen.dart          # 主界面，显示时间线和计时器 / Main screen with timeline and timers
│   ├── child_select.dart         # 宝宝选择界面 / Child selection screen
│   ├── quick_add.dart            # 快速记录界面 / Quick add screen
│   ├── settings_screen.dart      # 设置界面 / Settings screen
│   └── about_screen.dart         # 关于界面 / About screen
├── theme/
│   └── app_theme.dart            # 应用主题配置（Material Design 3）/ Theme configuration
├── utils/
│   ├── storage.dart              # 本地存储工具类 / Local storage utilities
│   ├── date_time_utils.dart      # 日期时间处理工具 / DateTime utilities
│   └── timer_manager.dart        # 计时器管理器 / Timer manager
├── widgets/
│   ├── animated_widgets.dart     # 动画组件库 / Animation widgets
│   └── timer_card.dart           # 计时器卡片组件 / Timer card widget
├── generated/
│   ├── app_localizations.dart    # 国际化主文件 / Internationalization main file
│   ├── app_localizations_zh.dart # 中文翻译 / Chinese translations
│   └── app_localizations_en.dart # 英文翻译 / English translations
├── l10n/
│   ├── app_zh.arb                # 中文语言资源 / Chinese language resources
│   └── app_en.arb                # 英文语言资源 / English language resources
└── main.dart                     # 应用入口 / App entry point
```

## 🛠️ 技术栈 / Tech Stack

- **框架 / Framework**: Flutter 3.24.0+
- **设计 / Design**: Material Design 3
- **网络请求 / Network**: Dio
- **本地存储 / Storage**: SharedPreferences
- **日期处理 / Date**: intl
- **提示信息 / Toast**: fluttertoast
- **HTML 解析 / HTML**: html
- **链接跳转 / URL**: url_launcher
- **国际化 / i18n**: flutter_localizations

## 🚀 快速开始 / Quick Start

### 前置条件 / Prerequisites

- 已安装 Flutter SDK (3.0+) / Flutter SDK installed (3.0+)
- 有运行中的 Baby Buddy 服务器 / Baby Buddy server running

### 安装与运行 / Installation & Running

1. 克隆项目 / Clone project：
   ```bash
   git clone https://github.com/moonbai/Baby-Buddy.git
   cd Baby-Buddy
   ```

2. 安装依赖 / Install dependencies：
   ```bash
   flutter pub get
   ```

3. 运行应用 / Run app：
   ```bash
   flutter run
   ```

## 📖 使用说明 / User Guide

1. **登录 / Login**：在登录界面输入您的 Baby Buddy 服务器地址、用户名和密码 / Enter server address, username, password
2. **选择宝宝 / Select Baby**：在主界面点击右上角菜单，选择要记录的宝宝 / Tap menu to select baby
3. **启动计时器 / Start Timer**：点击右下角 "+" 按钮，选择"启动定时器" / Tap "+" button, select "Start Timer"
4. **快速记录 / Quick Record**：点击右下角 "+" 按钮，快速记录各类活动 / Tap "+" for quick recording
5. **查看时间线 / View Timeline**：主界面显示所有活动的时间线，下拉刷新 / Main screen shows timeline, pull to refresh
6. **编辑记录 / Edit Records**：展开卡片后可编辑或删除记录 / Expand card to edit/delete
7. **使用计时器 / Use Timer**：点击活动的计时器卡片，选择对应的记录类型 / Tap timer card to record activity
8. **主题设置 / Theme Settings**：点击右上角菜单，选择"设置"，切换浅色/深色/跟随系统主题 / Menu > Settings to change theme
9. **快速提报模式 / Quick Report**：在设置中开启后，点击 "+" 按钮可快速选择常用选项 / Enable in settings for quick options
10. **语言切换 / Language Switch**：在设置中选择简体中文或 English / Settings > Choose language

## 🎨 主题与动画 / Theme & Animation

### 主题系统 / Theme System
- 支持三种模式：浅色/深色/跟随系统 / Three modes: Light/Dark/System
- 在设置中可自由切换 / Switchable in settings
- 统一的配色方案和组件样式 / Unified color scheme and component styles
- 所有页面完美适配深色模式 / Full dark mode support

### 动画组件 / Animation Components
- **AnimatedScroll**: 滚动时的淡入滑入动画 / Fade-in slide animation on scroll
- **AnimatedScale**: 缩放动画效果 / Scale animation
- **AnimatedFade**: 淡入淡出效果 / Fade in/out effect
- **BouncingButton**: 点击时的弹跳反馈 / Bounce feedback on tap
- **ShakeWidget**: 抖动效果（如错误提示）/ Shake effect (e.g., error hints)

## 🌐 多语言支持 / Multi-language Support

本应用支持中文和英文两种语言。

This app supports Chinese and English.

切换语言：设置 → 语言设置 → 选择语言 / Switch language: Settings > Language Settings > Choose language

如需添加其他语言，请参考 `lib/l10n/` 目录下的 arb 文件进行扩展。/ To add more languages, extend arb files in `lib/l10n/`.

## 🔧 构建与部署 / Build & Deploy

### 本地构建 / Local Build

```bash
flutter build apk --release
```

### 自动构建 / Auto Build

本项目包含 GitHub Actions 工作流，每次推送到 `main` 分支时会自动构建 APK。构建的 APK 会作为工件上传，您可以在 Actions 页面下载。

This project includes GitHub Actions workflow that automatically builds APK on push to `main`. APK artifacts are available in Actions page.

### APK 签名 / APK Signing

如需对 APK 进行签名，请在 GitHub 仓库中配置以下 Secrets / For APK signing, configure these Secrets:

- `ANDROID_KEYSTORE_BASE64`: Base64 编码的签名密钥文件 / Base64 encoded keystore file
- `ANDROID_KEYSTORE_PASSWORD`: 密钥库密码 / Keystore password
- `ANDROID_KEY_ALIAS`: 密钥别名 / Key alias
- `ANDROID_KEY_PASSWORD`: 密钥密码 / Key password

详细说明请查看 [SIGNING.md](SIGNING.md) 文件。/ See [SIGNING.md](SIGNING.md) for details.

## 📚 相关链接 / Related Links

- Baby Buddy 官方项目 / Official Project: https://github.com/babybuddy/babybuddy
- Flutter 官方网站 / Flutter Official: https://flutter.dev
- Material Design 3: https://m3.material.io

## 📄 许可证 / License

MIT License
