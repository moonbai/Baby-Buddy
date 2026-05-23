import 'dart:async';
import 'package:flutter/material.dart';
import 'package:babybuddy_app/utils/timer_manager.dart';
import 'package:babybuddy_app/utils/date_time_utils.dart';
import 'package:babybuddy_app/screens/quick_add.dart';

class TimerCard extends StatefulWidget {
  final Map<String, dynamic> timer;
  final int? selectedChildId;
  final VoidCallback? onTimerStopped;
  final VoidCallback? onTimerUsed;

  const TimerCard({
    super.key,
    required this.timer,
    this.selectedChildId,
    this.onTimerStopped,
    this.onTimerUsed,
  });

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  late StreamSubscription _timerSubscription;
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateDuration();
    _timerSubscription = TimerManager().timersStream.listen((_) {
      _updateDuration();
    });
  }

  @override
  void dispose() {
    _timerSubscription.cancel();
    super.dispose();
  }

  void _updateDuration() {
    if (mounted) {
      setState(() {
        _currentDuration = TimerManager.calculateDuration(widget.timer['start'] as String);
      });
    }
  }

  void _showUseTimerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('记录喂奶'),
              onTap: () {
                Navigator.pop(context);
                _useTimerForFeeding();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: const Text('记录睡眠'),
              onTap: () {
                Navigator.pop(context);
                _useTimerForSleep();
              },
            ),
            ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: const Text('记录俯卧时间'),
              onTap: () {
                Navigator.pop(context);
                _useTimerForTummyTime();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: const Text('重启计时器'),
              onTap: () {
                Navigator.pop(context);
                _restartTimer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop, color: Colors.red),
              title: const Text('停止计时器'),
              onTap: () {
                Navigator.pop(context);
                _stopTimer();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useTimerForFeeding() async {
    if (widget.selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择宝宝')),
      );
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => FeedingOptions(
          childId: widget.selectedChildId!,
          editItem: null,
          timer: widget.timer,
          onSaved: () {
            widget.onTimerUsed?.call();
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  Future<void> _useTimerForSleep() async {
    if (widget.selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择宝宝')),
      );
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SleepOptions(
          childId: widget.selectedChildId!,
          editItem: null,
          timer: widget.timer,
          onSaved: () {
            widget.onTimerUsed?.call();
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  Future<void> _useTimerForTummyTime() async {
    if (widget.selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择宝宝')),
      );
      return;
    }

    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => TummyTimeOptions(
          childId: widget.selectedChildId!,
          editItem: null,
          timer: widget.timer,
          onSaved: () {
            widget.onTimerUsed?.call();
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  Future<void> _restartTimer() async {
    try {
      await TimerManager().restartTimer(widget.timer['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('计时器已重启')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重启失败: $e')),
        );
      }
    }
  }

  Future<void> _stopTimer() async {
    try {
      await TimerManager().stopTimer(widget.timer['id'] as int);
      widget.onTimerStopped?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('计时器已停止')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('停止失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.timer['name'] as String?;
    final durationText = TimerManager.formatDuration(_currentDuration);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showUseTimerOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.timer,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? '计时器 #${widget.timer['id']}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationText,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.stop, color: Colors.red),
                onPressed: _stopTimer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
