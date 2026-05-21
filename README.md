# Baby Buddy 客户端

一个为 [Baby Buddy](https://github.com/babybuddy/babybuddy) 打造的 Flutter 移动应用客户端，帮助您轻松记录宝宝的日常活动！

## 功能特点

- 📱 **移动端友好界面**：简洁直观的 Flutter 界面
- 🔐 **用户认证**：通过 Token 安全连接到您的 Baby Buddy 服务器
- 👶 **宝宝管理**：支持选择和管理多个宝宝
- 📝 **快速记录**：一键记录喂奶、睡眠、尿布等日常活动
- 📊 **时间线查看**：查看宝宝活动的完整时间线
- 📦 **APK 打包**：内置 GitHub Actions 自动构建流程

## 项目结构

```
lib/
├── api/
│   └── api_service.dart      # API 服务层，处理所有与服务器的通信
├── screens/
│   ├── login_screen.dart     # 登录界面
│   ├── home_screen.dart      # 主界面，显示时间线
│   ├── child_select.dart     # 宝宝选择界面
│   └── quick_add.dart        # 快速记录界面
├── utils/
│   └── storage.dart          # 本地存储工具类（SharedPreferences）
└── main.dart                 # 应用入口
```

## 技术栈

- **框架**: Flutter
- **网络请求**: Dio
- **本地存储**: SharedPreferences
- **日期处理**: intl
- **提示信息**: fluttertoast

## 快速开始

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

## 使用说明

1. **登录**：在登录界面输入您的 Baby Buddy 服务器地址、用户名和密码
2. **选择宝宝**：在主界面点击右上角的人物图标，选择要记录的宝宝
3. **快速记录**：点击右下角的 "+" 按钮，快速记录喂奶、睡眠或尿布更换
4. **查看时间线**：主界面显示所有活动的时间线，下拉刷新

## 自动构建

本项目包含 GitHub Actions 工作流，每次推送到 `main` 分支时会自动构建 APK。构建的 APK 会作为工件上传，您可以在 Actions 页面下载。

## 相关链接

- Baby Buddy 官方项目: https://github.com/babybuddy/babybuddy

## 许可证

MIT License
