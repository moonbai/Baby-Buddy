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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await Storage.getThemeMode();
    setState(() {
      _themeMode = _getThemeModeFromString(mode!);
    });
  }

  ThemeMode _getThemeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void updateThemeMode(String mode) {
    setState(() {
      _themeMode = _getThemeModeFromString(mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Buddy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
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
