import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储工具类
///
/// 优化点：
/// 1. 缓存 SharedPreferences 实例，避免每次 get/set 重复异步获取
/// 2. 所有 getter 返回非空值（用默认值兜底），消除调用端的 ! 强制解包
class Storage {
  static SharedPreferences? _prefs;

  /// 获取 SharedPreferences 实例（带缓存）
  static Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  // ============== Token ==============

  static Future<void> saveToken(String token) async {
    final prefs = await _getPrefs();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await _getPrefs();
    return prefs.getString('token');
  }

  // ============== Server Url ==============

  static Future<void> saveServerUrl(String url) async {
    final prefs = await _getPrefs();
    await prefs.setString('serverUrl', url);
  }

  static Future<String?> getServerUrl() async {
    final prefs = await _getPrefs();
    return prefs.getString('serverUrl');
  }

  // ============== Child Id ==============

  static Future<void> saveChildId(int id) async {
    final prefs = await _getPrefs();
    await prefs.setInt('childId', id);
  }

  static Future<int?> getChildId() async {
    final prefs = await _getPrefs();
    return prefs.getInt('childId');
  }

  // ============== Theme Mode ==============

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await _getPrefs();
    await prefs.setString('themeMode', mode);
  }

  /// 返回主题模式字符串，保证非空
  static Future<String> getThemeMode() async {
    final prefs = await _getPrefs();
    return prefs.getString('themeMode') ?? 'system';
  }

  // ============== Quick Report ==============

  static Future<void> saveQuickReport(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool('quickReport', enabled);
  }

  /// 返回快速报告开关状态，保证非空
  static Future<bool> getQuickReport() async {
    final prefs = await _getPrefs();
    return prefs.getBool('quickReport') ?? false;
  }

  // ============== Language ==============

  static Future<void> saveLanguage(String language) async {
    final prefs = await _getPrefs();
    await prefs.setString('language', language);
  }

  /// 返回语言代码，保证非空
  static Future<String> getLanguage() async {
    final prefs = await _getPrefs();
    return prefs.getString('language') ?? 'zh';
  }

  // ============== Logout ==============

  static Future<void> logout() async {
    final prefs = await _getPrefs();
    await prefs.remove('token');
    await prefs.remove('childId');
  }

  /// 清空全部缓存（用于调试或彻底重置）
  static Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
    _prefs = null;
  }
}
