import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/screens/login_screen.dart';
import 'package:babybuddy_app/screens/home_screen.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:babybuddy_app/theme/app_theme.dart';
import 'package:babybuddy_app/generated/app_localizations.dart';

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
  Locale _locale = const Locale('zh');

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    // 注册 Api 层 401 回调：token 失效后自动返回登录页
    ApiService.setOnUnauthorized(_handleUnauthorized);
  }

  /// 并行加载 themeMode 和 language，替代两个串行 await
  Future<void> _loadPreferences() async {
    final results = await Future.wait([
      Storage.getThemeMode(),
      Storage.getLanguage(),
    ]);
    if (!mounted) return;
    setState(() {
      _themeMode = _getThemeModeFromString(results[0] as String);
      _locale = Locale(results[1] as String);
    });
  }

  /// 统一的 401/403 处理：跳回登录页
  Future<void> _handleUnauthorized() async {
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;
    if (!Navigator.of(ctx).canPop()) return;
    // 用登录页替换整个路由栈
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
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

  /// 切换主题模式，并持久化
  Future<void> updateThemeMode(String mode) async {
    setState(() {
      _themeMode = _getThemeModeFromString(mode);
    });
    await Storage.saveThemeMode(mode);
  }

  /// 切换语言，并持久化
  void updateLanguage(String language) {
    setState(() {
      _locale = Locale(language);
    });
    Storage.saveLanguage(language);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'Baby Buddy',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      locale: _locale,
      supportedLocales: const [
        Locale('zh'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 根路由：有 token 就进主页，无 token 就进登录页
      home: FutureBuilder<String?>(
        future: Storage.getToken(),
        builder: (ctx, snap) =>
            snap.hasData && snap.data != null
                ? const HomeScreen()
                : const LoginScreen(),
      ),
      routes: {
        '/login': (c) => const LoginScreen(),
        '/home': (c) => const HomeScreen(),
      },
    );
  }
}
