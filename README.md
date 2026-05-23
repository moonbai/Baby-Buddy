# Baby Buddy 客户端

[English Version](README.en.md)

一个为 [Baby Buddy](https://github.com/babybuddy/babybuddy) 打造的 Flutter 移动应用客户端，帮助您轻松记录宝宝的日常活动！

## ✨ 功能特点

- 📱 **现代化移动端界面**：Material Design 3 设计，简洁直观
- 🌙 **主题设置**：支持浅色/深色/跟随系统三种主题模式
- 🎨 **深色模式完全支持**：所有页面都完美适配深色模式
- 🌐 **多语言支持**：支持中文和英文，可在设置中切换
- ⏱️ **活动计时器**：支持喂奶、睡眠、俯卧时间的实时计时，解决了计时器时间同步问题
- 🔐 **安全认证**：通过 Token 安全连接到您的 Baby Buddy 服务器
- 👶 **多宝宝管理**：支持选择和管理多个宝宝
- 📝 **快速记录**：一键记录喂奶、睡眠、尿布、吸奶等日常活动
- ⚡ **快速提报模式**：可在设置中开启，点击按钮直接弹出常用选项快速记录
- 📏 **身体测量**：记录体重、身高、头围和体温
- 📊 **时间线查看**：查看宝宝所有活动的完整时间线
- ✏️ **编辑和删除**：支持修改和删除已记录的活动
- 📦 **APK 自动打包**：内置 GitHub Actions 自动构建流程

## 📁 项目结构

```
lib/
├── api/
│   └── api_service.dart          # API 服务层，处理所有与服务器的通信
├── screens/
│   ├── login_screen.dart         # 登录界面
│   ├── home_screen.dart          # 主界面，显示时间线和计时器
│   ├── child_select.dart         # 宝宝选择界面
│   ├── quick_add.dart            # 快速记录界面
│   ├── settings_screen.dart      # 设置界面
│   └── about_screen.dart         # 关于界面
├── theme/
│   └── app_theme.dart            # 应用主题配置（Material Design 3）
├── utils/
│   ├── storage.dart              # 本地存储工具类
│   ├── date_time_utils.dart      # 日期时间处理工具
│   └── timer_manager.dart        # 计时器管理器
├── widgets/
│   ├── animated_widgets.dart     # 动画组件库
│   └── timer_card.dart           # 计时器卡片组件
├── generated/
│   ├── app_localizations.dart    # 国际化主文件
│   ├── app_localizations_zh.dart # 中文翻译
│   └── app_localizations_en.dart # 英文翻译
├── l10n/
│   ├── app_zh.arb                # 中文语言资源
│   └── app_en.arb                # 英文语言资源
└── main.dart                     # 应用入口
```

## 🛠️ 技术栈

- **框架**: Flutter 3.24.0+
- **设计**: Material Design 3
- **网络请求**: Dio
- **本地存储**: SharedPreferences
- **日期处理**: intl
- **提示信息**: fluttertoast
- **HTML 解析**: html
- **链接跳转**: url_launcher
- **国际化**: flutter_localizations

## 🚀 快速开始

### 前置条件

- 已安装 Flutter SDK (3.0+)
- 有运行中的 Baby Buddy 服务器

### 安装与运行

1. 克隆项目：
   ```bash
   git clone https://github.com/moonbai/Baby-Buddy.git
   cd Baby-Buddy
   ```

2. 安装依赖：
   ```bash
   flutter pub get
   ```

3. 运行应用：
   ```bash
   flutter run
   ```

## 📖 使用说明

1. **登录**：在登录界面输入您的 Baby Buddy 服务器地址、用户名和密码
2. **选择宝宝**：在主界面点击右上角菜单，选择要记录的宝宝
3. **启动计时器**：点击右下角 "+" 按钮，选择"启动定时器"
4. **快速记录**：点击右下角 "+" 按钮，快速记录各类活动
5. **查看时间线**：主界面显示所有活动的时间线，下拉刷新
6. **编辑记录**：展开卡片后可编辑或删除记录
7. **使用计时器**：点击活动的计时器卡片，选择对应的记录类型
8. **主题设置**：点击右上角菜单，选择"设置"，切换浅色/深色/跟随系统主题
9. **快速提报模式**：在设置中开启后，点击 "+" 按钮可快速选择常用选项
10. **语言切换**：在设置中选择简体中文或 English

## 🎨 主题与动画

### 主题系统
- 支持三种模式：浅色/深色/跟随系统
- 在设置中可自由切换
- 统一的配色方案和组件样式
- 所有页面完美适配深色模式

### 动画组件
- **AnimatedScroll**: 滚动时的淡入滑入动画
- **AnimatedScale**: 缩放动画效果
- **AnimatedFade**: 淡入淡出效果
- **BouncingButton**: 点击时的弹跳反馈
- **ShakeWidget**: 抖动效果（如错误提示）

## 🌐 多语言支持

本应用支持中文和英文两种语言。

切换语言：设置 → 语言设置 → 选择语言

如需添加其他语言，请参考 `lib/l10n/` 目录下的 arb 文件进行扩展。

## 🔧 构建与部署

### 本地构建

```bash
flutter build apk --release
```

### 自动构建

本项目包含 GitHub Actions 工作流，每次推送到 `main` 分支时会自动构建 APK。构建的 APK 会作为工件上传，您可以在 Actions 页面下载。

### APK 签名

如需对 APK 进行签名，请在 GitHub 仓库中配置以下 Secrets：

- `ANDROID_KEYSTORE_BASE64`: Base64 编码的签名密钥文件
- `ANDROID_KEYSTORE_PASSWORD`: 密钥库密码
- `ANDROID_KEY_ALIAS`: 密钥别名
- `ANDROID_KEY_PASSWORD`: 密钥密码

详细说明请查看 [SIGNING.md](SIGNING.md) 文件。

## 📚 相关链接

- Baby Buddy 官方项目: https://github.com/babybuddy/babybuddy
- Flutter 官方网站: https://flutter.dev
- Material Design 3: https://m3.material.io

## 📄 许可证

MIT License
