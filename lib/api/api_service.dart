import 'package:dio/dio.dart';
import 'package:babybuddy_app/utils/storage.dart';

class ApiService {
  static late Dio dio;
  static String? _baseUrl;

  static Future<void> init() async {
    _baseUrl = await Storage.getServerUrl();
    final baseUrl = _baseUrl ?? 'http://127.0.0.1:8000';
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    final token = await Storage.getToken();
    if (token != null) {
      dio.interceptors.add(AuthInterceptor(token));
    }
  }

  static Future<String?> login(String user, String pass) async {
    try {
      final res = await dio.post('/api/auth/token/', data: {
        'username': user,
        'password': pass,
      });
      if (res.data != null && res.data['token'] != null) {
        return res.data['token'];
      }
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('连接超时，请检查服务器地址是否正确');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('无法连接到服务器，请检查服务器地址和网络');
      } else if (e.response?.statusCode == 401) {
        throw Exception('用户名或密码错误');
      } else if (e.response?.statusCode == 404) {
        throw Exception('服务器地址错误，找不到登录接口');
      } else {
        throw Exception('登录失败: ${e.message}');
      }
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }

  static Future<List> getChildren() async {
    try {
      final res = await dio.get('/api/children/');
      return res.data;
    } catch (e) {
      throw Exception('获取宝宝列表失败: $e');
    }
  }

  static Future<List> getTimeline() async {
    try {
      final res = await dio.get('/api/timeline/');
      return res.data;
    } catch (e) {
      throw Exception('获取时间线失败: $e');
    }
  }

  static Future<void> addFeeding(int childId, String start, String end, String type, String method) async {
    try {
      await dio.post('/api/feedings/', data: {
        'child': childId,
        'start': start,
        'end': end,
        'type': type,
        'method': method,
      });
    } catch (e) {
      throw Exception('添加喂奶记录失败: $e');
    }
  }

  static Future<void> addSleep(int childId, String start, String end) async {
    try {
      await dio.post('/api/sleep/', data: {
        'child': childId,
        'start': start,
        'end': end,
      });
    } catch (e) {
      throw Exception('添加睡眠记录失败: $e');
    }
  }

  static Future<void> addDiaper(int childId, String time, bool wet, bool solid) async {
    try {
      await dio.post('/api/diapers/', data: {
        'child': childId,
        'time': time,
        'wet': wet,
        'solid': solid,
      });
    } catch (e) {
      throw Exception('添加尿布记录失败: $e');
    }
  }
}

class AuthInterceptor extends Interceptor {
  final String token;
  AuthInterceptor(this.token);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Token $token';
    super.onRequest(options, handler);
  }
}
