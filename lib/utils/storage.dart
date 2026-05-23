import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverUrl', url);
  }

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('serverUrl');
  }

  static Future<void> saveChildId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('childId', id);
  }

  static Future<int?> getChildId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('childId');
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode);
  }

  static Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('themeMode') ?? 'system';
  }

  static Future<void> saveQuickReport(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quickReport', enabled);
  }

  static Future<bool?> getQuickReport() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('quickReport') ?? false;
  }

  static Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }

  static Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('language') ?? 'zh';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('childId');
  }
}
