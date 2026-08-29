import 'package:flutter/material.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:babybuddy_app/screens/home_screen.dart';

/// 登录模式：账号密码 或 API Key（与 Baby Buddy 官方原版 Android App 一致）
enum _LoginMode { credentials, apiKey }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();

  _LoginMode _mode = _LoginMode.credentials;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureApiKey = true;

  // -------------------- lifecycle --------------------

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _urlCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final savedUrl = await Storage.getServerUrl();
    if (savedUrl != null && savedUrl.isNotEmpty && mounted) {
      setState(() => _urlCtrl.text = savedUrl);
    }
  }

  // -------------------- helpers --------------------

  String get _url => _urlCtrl.text.trim();

  /// 如果是 http:// （非 HTTPS），弹 Dialog 二次确认；用户同意后才继续
  Future<bool> _warnIfInsecureHttp() async {
    final u = _url;
    if (u.startsWith('http://') && !u.startsWith('https://')) {
      if (!mounted) return false;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          title: const Text('不安全连接（HTTP）'),
          content: const Text(
            '您正在使用 HTTP 协议连接 Baby Buddy 服务器。\n\n'
            '在公网环境下，账号密码和 API Key 不会被加密，极容易被窃取。'
            '此选项仅适用于本地家庭网络的私有部署。\n\n是否继续？',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('仍要继续'),
            ),
          ],
        ),
      );
      return ok == true;
    }
    return true;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 5),
      backgroundColor: Colors.red,
    ));
  }

  void _gotoHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // -------------------- actions --------------------

  Future<void> _doLogin() async {
    if (_loading) return;
    if (_url.isEmpty) {
      _showError('请输入服务器地址');
      return;
    }
    final proceed = await _warnIfInsecureHttp();
    if (!proceed) return;

    setState(() => _loading = true);
    try {
      await Storage.saveServerUrl(_url);
      await ApiService.init();

      if (_mode == _LoginMode.credentials) {
        if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
          _showError('请输入用户名和密码');
          return;
        }
        final token = await ApiService.login(_userCtrl.text.trim(), _passCtrl.text.trim());
        if (token == null) {
          _showError('登录失败：无法获取认证令牌');
          return;
        }
        _gotoHome();
      } else {
        // ---- API Key 模式 ----
        final key = _apiKeyCtrl.text.trim();
        if (key.isEmpty) {
          _showError('请输入 API Key');
          return;
        }
        ApiService.updateAuthToken(key);
        final ok = await ApiService.verifyToken();
        if (!ok) {
          _showError('API Key 无效，请重新检查');
          return;
        }
        await Storage.saveToken(key);
        _gotoHome();
      }
    } catch (e) {
      String msg = '登录失败';
      final s = e.toString();
      if (s.contains('Exception:')) {
        msg = s.replaceAll('Exception: ', '');
      } else if (s.contains('SocketException') || s.contains('connection')) {
        msg = '无法连接到服务器，请检查地址是否正确';
      } else if (s.isNotEmpty) {
        msg = s;
      }
      _showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -------------------- UI building --------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary, scheme.primaryContainer],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildModeSelector(),
                      const SizedBox(height: 20),
                      ..._mode == _LoginMode.credentials
                          ? _buildCredentialsForm()
                          : _buildApiKeyForm(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(scheme),
                      const SizedBox(height: 16),
                      _buildTips(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.child_care, size: 72, color: scheme.primary),
        ),
        const SizedBox(height: 18),
        const Text(
          'Baby Buddy',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '宝宝成长记录助手',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    final scheme = Theme.of(context).colorScheme;
    return SegmentedButton<_LoginMode>(
      segments: const [
        ButtonSegment<_LoginMode>(
          value: _LoginMode.credentials,
          icon: Icon(Icons.person_outline),
          label: Text('账号密码'),
        ),
        ButtonSegment<_LoginMode>(
          value: _LoginMode.apiKey,
          icon: Icon(Icons.key_outlined),
          label: Text('API Key'),
        ),
      ],
      selected: {_mode},
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      onSelectionChanged: (set) => setState(() => _mode = set.first),
    );
  }

  Widget _buildUrlField() {
    return TextField(
      controller: _urlCtrl,
      keyboardType: TextInputType.url,
      decoration: InputDecoration(
        labelText: '服务器地址',
        hintText: 'https://babybuddy.example.com',
        prefixIcon: const Icon(Icons.cloud_outlined),
        helperText: '例：https://baby.example.com 或 http://home-server.local:8000',
        helperMaxLines: 2,
      ),
    );
  }

  List<Widget> _buildCredentialsForm() => [
        _buildUrlField(),
        const SizedBox(height: 14),
        TextField(
          controller: _userCtrl,
          decoration: const InputDecoration(
            labelText: '用户名',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passCtrl,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: '密码',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ];

  List<Widget> _buildApiKeyForm() => [
        _buildUrlField(),
        const SizedBox(height: 14),
        TextField(
          controller: _apiKeyCtrl,
          obscureText: _obscureApiKey,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'API Key',
            hintText: '在 Baby Buddy 网页的 User Settings 中生成',
            prefixIcon: const Icon(Icons.key_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureApiKey ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
            ),
            helperText:
                '登录后，从 Baby Buddy 网页端 Settings → API Keys 中复制并粘贴到此处；与 Baby Buddy 官方原版 Android App 兼容。',
            helperMaxLines: 3,
          ),
        ),
      ];

  Widget _buildSubmitButton(ColorScheme scheme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _loading ? null : _doLogin,
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : const Text('登录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildTips() {
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.info_outline),
            title: const Text('连接示例'),
            content: const SingleChildScrollView(
              child: ListBody(
                children: [
                  Text('• 公共试用服务器：', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('  URL:  http://demo.baby-buddy.net/'),
                  Text('  用户: admin  /  密码: admin'),
                  SizedBox(height: 10),
                  Text('  ⚠️ Demo 服务器使用 HTTP，请勿存放私人数据。',
                      style: TextStyle(color: Colors.orange, fontSize: 12)),
                  SizedBox(height: 14),
                  Text('• 使用 API Key 登录：', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('  1. 在 Baby Buddy 网页端登录'),
                  Text('  2. 点击右上角头像 → Settings'),
                  Text('  3. 找到 API Keys 栏目，生成新的 Key'),
                  Text('  4. 粘贴到“API Key”标签页输入框即可'),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.help_outline, size: 18),
      label: const Text('不知道如何填写？查看连接示例'),
    );
  }
}
