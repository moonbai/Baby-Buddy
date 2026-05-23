import 'package:flutter/material.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/screens/login_screen.dart';
import 'package:babybuddy_app/screens/home_screen.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:babybuddy_app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Buddy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (c) => FutureBuilder<String?>(
          future: Storage.getToken(),
          builder: (ctx, snap) => snap.hasData && snap.data != null ? const HomeScreen() : const LoginScreen(),
        ),
        '/login': (c) => const LoginScreen(),
      },
    );
  }
}
