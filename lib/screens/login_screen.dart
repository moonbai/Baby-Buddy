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
  final urlCtrl = TextEditingController(text: 'http://127.0.0.1:8000');
  bool loading = false;

  Future<void> doLogin() async {
    setState(() => loading = true);
    await Storage.saveServerUrl(urlCtrl.text.trim());
    await ApiService.init();
    final token = await ApiService.login(userCtrl.text, passCtrl.text);
    setState(() => loading = false);
    if (token != null) {
      await Storage.saveToken(token);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登录失败')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Baby Buddy 登录')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: '服务器地址')),
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: '用户名')),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: '密码')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: loading ? null : doLogin, child: loading ? const CircularProgressIndicator() : const Text('登录')),
          ],
        ),
      ),
    );
  }
}
