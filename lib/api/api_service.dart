import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:html/parser.dart' as html_parser;

/// 对外暴露的 401 回调（供 UI 层跳转到登录页）
typedef OnUnauthorizedCallback = FutureOr<void> Function();

/// Baby Buddy API 服务层
///
/// 优化点：
/// 1. init() 幂等：Dio 实例和 Cookie 拦截器只创建一次；Token 变化时通过 [updateAuthToken] 更新
/// 2. 提取通用 CRUD 方法（[_getList] / [_addItem] / [_updateItem] / [_deleteItem]），消除 ~600 行重复代码
/// 3. 401/403 时通过 [onUnauthorized] 通知上层跳登录，并自动清除失效 token
/// 4. 提供 [setOnUnauthorized] 让 UI 层注册回调
class ApiService {
  static Dio? _dioInstance;
  static String? _baseUrl;
  static final Map<String, String> _cookies = {};
  static String? _csrfToken;
  static String? _authToken;
  static bool _initialized = false;

  static OnUnauthorizedCallback? _onUnauthorized;

  /// 注册 401/403 回调（通常在 App 启动后调用一次）
  static void setOnUnauthorized(OnUnauthorizedCallback? cb) {
    _onUnauthorized = cb;
  }

  /// 获取 Dio 实例（保证非空）
  static Dio get dio {
    if (_dioInstance == null) {
      throw StateError('ApiService 尚未初始化，请先调用 ApiService.init()');
    }
    return _dioInstance!;
  }

  /// 初始化 Dio、Cookie 拦截器、认证拦截器（幂等）
  static Future<void> init() async {
    _baseUrl = await Storage.getServerUrl();
    final baseUrl = _baseUrl ?? 'http://127.0.0.1:8000';

    // ---- 首次初始化：只创建一次 Dio 和 Cookie 拦截器 ----
    if (!_initialized) {
      _dioInstance = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ));

      // Cookie 拦截器 - 只添加一次
      _dioInstance!.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_cookies.isNotEmpty) {
            final cookieString =
                _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
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

      // 统一错误拦截：401/403 清除 token + 回调
      _dioInstance!.interceptors.add(InterceptorsWrapper(
        onError: (e, handler) async {
          final status = e.response?.statusCode;
          if (status == 401 || status == 403) {
            // 判断是否是登录接口（登录 403 是密码错误，不触发登出）
            final path = e.requestOptions.path;
            final bool isLoginFlow = path.contains('/login');
            if (!isLoginFlow) {
              await Storage.logout();
              _authToken = null;
              final cb = _onUnauthorized;
              if (cb != null) {
                try {
                  await cb();
                } catch (_) {}
              }
            }
          }
          return handler.next(e);
        },
      ));

      _initialized = true;
    } else {
      // 非首次：仅更新 baseUrl
      _dioInstance!.options.baseUrl = baseUrl;
    }

    // ---- 同步 token & Auth 拦截器 ----
    final savedToken = await Storage.getToken();
    if (savedToken != null && savedToken != _authToken) {
      updateAuthToken(savedToken);
    }
  }

  /// 直接更新 auth token（用于登录成功后注入 token，无需重新构建 Dio）
  static void updateAuthToken(String token) {
    _authToken = token;
    // 移除旧的同名拦截器
    dio.interceptors.removeWhere((i) => i is AuthInterceptor);
    // 新增
    dio.interceptors.add(AuthInterceptor(token));
  }

  // ======================================================================
  // 通用 CRUD 私有辅助方法 —— 大幅减少重复代码
  // ======================================================================

  /// 通用 GET 列表：自动处理分页参数、从 results 字段取数据、注入 model 标签
  static Future<List<dynamic>> _getList(
    String endpoint, {
    int? limit,
    int? offset,
    int? childId,
    Map<String, dynamic>? extraQuery,
    String? modelTag,
  }) async {
    try {
      final query = <String, dynamic>{
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
        if (childId != null) 'child': childId,
        ...?extraQuery,
      };
      final response = await dio.get(endpoint, queryParameters: query.isEmpty ? null : query);
      final data = response.data;
      if (data != null && data['results'] != null) {
        final results = data['results'] as List;
        if (modelTag == null) return results;
        return results
            .map((item) => Map<String, dynamic>.from(item)..['model'] = modelTag)
            .toList();
      }
      return [];
    } on DioException catch (e) {
      // endpoint 最后一段作为资源名传入错误信息
      final resource = endpoint.replaceAll('/api/', '').replaceAll('/', '').trim();
      throw _handleApiError(e, resource);
    }
  }

  /// 通用 POST 新增
  static Future<void> _addItem(
    String endpoint,
    Map<String, dynamic> data,
    String actionName,
  ) async {
    try {
      await dio.post(endpoint, data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, actionName);
    }
  }

  /// 通用 PATCH 更新
  static Future<void> _updateItem(
    String endpoint,
    int id,
    Map<String, dynamic> data,
    String actionName,
  ) async {
    try {
      await dio.patch('$endpoint$id/', data: data);
    } on DioException catch (e) {
      throw _handleApiError(e, actionName);
    }
  }

  /// 通用 DELETE
  static Future<void> _deleteItem(
    String endpoint,
    int id,
    String actionName,
  ) async {
    try {
      await dio.delete('$endpoint$id/');
    } on DioException catch (e) {
      throw _handleApiError(e, actionName);
    }
  }

  // ======================================================================
  // 登录 / 认证
  // ======================================================================

  static Future<String?> login(String username, String password) async {
    try {
      final loginPageResponse = await dio.get(
        '/login/',
        options: Options(
          headers: {'Accept': 'text/html,application/xhtml+xml'},
          responseType: ResponseType.plain,
        ),
      );

      final html = loginPageResponse.data;
      final document = html_parser.parse(html);
      final csrfElement =
          document.querySelector('input[name="csrfmiddlewaretoken"]');
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
        ),
      );

      if (loginResponse.statusCode == 403) {
        throw Exception('用户名或密码错误');
      }
      if (loginResponse.statusCode != 200 &&
          !(loginResponse.statusCode! >= 300 &&
              loginResponse.statusCode! <= 307)) {
        throw Exception('登录失败 (状态码: ${loginResponse.statusCode})');
      }

      final profileResponse = await dio.get(
        '/api/profile',
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (profileResponse.statusCode == 200 && profileResponse.data != null) {
        final profileData = profileResponse.data;
        if (profileData['api_key'] != null) {
          final token = profileData['api_key'] as String;
          await Storage.saveToken(token);
          updateAuthToken(token); // 不再重新 init()，直接注入拦截器
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

  /// 校验 API Key / Token 是否有效
  ///
  /// 用户粘贴来自 Baby Buddy 服务器的 API Key 时，通过请求轻量接口 /api/children 验证。
  /// 返回 true 表示鉴权通过，false 表示 401/403；其他错误抛异常。
  static Future<bool> verifyToken() async {
    try {
      final resp = await dio.get('/api/children/', queryParameters: {'limit': 1});
      final status = resp.statusCode;
      if (status == 401 || status == 403) return false;
      return status != null && status >= 200 && status < 300;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) return false;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception('无法连接到服务器，请检查地址和网络');
      }
      if (status == 404) throw Exception('服务器地址错误，请确认URL正确');
      throw Exception('验证失败: ${e.message}');
    }
  }

  // ======================================================================
  // Children
  // ======================================================================

  static Future<List<dynamic>> getChildren({int? limit, int? offset}) =>
      _getList('/api/children/', limit: limit, offset: offset);

  static Future<Map<String, dynamic>> getChildById(int id) async {
    try {
      final response = await dio.get('/api/children/$id/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleApiError(e, '获取宝宝信息');
    }
  }

  // ======================================================================
  // Changes (尿布)
  // ======================================================================

  static Future<List<dynamic>> getChanges({int? limit, int? offset, int? childId}) =>
      _getList('/api/changes/', limit: limit, offset: offset, childId: childId, modelTag: 'change');

  static Future<void> addDiaper(
    int childId,
    String time,
    bool wet,
    bool solid,
    String color, {
    String? notes,
  }) =>
      _addItem('/api/changes/', {
        'child': childId,
        'time': time,
        'wet': wet,
        'solid': solid,
        'color': color,
        if (notes != null) 'notes': notes,
      }, '添加尿布记录');

  static Future<void> updateDiaper(int id, Map<String, dynamic> data) =>
      _updateItem('/api/changes/', id, data, '更新尿布记录');

  static Future<void> deleteDiaper(int id) =>
      _deleteItem('/api/changes/', id, '删除尿布记录');

  // ======================================================================
  // Feedings (喂奶)
  // ======================================================================

  static Future<List<dynamic>> getFeedings({int? limit, int? offset, int? childId}) =>
      _getList('/api/feedings/', limit: limit, offset: offset, childId: childId, modelTag: 'feeding');

  static Future<void> addFeeding(
    int childId,
    String start,
    String end,
    String type,
    String method, {
    String? notes,
    int? timer,
    double? amount,
    String? amountUnit,
  }) =>
      _addItem('/api/feedings/', {
        'child': childId,
        'start': start,
        'end': end,
        'type': type,
        'method': method,
        if (notes != null) 'notes': notes,
        if (timer != null) 'timer': timer,
        if (amount != null) 'amount': amount,
        if (amountUnit != null) 'amount_unit': amountUnit,
      }, '添加喂奶记录');

  static Future<void> updateFeeding(int id, Map<String, dynamic> data) =>
      _updateItem('/api/feedings/', id, data, '更新喂奶记录');

  static Future<void> deleteFeeding(int id) =>
      _deleteItem('/api/feedings/', id, '删除喂奶记录');

  // ======================================================================
  // Sleep (睡眠)
  // ======================================================================

  static Future<List<dynamic>> getSleep({int? limit, int? offset, int? childId}) =>
      _getList('/api/sleep/', limit: limit, offset: offset, childId: childId, modelTag: 'sleep');

  static Future<void> addSleep(
    int childId,
    String start,
    String end, {
    String? notes,
    bool? nap,
    int? timer,
  }) =>
      _addItem('/api/sleep/', {
        'child': childId,
        'start': start,
        'end': end,
        if (notes != null) 'notes': notes,
        if (nap != null) 'nap': nap,
        if (timer != null) 'timer': timer,
      }, '添加睡眠记录');

  static Future<void> updateSleep(int id, Map<String, dynamic> data) =>
      _updateItem('/api/sleep/', id, data, '更新睡眠记录');

  static Future<void> deleteSleep(int id) =>
      _deleteItem('/api/sleep/', id, '删除睡眠记录');

  // ======================================================================
  // Tummy Times (俯卧时间)
  // ======================================================================

  static Future<List<dynamic>> getTummyTimes({int? limit, int? offset, int? childId}) =>
      _getList('/api/tummy-times/', limit: limit, offset: offset, childId: childId, modelTag: 'tummy time');

  static Future<void> addTummyTime(
    int childId,
    String start,
    String end, {
    String? milestone,
    String? notes,
    int? timer,
  }) =>
      _addItem('/api/tummy-times/', {
        'child': childId,
        'start': start,
        'end': end,
        if (milestone != null) 'milestone': milestone,
        if (notes != null) 'notes': notes,
        if (timer != null) 'timer': timer,
      }, '添加俯卧时间记录');

  static Future<void> updateTummyTime(int id, Map<String, dynamic> data) =>
      _updateItem('/api/tummy-times/', id, data, '更新俯卧时间记录');

  static Future<void> deleteTummyTime(int id) =>
      _deleteItem('/api/tummy-times/', id, '删除俯卧时间记录');

  // ======================================================================
  // Pumping (吸奶)
  // ======================================================================

  static Future<List<dynamic>> getPumping({int? limit, int? offset, int? childId}) =>
      _getList('/api/pumping/', limit: limit, offset: offset, childId: childId, modelTag: 'pumping');

  static Future<void> addPumping(
    int childId,
    String start,
    String end, {
    double? amount,
    String? amountUnit,
    String? notes,
  }) =>
      _addItem('/api/pumping/', {
        'child': childId,
        'start': start,
        'end': end,
        if (amount != null) 'amount': amount,
        if (amountUnit != null) 'amount_unit': amountUnit,
        if (notes != null) 'notes': notes,
      }, '添加吸奶记录');

  static Future<void> updatePumping(int id, Map<String, dynamic> data) =>
      _updateItem('/api/pumping/', id, data, '更新吸奶记录');

  static Future<void> deletePumping(int id) =>
      _deleteItem('/api/pumping/', id, '删除吸奶记录');

  // ======================================================================
  // Notes (笔记)
  // ======================================================================

  static Future<List<dynamic>> getNotes({int? limit, int? offset, int? childId}) =>
      _getList('/api/notes/', limit: limit, offset: offset, childId: childId, modelTag: 'note');

  static Future<void> addNote(
    int childId,
    String note, {
    String? time,
  }) =>
      _addItem('/api/notes/', {
        'child': childId,
        'note': note,
        if (time != null) 'time': time,
      }, '添加笔记');

  static Future<void> updateNote(int id, Map<String, dynamic> data) =>
      _updateItem('/api/notes/', id, data, '更新笔记');

  static Future<void> deleteNote(int id) =>
      _deleteItem('/api/notes/', id, '删除笔记');

  // ======================================================================
  // Weight (体重)
  // ======================================================================

  static Future<List<dynamic>> getWeight({int? limit, int? offset, int? childId}) =>
      _getList('/api/weight/', limit: limit, offset: offset, childId: childId, modelTag: 'weight');

  static Future<void> addWeight(
    int childId,
    String date,
    double weight, {
    String? weightUnit,
    String? notes,
  }) =>
      _addItem('/api/weight/', {
        'child': childId,
        'date': date,
        'weight': weight,
        if (weightUnit != null) 'weight_unit': weightUnit,
        if (notes != null) 'notes': notes,
      }, '添加体重记录');

  static Future<void> updateWeight(int id, Map<String, dynamic> data) =>
      _updateItem('/api/weight/', id, data, '更新体重记录');

  static Future<void> deleteWeight(int id) =>
      _deleteItem('/api/weight/', id, '删除体重记录');

  // ======================================================================
  // Height (身高)
  // ======================================================================

  static Future<List<dynamic>> getHeight({int? limit, int? offset, int? childId}) =>
      _getList('/api/height/', limit: limit, offset: offset, childId: childId, modelTag: 'height');

  static Future<void> addHeight(
    int childId,
    String date,
    double height, {
    String? heightUnit,
    String? notes,
  }) =>
      _addItem('/api/height/', {
        'child': childId,
        'date': date,
        'height': height,
        if (heightUnit != null) 'height_unit': heightUnit,
        if (notes != null) 'notes': notes,
      }, '添加身高记录');

  static Future<void> updateHeight(int id, Map<String, dynamic> data) =>
      _updateItem('/api/height/', id, data, '更新身高记录');

  static Future<void> deleteHeight(int id) =>
      _deleteItem('/api/height/', id, '删除身高记录');

  // ======================================================================
  // Head Circumference (头围)
  // ======================================================================

  static Future<List<dynamic>> getHeadCircumference({int? limit, int? offset, int? childId}) =>
      _getList('/api/head-circumference/', limit: limit, offset: offset, childId: childId, modelTag: 'head circumference');

  static Future<void> addHeadCircumference(
    int childId,
    String date,
    double circumference, {
    String? circumferenceUnit,
    String? notes,
  }) =>
      _addItem('/api/head-circumference/', {
        'child': childId,
        'date': date,
        'circumference': circumference,
        if (circumferenceUnit != null) 'circumference_unit': circumferenceUnit,
        if (notes != null) 'notes': notes,
      }, '添加头围记录');

  static Future<void> updateHeadCircumference(int id, Map<String, dynamic> data) =>
      _updateItem('/api/head-circumference/', id, data, '更新头围记录');

  static Future<void> deleteHeadCircumference(int id) =>
      _deleteItem('/api/head-circumference/', id, '删除头围记录');

  // ======================================================================
  // BMI
  // ======================================================================

  static Future<List<dynamic>> getBMI({int? limit, int? offset, int? childId}) =>
      _getList('/api/bmi/', limit: limit, offset: offset, childId: childId, modelTag: 'bmi');

  static Future<void> addBMI(
    int childId,
    String date,
    double bmi, {
    String? notes,
  }) =>
      _addItem('/api/bmi/', {
        'child': childId,
        'date': date,
        'bmi': bmi,
        if (notes != null) 'notes': notes,
      }, '添加BMI记录');

  // ======================================================================
  // Temperature (体温)
  // ======================================================================

  static Future<List<dynamic>> getTemperature({int? limit, int? offset, int? childId}) =>
      _getList('/api/temperature/', limit: limit, offset: offset, childId: childId, modelTag: 'temperature');

  static Future<void> addTemperature(
    int childId,
    String time,
    double temperature, {
    String? temperatureUnit,
    String? notes,
  }) =>
      _addItem('/api/temperature/', {
        'child': childId,
        'time': time,
        'temperature': temperature,
        if (temperatureUnit != null) 'temperature_unit': temperatureUnit,
        if (notes != null) 'notes': notes,
      }, '添加体温记录');

  static Future<void> updateTemperature(int id, Map<String, dynamic> data) =>
      _updateItem('/api/temperature/', id, data, '更新体温记录');

  static Future<void> deleteTemperature(int id) =>
      _deleteItem('/api/temperature/', id, '删除体温记录');

  // ======================================================================
  // Timers (计时器)
  // ======================================================================

  static Future<List<dynamic>> getTimers({int? limit, int? offset, int? childId}) =>
      _getList('/api/timers/', limit: limit, offset: offset, childId: childId);

  static Future<Map<String, dynamic>> addTimer({int? childId, String? name}) async {
    try {
      final data = <String, dynamic>{
        if (childId != null) 'child': childId,
        if (name != null) 'name': name,
      };
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

  static Future<void> stopTimer(int id) =>
      _deleteItem('/api/timers/', id, '停止计时器');

  static Future<void> updateTimer(int id, Map<String, dynamic> data) =>
      _updateItem('/api/timers/', id, data, '更新计时器');

  /// 重建 3 个默认计时器（与 Baby Buddy 官方原版 Android App 行为一致）
  ///
  /// 流程：列出当前 child 的所有 timer → 全部 stop（删除）→ 创建默认的
  /// Feeding / Sleep / TummyTime 三个新计时器。用于快速从杂乱的 quick-timers
  /// 状态恢复成干净的默认布局。
  static Future<void> recreateDefaultTimers(int childId, {List<String>? types}) async {
    final existing = await getTimers(childId: childId, limit: 200);
    // 并行清理（互不依赖）
    await Future.wait(
      existing
          .map((t) => t['id'])
          .whereType<int>()
          .map((id) => stopTimer(id).catchError((_) => null)),
    );
    // 默认创建全部 3 个，或按传入的 types 创建
    final createTypes = types ?? ['Feeding', 'Sleep', 'Tummy Time'];
    await Future.wait(
      createTypes.map((name) => addTimer(childId: childId, name: name)),
    );
  }

  // ======================================================================
  // Tags
  // ======================================================================

  static Future<List<dynamic>> getTags() => _getList('/api/tags/');

  // ======================================================================
  // Timeline (组合接口)
  // ======================================================================

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
      for (final list in responses) {
        timeline.addAll(list);
      }

      // 提取时间键，排序降序
      String getTime(dynamic item) {
        if (item['time'] != null) return item['time'] as String;
        if (item['start'] != null) return item['start'] as String;
        if (item['date'] != null) return item['date'] as String;
        return '';
      }

      timeline.sort((a, b) => getTime(b).compareTo(getTime(a)));
      return timeline;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('获取时间线失败: $e');
    }
  }

  // ======================================================================
  // 错误处理
  // ======================================================================

  static Exception _handleApiError(DioException e, String action) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return Exception('没有权限，请重新登录');
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return Exception('$action失败：连接超时');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('$action失败：无法连接到服务器');
    } else if (status == 500) {
      return Exception('$action失败：服务器错误');
    } else {
      final data = e.response?.data;
      final errorMessage = data is Map
          ? (data['detail'] ?? data['message'] ?? data.toString())
          : data?.toString();
      return Exception('$action失败：${errorMessage ?? e.message ?? '未知错误'}');
    }
  }
}

// ======================================================================
// AuthInterceptor - Token 注入
// ======================================================================

class AuthInterceptor extends Interceptor {
  final String token;
  AuthInterceptor(this.token);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Token $token';
    return handler.next(options);
  }

  // 便于识别/去重拦截器
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthInterceptor &&
          runtimeType == other.runtimeType &&
          token == other.token;

  @override
  int get hashCode => token.hashCode;
}
