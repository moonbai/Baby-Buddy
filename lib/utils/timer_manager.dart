import 'dart:async';
import 'package:babybuddy_app/api/api_service.dart';

/// 全局计时器管理器（单例）
///
/// 优化点：
/// 1. 合并 N 个 Timer 为 1 个全局 tick（只要列表非空，每秒广播一次），减少资源占用
/// 2. 统一的 Stream API，外部 UI 订阅后自动在每次 tick 收到最新快照
/// 3. 单例可被多个页面共享，避免重复加载
class TimerManager {
  TimerManager._internal();
  static final TimerManager _instance = TimerManager._internal();
  factory TimerManager() => _instance;

  final List<Map<String, dynamic>> _timers = [];
  final StreamController<List<Map<String, dynamic>>> _timersController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  /// 全局统一的 tick：所有在线计时器共用一个定时器
  Timer? _globalTicker;

  /// 对外暴露的只读流
  Stream<List<Map<String, dynamic>>> get timersStream => _timersController.stream;

  /// 不可变快照
  List<Map<String, dynamic>> get timers => List.unmodifiable(_timers);

  bool get hasActiveTimers => _timers.isNotEmpty;

  // ============== 对外 API ==============

  /// 从服务端加载计时器（通常页面打开或切换宝宝时调用）
  Future<void> loadTimers({int? childId}) async {
    try {
      final timers = await ApiService.getTimers(childId: childId);
      _timers
        ..clear()
        ..addAll(timers.cast<Map<String, dynamic>>());
      _emit();
      _ensureTicker();
    } catch (e) {
      // 不吞掉异常，交给上层（保持原有语义）
      rethrow;
    }
  }

  /// 创建新计时器
  Future<Map<String, dynamic>> createTimer({int? childId, String? name}) async {
    final timer = await ApiService.addTimer(childId: childId, name: name);
    _timers.insert(0, timer);
    _emit();
    _ensureTicker();
    return timer;
  }

  /// 重启指定计时器
  Future<void> restartTimer(int id) async {
    final updatedTimer = await ApiService.restartTimer(id);
    final index = _timers.indexWhere((t) => t['id'] == id);
    if (index != -1) {
      _timers[index] = updatedTimer;
      _emit();
    }
  }

  /// 停止并移除指定计时器
  Future<void> stopTimer(int id) async {
    await ApiService.stopTimer(id);
    _timers.removeWhere((t) => t['id'] == id);
    _emit();
    _cancelTickerIfIdle();
  }

  /// 静态工具：根据服务端开始时间计算已运行时长
  static Duration calculateDuration(String startTime) {
    try {
      final start = DateTime.parse(startTime).toLocal();
      return DateTime.now().difference(start);
    } catch (_) {
      return Duration.zero;
    }
  }

  /// 静态工具：把 Duration 格式化为 HH:mm:ss
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // ============== 内部逻辑 ==============

  /// 向订阅者广播最新快照
  void _emit() {
    if (!_timersController.isClosed) {
      _timersController.add(List<Map<String, dynamic>>.unmodifiable(_timers));
    }
  }

  /// 如果没有启动全局 ticker，且当前有活跃计时器，则启动它
  void _ensureTicker() {
    if (_timers.isEmpty) return;
    if (_globalTicker != null && _globalTicker!.isActive) return;
    _globalTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      _emit(); // 每秒广播一次，UI 根据 start 自己算时长
    });
  }

  /// 如果计时器列表为空，关闭 ticker 省电
  void _cancelTickerIfIdle() {
    if (_timers.isEmpty && _globalTicker != null) {
      _globalTicker!.cancel();
      _globalTicker = null;
    }
  }

  /// 释放所有资源。通常 App 退出时调用，或单元测试 tearDown。
  /// 作为单例生命周期等同 App，一般不强制调用。
  void dispose() {
    _globalTicker?.cancel();
    _globalTicker = null;
    _timers.clear();
    if (!_timersController.isClosed) {
      _timersController.close();
    }
  }
}
