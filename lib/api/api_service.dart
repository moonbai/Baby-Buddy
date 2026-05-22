import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:html/parser.dart' as html_parser;

class ApiService {
  static late Dio dio;
  static String? _baseUrl;
  static Map<String, String> _cookies = {};
  static String? _csrfToken;
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    
    _baseUrl = await Storage.getServerUrl();
    final baseUrl = _baseUrl ?? 'http://127.0.0.1:8000';
    
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/html',
      },
    ));
    
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
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} - ${error.message}');
        if (error.response?.data != null) {
          print('Response data: ${error.response?.data}');
        }
        return handler.next(error);
      },
    ));
    
    final token = await Storage.getToken();
    if (token != null && token.isNotEmpty) {
      _addAuthInterceptor(token);
    }
    
    _isInitialized = true;
  }

  static void _addAuthInterceptor(String token) {
    for (var interceptor in dio.interceptors) {
      if (interceptor is AuthInterceptor) {
        return;
      }
    }
    dio.interceptors.add(AuthInterceptor(token));
  }

  static Future<void> resetInterceptor() async {
    final token = await Storage.getToken();
    if (token != null && token.isNotEmpty) {
      _addAuthInterceptor(token);
    }
  }

  static Future<String?> login(String username, String password) async {
    try {
      print('=== 开始登录流程 ===');
      
      if (!_isInitialized) {
        await init();
      }
      
      print('Step 1: 访问 /login/ 获取CSRF token');
      final loginPageResponse = await dio.get(
        '/login/',
        options: Options(
          headers: {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          },
          responseType: ResponseType.plain,
        ),
      );
      
      print('登录页面状态码: ${loginPageResponse.statusCode}');
      
      final html = loginPageResponse.data.toString();
      final document = html_parser.parse(html);
      final csrfElement = document.querySelector('input[name="csrfmiddlewaretoken"]');
      
      if (csrfElement == null) {
        throw Exception('无法找到CSRF token，请确认登录页面URL正确');
      }
      
      _csrfToken = csrfElement.attributes['value'];
      
      if (_csrfToken == null || _csrfToken!.isEmpty) {
        throw Exception('CSRF token为空');
      }
      
      print('CSRF token获取成功');
      
      print('Step 2: 发送登录请求到 /login/');
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
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );
      
      print('登录请求状态码: ${loginResponse.statusCode}');
      
      if (loginResponse.statusCode == 403) {
        throw Exception('用户名或密码错误');
      }
      
      if (loginResponse.statusCode == 500) {
        throw Exception('服务器内部错误 (500)');
      }
      
      if (loginResponse.statusCode != 200 && 
          !(loginResponse.statusCode! >= 300 && loginResponse.statusCode! <= 307)) {
        throw Exception('登录失败 (状态码: ${loginResponse.statusCode})');
      }
      
      print('登录请求成功');
      
      print('Step 3: 获取API key');
      
      final profileResponse = await dio.get(
        '/api/profile',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      
      print('Profile API状态码: ${profileResponse.statusCode}');
      print('Profile数据: ${profileResponse.data}');
      
      if (profileResponse.statusCode == 200 && profileResponse.data != null) {
        final profileData = profileResponse.data;
        if (profileData['api_key'] != null) {
          print('成功获取到API key');
          final token = profileData['api_key'] as String;
          _addAuthInterceptor(token);
          return token;
        }
      }
      
      throw Exception('无法获取API key');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('连接超时，请检查服务器地址是否正确');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('无法连接到服务器，请检查服务器地址和网络');
      } else if (e.response?.statusCode == 404) {
        throw Exception('服务器地址错误，找不到API端点');
      } else if (e.response?.statusCode == 500) {
        throw Exception('服务器内部错误 (500)');
      } else {
        print('DioException: $e');
        print('Response: ${e.response?.data}');
        throw Exception('登录失败: ${e.message}');
      }
    } catch (e) {
      print('Exception: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getChildren({int? limit, int? offset}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      
      final response = await dio.get('/api/children/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取宝宝列表失败: $e');
    }
  }

  static Future<Map<String, dynamic>> getChildById(int id) async {
    try {
      final response = await dio.get('/api/children/$id/');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('获取宝宝信息失败: $e');
    }
  }

  static Future<List<dynamic>> getChanges({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/changes/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取尿布记录失败: $e');
    }
  }

  static Future<void> addDiaper(int childId, String time, bool wet, bool solid, String color, {String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'time': time,
        'wet': wet,
        'solid': solid,
        'color': color,
      };
      if (notes != null) data['notes'] = notes;
      
      print('添加尿布记录: $data');
      await dio.post('/api/changes/', data: data);
    } catch (e) {
      print('添加尿布记录失败: $e');
      throw Exception('添加尿布记录失败: $e');
    }
  }

  static Future<void> updateDiaper(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/changes/$id/', data: data);
    } catch (e) {
      throw Exception('更新尿布记录失败: $e');
    }
  }

  static Future<void> deleteDiaper(int id) async {
    try {
      await dio.delete('/api/changes/$id/');
    } catch (e) {
      throw Exception('删除尿布记录失败: $e');
    }
  }

  static Future<List<dynamic>> getFeedings({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/feedings/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取喂奶记录失败: $e');
    }
  }

  static Future<void> addFeeding(int childId, String start, String end, String type, String method, {String? notes, int? timer, double? amount, String? amountUnit}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'start': start,
        'end': end,
        'type': type,
        'method': method,
      };
      if (notes != null) data['notes'] = notes;
      if (timer != null) data['timer'] = timer;
      if (amount != null) data['amount'] = amount;
      if (amountUnit != null) data['amount_unit'] = amountUnit;
      
      print('添加喂奶记录: $data');
      await dio.post('/api/feedings/', data: data);
    } catch (e) {
      print('添加喂奶记录失败: $e');
      throw Exception('添加喂奶记录失败: $e');
    }
  }

  static Future<void> updateFeeding(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/feedings/$id/', data: data);
    } catch (e) {
      throw Exception('更新喂奶记录失败: $e');
    }
  }

  static Future<void> deleteFeeding(int id) async {
    try {
      await dio.delete('/api/feedings/$id/');
    } catch (e) {
      throw Exception('删除喂奶记录失败: $e');
    }
  }

  static Future<List<dynamic>> getSleep({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/sleep/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取睡眠记录失败: $e');
    }
  }

  static Future<void> addSleep(int childId, String start, String end, {String? notes, bool? nap, int? timer}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'start': start,
        'end': end,
      };
      if (notes != null) data['notes'] = notes;
      if (nap != null) data['nap'] = nap;
      if (timer != null) data['timer'] = timer;
      
      print('添加睡眠记录: $data');
      await dio.post('/api/sleep/', data: data);
    } catch (e) {
      print('添加睡眠记录失败: $e');
      throw Exception('添加睡眠记录失败: $e');
    }
  }

  static Future<void> updateSleep(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/sleep/$id/', data: data);
    } catch (e) {
      throw Exception('更新睡眠记录失败: $e');
    }
  }

  static Future<void> deleteSleep(int id) async {
    try {
      await dio.delete('/api/sleep/$id/');
    } catch (e) {
      throw Exception('删除睡眠记录失败: $e');
    }
  }

  static Future<List<dynamic>> getTummyTimes({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/tummy-times/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取俯卧时间记录失败: $e');
    }
  }

  static Future<void> addTummyTime(int childId, String start, String end, {String? milestone, String? notes, int? timer}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'start': start,
        'end': end,
      };
      if (milestone != null) data['milestone'] = milestone;
      if (notes != null) data['notes'] = notes;
      if (timer != null) data['timer'] = timer;
      
      print('添加俯卧时间记录: $data');
      await dio.post('/api/tummy-times/', data: data);
    } catch (e) {
      print('添加俯卧时间记录失败: $e');
      throw Exception('添加俯卧时间记录失败: $e');
    }
  }

  static Future<List<dynamic>> getPumping({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/pumping/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取吸奶记录失败: $e');
    }
  }

  static Future<void> addPumping(int childId, String start, String end, {double? amount, String? amountUnit, String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'start': start,
        'end': end,
      };
      if (amount != null) data['amount'] = amount;
      if (amountUnit != null) data['amount_unit'] = amountUnit;
      if (notes != null) data['notes'] = notes;
      
      print('添加吸奶记录: $data');
      await dio.post('/api/pumping/', data: data);
    } catch (e) {
      print('添加吸奶记录失败: $e');
      throw Exception('添加吸奶记录失败: $e');
    }
  }

  static Future<List<dynamic>> getNotes({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/notes/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取笔记失败: $e');
    }
  }

  static Future<void> addNote(int childId, String note, {String? time}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'note': note,
      };
      if (time != null) data['time'] = time;
      
      print('添加笔记: $data');
      await dio.post('/api/notes/', data: data);
    } catch (e) {
      print('添加笔记失败: $e');
      throw Exception('添加笔记失败: $e');
    }
  }

  static Future<void> updateNote(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/notes/$id/', data: data);
    } catch (e) {
      throw Exception('更新笔记失败: $e');
    }
  }

  static Future<void> deleteNote(int id) async {
    try {
      await dio.delete('/api/notes/$id/');
    } catch (e) {
      throw Exception('删除笔记失败: $e');
    }
  }

  static Future<List<dynamic>> getWeight({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/weight/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取体重记录失败: $e');
    }
  }

  static Future<void> addWeight(int childId, String date, double weight, {String? weightUnit, String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'date': date,
        'weight': weight,
      };
      if (weightUnit != null) data['weight_unit'] = weightUnit;
      if (notes != null) data['notes'] = notes;
      
      print('添加体重记录: $data');
      await dio.post('/api/weight/', data: data);
    } catch (e) {
      print('添加体重记录失败: $e');
      throw Exception('添加体重记录失败: $e');
    }
  }

  static Future<List<dynamic>> getHeight({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/height/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取身高记录失败: $e');
    }
  }

  static Future<void> addHeight(int childId, String date, double height, {String? heightUnit, String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'date': date,
        'height': height,
      };
      if (heightUnit != null) data['height_unit'] = heightUnit;
      if (notes != null) data['notes'] = notes;
      
      print('添加身高记录: $data');
      await dio.post('/api/height/', data: data);
    } catch (e) {
      print('添加身高记录失败: $e');
      throw Exception('添加身高记录失败: $e');
    }
  }

  static Future<List<dynamic>> getHeadCircumference({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/head-circumference/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取头围记录失败: $e');
    }
  }

  static Future<void> addHeadCircumference(int childId, String date, double circumference, {String? circumferenceUnit, String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'date': date,
        'circumference': circumference,
      };
      if (circumferenceUnit != null) data['circumference_unit'] = circumferenceUnit;
      if (notes != null) data['notes'] = notes;
      
      print('添加头围记录: $data');
      await dio.post('/api/head-circumference/', data: data);
    } catch (e) {
      print('添加头围记录失败: $e');
      throw Exception('添加头围记录失败: $e');
    }
  }

  static Future<List<dynamic>> getBMI({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/bmi/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取BMI记录失败: $e');
    }
  }

  static Future<void> addBMI(int childId, String date, double bmi, {String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'date': date,
        'bmi': bmi,
      };
      if (notes != null) data['notes'] = notes;
      
      print('添加BMI记录: $data');
      await dio.post('/api/bmi/', data: data);
    } catch (e) {
      print('添加BMI记录失败: $e');
      throw Exception('添加BMI记录失败: $e');
    }
  }

  static Future<List<dynamic>> getTemperature({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/temperature/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取体温记录失败: $e');
    }
  }

  static Future<void> addTemperature(int childId, String time, double temperature, {String? temperatureUnit, String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'time': time,
        'temperature': temperature,
      };
      if (temperatureUnit != null) data['temperature_unit'] = temperatureUnit;
      if (notes != null) data['notes'] = notes;
      
      print('添加体温记录: $data');
      await dio.post('/api/temperature/', data: data);
    } catch (e) {
      print('添加体温记录失败: $e');
      throw Exception('添加体温记录失败: $e');
    }
  }

  static Future<List<dynamic>> getTimers({int? limit, int? offset, int? childId}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (offset != null) query['offset'] = offset;
      if (childId != null) query['child'] = childId;
      
      final response = await dio.get('/api/timers/', queryParameters: query);
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取计时器列表失败: $e');
    }
  }

  static Future<Map<String, dynamic>> addTimer(int childId, {String? name}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
      };
      if (name != null) data['name'] = name;
      
      print('添加计时器: $data');
      final response = await dio.post('/api/timers/', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('添加计时器失败: $e');
      throw Exception('添加计时器失败: $e');
    }
  }

  static Future<void> stopTimer(int id) async {
    try {
      await dio.delete('/api/timers/$id/');
    } catch (e) {
      throw Exception('停止计时器失败: $e');
    }
  }

  static Future<List<dynamic>> getTags() async {
    try {
      final response = await dio.get('/api/tags/');
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('获取标签失败: $e');
    }
  }

  static Future<List<dynamic>> getTimeline({int? childId, int? limit}) async {
    try {
      final responses = await Future.wait([
        getSleep(limit: limit, childId: childId),
        getFeedings(limit: limit, childId: childId),
        getChanges(limit: limit, childId: childId),
        getTummyTimes(limit: limit, childId: childId),
        getPumping(limit: limit, childId: childId),
        getNotes(limit: limit, childId: childId),
      ]);

      final List<dynamic> timeline = [];
      
      for (final response in responses) {
        timeline.addAll(response);
      }

      timeline.sort((a, b) {
        String getTime(dynamic item) {
          if (item['time'] != null) return item['time'];
          if (item['start'] != null) return item['start'];
          if (item['date'] != null) return item['date'];
          return '';
        }
        return getTime(b).compareTo(getTime(a));
      });

      return timeline;
    } catch (e) {
      throw Exception('获取时间线失败: $e');
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
