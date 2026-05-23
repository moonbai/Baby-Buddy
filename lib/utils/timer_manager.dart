import 'dart:async';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/date_time_utils.dart';

class TimerManager {
  static final TimerManager _instance = TimerManager._internal();
  factory TimerManager() => _instance;
  TimerManager._internal();

  final List<Map<String, dynamic>> _timers = [];
  final Map<int, Timer> _timerUpdates = {};
  final StreamController<List<Map<String, dynamic>>> _timersController =
      StreamController.broadcast();

  Stream<List<Map<String, dynamic>>> get timersStream => _timersController.stream;
  List<Map<String, dynamic>> get timers => List.unmodifiable(_timers);

  Future<void> loadTimers({int? childId}) async {
    try {
      final timers = await ApiService.getTimers(childId: childId);
      _timers.clear();
      _timers.addAll(timers.cast<Map<String, dynamic>>());
      _startTimerUpdates();
      _timersController.add(List.from(_timers));
    } catch (e) {
      print('加载计时器失败: $e');
    }
  }

  Future<Map<String, dynamic>> createTimer({int? childId, String? name}) async {
    try {
      final timer = await ApiService.addTimer(childId: childId, name: name);
      _timers.insert(0, timer);
      _startTimerUpdates();
      _timersController.add(List.from(_timers));
      return timer;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> restartTimer(int id) async {
    try {
      final updatedTimer = await ApiService.restartTimer(id);
      final index = _timers.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _timers[index] = updatedTimer;
        _timersController.add(List.from(_timers));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> stopTimer(int id) async {
    try {
      await ApiService.stopTimer(id);
      _timers.removeWhere((t) => t['id'] == id);
      _stopTimerUpdate(id);
      _timersController.add(List.from(_timers));
    } catch (e) {
      rethrow;
    }
  }

  void _startTimerUpdates() {
    for (final timer in _timers) {
      final id = timer['id'] as int;
      if (!_timerUpdates.containsKey(id)) {
        _timerUpdates[id] = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateTimerDuration(id);
        });
      }
    }
  }

  void _stopTimerUpdate(int id) {
    _timerUpdates[id]?.cancel();
    _timerUpdates.remove(id);
  }

  void _updateTimerDuration(int id) {
    final index = _timers.indexWhere((t) => t['id'] == id);
    if (index != -1) {
      _timersController.add(List.from(_timers));
    }
  }

  static Duration calculateDuration(String startTime) {
    try {
      final start = DateTime.parse(startTime).toLocal();
      final now = DateTime.now();
      return now.difference(start);
    } catch (e) {
      return Duration.zero;
    }
  }

  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void dispose() {
    for (final timer in _timerUpdates.values) {
      timer.cancel();
    }
    _timerUpdates.clear();
    _timersController.close();
  }
}
