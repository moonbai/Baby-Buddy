import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:html/parser.dart' as html_parser;

class ApiService {
  static late Dio dio;
  static String? _baseUrl;
  static Map<String, String> _cookies = {};
  static String? _csrfToken;
  static String? _authToken;

  static Future<void> init() async {
    _baseUrl = await Storage.getServerUrl();
    final baseUrl = _baseUrl ?? 'http://127.0.0.1:8000';

    // 先清空所有拦截器，创建全新的Dio实例
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 添加Cookie拦截器
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
    ));

    // 添加认证拦截器
    final token = await Storage.getToken();
    if (token != null) {
      _authToken = token;
      dio.interceptors.add(AuthInterceptor(token));
    }
  }

  static Future<String?> login(String username, String password) async {
    try {
      final loginPageResponse = await dio.get(
        '/login/',
        options: Options(
          headers: {
            'Accept': 'text/html,application/xhtml+xml',
          },
          responseType: ResponseType.plain,
        ),
      );

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

      final profileResponse = await dio.get(
        '/api/profile',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (profileResponse.statusCode == 200 && profileResponse.data != null) {
        final profileData = profileResponse.data;
        if (profileData['api_key'] != null) {
          final token = profileData['api_key'] as String;
          await Storage.saveToken(token);
          _authToken = token;

          // 重新初始化，确保AuthInterceptor正确添加
          await init();
          
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
    } on DioException catch (e) {
      throw _handleApiError(e, '获取宝宝列表');
    }
  }

  static Future<Map<String, dynamic>> getChildById(int id) async {
    try {
      final response = await dio.get('/api/children/$id/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleApiError(e, '获取宝宝信息');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'change';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取尿布记录');
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

      await dio.post('/api/changes/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加尿布记录');
    }
  }

  static Future<void> updateDiaper(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/changes/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新尿布记录');
    }
  }

  static Future<void> deleteDiaper(int id) async {
    try {
      await dio.delete('/api/changes/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除尿布记录');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'feeding';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取喂奶记录');
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

      await dio.post('/api/feedings/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加喂奶记录');
    }
  }

  static Future<void> updateFeeding(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/feedings/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新喂奶记录');
    }
  }

  static Future<void> deleteFeeding(int id) async {
    try {
      await dio.delete('/api/feedings/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除喂奶记录');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'sleep';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取睡眠记录');
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

      await dio.post('/api/sleep/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加睡眠记录');
    }
  }

  static Future<void> updateSleep(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/sleep/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新睡眠记录');
    }
  }

  static Future<void> deleteSleep(int id) async {
    try {
      await dio.delete('/api/sleep/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除睡眠记录');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'tummy time';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取俯卧时间记录');
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

      await dio.post('/api/tummy-times/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加俯卧时间记录');
    }
  }

  static Future<void> updateTummyTime(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/tummy-times/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新俯卧时间记录');
    }
  }

  static Future<void> deleteTummyTime(int id) async {
    try {
      await dio.delete('/api/tummy-times/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除俯卧时间记录');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'pumping';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取吸奶记录');
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

      await dio.post('/api/pumping/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加吸奶记录');
    }
  }

  static Future<void> updatePumping(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/pumping/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新吸奶记录');
    }
  }

  static Future<void> deletePumping(int id) async {
    try {
      await dio.delete('/api/pumping/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除吸奶记录');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'note';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取笔记');
    }
  }

  static Future<void> addNote(int childId, String note, {String? time}) async {
    try {
      final data = <String, dynamic>{
        'child': childId,
        'note': note,
      };
      if (time != null) data['time'] = time;

      await dio.post('/api/notes/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加笔记');
    }
  }

  static Future<void> updateNote(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/notes/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新笔记');
    }
  }

  static Future<void> deleteNote(int id) async {
    try {
      await dio.delete('/api/notes/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除笔记');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'weight';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取体重记录');
    }
  }

  static Future<void> addWeight(int childId, String date, double weight, {String? weightUnit, String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId, 'date': date, 'weight': weight,
      };
      if (weightUnit != null) data['weight_unit'] = weightUnit;
      if (notes != null) data['notes'] = notes;

      await dio.post('/api/weight/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加体重记录');
    }
  }

  static Future<void> updateWeight(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/weight/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新体重记录');
    }
  }

  static Future<void> deleteWeight(int id) async {
    try {
      await dio.delete('/api/weight/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除体重记录');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'height';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取身高记录');
    }
  }

  static Future<void> addHeight(int childId, String date, double height, {String? heightUnit, String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId, 'date': date, 'height': height,
      };
      if (heightUnit != null) data['height_unit'] = heightUnit;
      if (notes != null) data['notes'] = notes;

      await dio.post('/api/height/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加身高记录');
    }
  }

  static Future<void> updateHeight(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/height/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新身高记录');
    }
  }

  static Future<void> deleteHeight(int id) async {
    try {
      await dio.delete('/api/height/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除身高记录');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'head circumference';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取头围记录');
    }
  }

  static Future<void> addHeadCircumference(int childId, String date, double circumference, {String? circumferenceUnit, String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId, 'date': date, 'circumference': circumference,
      };
      if (circumferenceUnit != null) data['circumference_unit'] = circumferenceUnit;
      if (notes != null) data['notes'] = notes;

      await dio.post('/api/head-circumference/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加头围记录');
    }
  }

  static Future<void> updateHeadCircumference(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/head-circumference/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新头围记录');
    }
  }

  static Future<void> deleteHeadCircumference(int id) async {
    try {
      await dio.delete('/api/head-circumference/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除头围记录');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'bmi';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取BMI记录');
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

      await dio.post('/api/bmi/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加BMI记录');
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
        final results = response.data['results'] as List;
        return results.map((item) {
          final map = Map<String, dynamic>.from(item);
          map['model'] = 'temperature';
          return map;
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取体温记录');
    }
  }

  static Future<void> addTemperature(int childId, String time, double temperature, {String? temperatureUnit, String? notes}) async {
    try {
      final data = <String, dynamic>{
        'child': childId, 'time': time, 'temperature': temperature,
      };
      if (temperatureUnit != null) data['temperature_unit'] = temperatureUnit;
      if (notes != null) data['notes'] = notes;

      await dio.post('/api/temperature/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '添加体温记录');
    }
  }

  static Future<void> updateTemperature(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/temperature/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新体温记录');
    }
  }

  static Future<void> deleteTemperature(int id) async {
    try {
      await dio.delete('/api/temperature/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '删除体温记录');
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
    } on DioException catch (e) {
      throw _handleApiError(e, '获取计时器列表');
    }
  }

  static Future<Map<String, dynamic>> addTimer({int? childId, String? name}) async {
    try {
      final data = <String, dynamic>{};
      if (childId != null) data['child'] = childId;
      if (name != null) data['name'] = name;

      final response = await dio.post('/api/timers/', data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleApiError(e, '添加计时器');
    }
  }

  static Future<Map<String, dynamic>> getTimerById(int id) async {
    try {
      final response = await dio.get('/api/timers/$id/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleApiError(e, '获取计时器详情');
    }
  }

  static Future<Map<String, dynamic>> restartTimer(int id) async {
    try {
      final response = await dio.patch('/api/timers/$id/restart/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleApiError(e, '重启计时器');
    }
  }

  static Future<void> stopTimer(int id) async {
    try {
      await dio.delete('/api/timers/$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, '停止计时器');
    }
  }

  static Future<void> updateTimer(int id, Map<String, dynamic> data) async {
    try {
      await dio.patch('/api/timers/$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, '更新计时器');
    }
  }

  static Future<List<dynamic>> getTags() async {
    try {
      final response = await dio.get('/api/tags/');
      if (response.data != null && response.data['results'] != null) {
        return response.data['results'] as List;
      }
      return [];
    } on DioException catch (e) {
      throw _handleApiError(e, '获取标签');
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
        getWeight(limit: limit, childId: childId),
        getHeight(limit: limit, childId: childId),
        getHeadCircumference(limit: limit, childId: childId),
        getTemperature(limit: limit, childId: childId),
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

  static Exception _handleApiError(DioException e, String action) {
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return Exception('没有权限，请重新登录');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('$action失败：连接超时');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('$action失败：无法连接到服务器');
    } else if (e.response?.statusCode == 500) {
      return Exception('$action失败：服务器错误');
    } else {
      final errorMessage = e.response?.data is Map
          ? e.response?.data['detail'] ?? e.response?.data['message']
          : e.response?.data;
      return Exception('$action失败：${errorMessage ?? e.message}');
    }
  }
}

class AuthInterceptor extends Interceptor {
  final String token;
  
  AuthInterceptor(this.token);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Token $token';
    return handler.next(options);
  }
}
