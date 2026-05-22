import 'package:flutter/material.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:babybuddy_app/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final urlCtrl = TextEditingController();
  bool loading = false;
  String? _savedUrl;

  @override
  void initState() {
    super.initState();
    _loadSavedUrl();
  }

  Future<void> _loadSavedUrl() async {
    final savedUrl = await Storage.getServerUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      setState(() {
        urlCtrl.text = savedUrl;
        _savedUrl = savedUrl;
      });
    }
  }

  String _formatUrl(String url) {
    url = url.trim();
    if (url.isEmpty) return url;
    
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    return url;
  }

  Future<void> doLogin() async {
    if (userCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入用户名和密码'))
      );
      return;
    }

    String serverUrl = urlCtrl.text.trim();
    if (serverUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入服务器地址'))
      );
      return;
    }

    setState(() => loading = true);
    
    try {
      serverUrl = _formatUrl(serverUrl);
      print('正在连接服务器: $serverUrl');
      
      await Storage.saveServerUrl(serverUrl);
      await ApiService.init();
      
      final token = await ApiService.login(userCtrl.text, passCtrl.text);
      if (token != null) {
        await Storage.saveToken(token);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录失败：无法获取认证令牌'))
          );
        }
      }
    } catch (e) {
      String errorMessage = '登录失败';
      print('登录错误: $e');
      
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('SocketException')) {
        errorMessage = '无法连接到服务器，请检查地址是否正确\n服务器地址应为形如：http://192.168.1.100:8000';
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage = 'SSL证书错误，请确认服务器使用HTTPS或联系服务器管理员';
      } else if (e.toString().contains('connection')) {
        errorMessage = '连接失败，请检查服务器地址和网络';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '查看帮助',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('连接帮助'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('服务器地址格式示例：'),
                          SizedBox(height: 8),
                          Text('• 本地网络：http://192.168.1.100:8000'),
                          Text('• 公网地址：https://your-domain.com'),
                          Text('• 本地模拟器：http://10.0.2.2:8000'),
                          SizedBox(height: 16),
                          Text('常见问题：'),
                          Text('1. 确认服务器已启动'),
                          Text('2. 确认手机与服务器在同一网络'),
                          Text('3. 如果是内网，确认端口已开放'),
                          Text('4. 如果是HTTPS，确保证书有效'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('知道了'),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Baby Buddy 登录')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.child_care, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(
              controller: urlCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: '服务器地址',
                hintText: 'http://192.168.1.100:8000',
                prefixIcon: const Icon(Icons.cloud),
                border: const OutlineInputBorder(),
                helperText: '输入 Baby Buddy 服务器地址',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: userCtrl,
              decoration: const InputDecoration(
                labelText: '用户名',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : doLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: loading 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('登录', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            const Text(
              '💡 提示：服务器地址应包含协议（http:// 或 https://）',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
