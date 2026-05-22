# APK签名配置说明

本项目已配置好签名支持，你需要按以下步骤准备并配置签名信息。

## 你需要准备的文件和信息

### 1. 创建或获取签名文件
你需要一个Android签名密钥库文件，通常是 `.keystore` 或 `.jks` 文件。

#### 如果还没有签名文件，使用以下命令创建：
```bash
keytool -genkey -v -keystore release.keystore -alias babybuddy -keyalg RSA -keysize 2048 -validity 10000
```

这将创建一个名为 `release.keystore` 的文件，你需要设置：
- 密钥库密码 (Store Password)
- 别名 (Alias) - 这里用 `babybuddy`
- 密钥密码 (Key Password) - 建议与密钥库密码一致

### 2. 准备需要配置的信息

你需要准备以下4个信息：

| 信息项 | 说明 | 示例 |
|--------|------|------|
| 1. `release.keystore` | 你的签名文件 | 本地创建的文件 |
| 2. `ANDROID_KEYSTORE_PASSWORD` | 密钥库密码 | 你设置的密码 |
| 3. `ANDROID_KEY_ALIAS` | 密钥别名 | `babybuddy` |
| 4. `ANDROID_KEY_PASSWORD` | 密钥密码 | 你设置的密码 |

## 配置步骤

### 第一步：Base64编码签名文件

在你的本地电脑上，运行以下命令将签名文件转换为Base64字符串：

**Linux/macOS:**
```bash
base64 -w 0 release.keystore > release.keystore.b64
```

**Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("release.keystore")) > release.keystore.b64
```

然后用文本编辑器打开 `release.keystore.b64`，复制全部内容。

### 第二步：在GitHub上设置密钥

1. 进入你的项目仓库
2. 点击 Settings (设置)
3. 在左侧菜单找到 Secrets and variables → Actions
4. 点击 New repository secret，依次添加以下4个密钥：

| 密钥名称 | 值 |
|----------|---|
| `ANDROID_KEYSTORE_BASE64` | 刚才复制的Base64字符串 |
| `ANDROID_KEYSTORE_PASSWORD` | 你的密钥库密码 |
| `ANDROID_KEY_ALIAS` | 你的密钥别名（如 `babybuddy`） |
| `ANDROID_KEY_PASSWORD` | 你的密钥密码 |

### 第三步：提交和推送

代码已配置好签名支持，直接推送即可：
```bash
git add -A
git commit -m "chore: 添加APK签名支持"
git push
```

## 本地调试签名（可选）

如果你想在本地调试签名，可以在 `android/` 目录下创建 `key.properties` 文件：

```properties
storeFile=../release.keystore
storePassword=你的密钥库密码
keyAlias=babybuddy
keyPassword=你的密钥密码
```

将 `release.keystore` 放在项目根目录，然后运行 `flutter build apk --release` 即可。

**注意：** 请不要将 `release.keystore` 和 `key.properties` 提交到Git仓库！请确保它们已添加到 `.gitignore`。

## 当前状态

- ✅ [build.gradle](android/app/build.gradle) - 已配置签名逻辑
- ✅ [build-apk.yml](.github/workflows/build-apk.yml) - 已配置CI签名环境
- ⏳ 等待你配置 GitHub Secrets 并推送代码
