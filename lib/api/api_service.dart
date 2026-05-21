import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:html/parser.dart' as html_parser;

class ApiService {
  static late Dio dio;
  static String? _baseUrl;
  static Map<String, String> _cookies = {};
  static String? _csrfToken;

  static Future<void> init() async {
    _baseUrl = await Storage.getServerUrl();
    final baseUrl = _baseUrl ?? 'http://127.0.0.1:8000';
    
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // 添加cookie管理拦截器
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_cookies.isNotEmpty) {
          final cookieString = _cookies.entries
              .map((e) => '${e.key}=${e.value}')
              .join('; ');
          options.headers['Cookie'] = cookieString;
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // 提取 Set-Cookie 响应头
        final setCookieHeaders = response.headers['set-cookie'];
        if (setCookieHeaders != null) {
          for (final cookie in setCookieHeaders) {
            final parts = cookie.split(';');
            final cookiePair = parts.first.split('=');
            if (cookiePair.length >= 2) {
              _cookies[cookiePair[0].trim()] = cookiePair[1].trim();
            }
          }
        }
        return handler.next(response);
      },
    ));
    
    // 如果已有token，添加认证拦截器
    final token = await Storage.getToken();
    if (token != null) {
      dio.interceptors.add(AuthInterceptor(token));
    }
  }

  static Future<String?> login(String username, String password) async {
    try {
      // Step 1: 访问登录页面获取CSRF token和session
      final loginPageResponse = await dio.get(
        '/login/',
        options: Options(
          headers: {
            'Accept': 'text/html,application/xhtml+xml',
          },
          responseType: ResponseType.plain,
        ),
      );
      
      // 解析HTML获取csrfmiddlewaretoken
      final html = loginPageResponse.data;
      final document = html_parser.parse(html);
      final csrfElement = document.querySelector('input[name="csrfmiddlewaretoken"]');
      if (csrfElement == null) {
        throw Exception('无法找到CSRF token');
      }
      _csrfToken = csrfElement.attributes['value'];
      
      if (_csrfToken == null) {
        throw Exception('CSRF token为空');
      }
      
      // Step 2: 发送登录请求
      final formData = {
        'csrfmiddlewaretoken': _csrfToken,
        'username': username,
        'password': password,
        'next': '/',
      };
      
      final loginResponse = await dio.post(
        '/login/',
        data: FormData.fromMap(formData),
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Referer': '${_baseUrl ?? ''}/login/',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (loginResponse.statusCode == 403) {
        throw Exception('用户名或密码错误');
      }
      
      if (loginResponse.statusCode != 200 && 
          !(loginResponse.statusCode! >= 300 && loginResponse.statusCode! <= 307)) {
        throw Exception('登录失败 (状态码: ${loginResponse.statusCode})');
      }
      
      // Step 3: 访问profile API获取api_key
      final profileResponse = await dio.get(
        '/api/profile/',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      
      if (profileResponse.statusCode == 200 && profileResponse.data != null) {
        final profileData = profileResponse.data;
        if (profileData['api_key'] != null) {
          return profileData['api_key'] as String;
        }
      }
      
      throw Exception('无法获取API key');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('连接超时，请检查服务器地址是否正确');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('无法连接到服务器，请检查服务器地址和网络');
      } else if (e.response?.statusCode == 404) {
        throw Exception('服务器地址错误，请确认URL正确');
      } else if (e.response?.statusCode == 500) {
        throw Exception('服务器内部错误，请确认Baby Buddy版本正确');
      } else {
        throw Exception('登录失败: ${e.message}');
      }
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }

  static Future<List<dynamic>> getChildren() async {
    try {
      final response = await dio.get('/api/children/');
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取宝宝列表失败: $e');
    }
  }

  static Future<List<dynamic>> getTimeline() async {
    try {
      final responses = await Future.wait([
        dio.get('/api/sleep/'),
        dio.get('/api/feedings/'),
        dio.get('/api/changes/'),
      ]);

      final List<dynamic> timeline = [];
      
      for (final response in responses) {
        if (response.data != null && response.data['results'] != null) {
          timeline.addAll(response.data['results']);
        }
      }

      return timeline;
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
      await dio.post('/api/changes/', data: {
        'child': childId,
        'time': time,
        'wet': wet,
        'solid': solid,
        'color': 'unknown',
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
