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

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
