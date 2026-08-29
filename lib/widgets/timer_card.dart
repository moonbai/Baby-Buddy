import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:babybuddy_app/utils/timer_manager.dart';
import 'package:babybuddy_app/utils/date_time_utils.dart';
import 'package:babybuddy_app/screens/quick_add.dart';
import 'package:babybuddy_app/generated/app_localizations.dart';
import 'package:babybuddy_app/generated/app_localizations_en.dart';

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

  AppLocalizations get l10n =>
      AppLocalizations.of(context) ?? AppLocalizationsEn();

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
    final start = widget.timer['start'];
    if (start is! String) return;
    if (mounted) {
      setState(() {
        _currentDuration = TimerManager.calculateDuration(start);
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
              title: Text(l10n.recordFeeding),
              onTap: () {
                Navigator.pop(context);
                _useTimerForFeeding();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: Text(l10n.recordSleep),
              onTap: () {
                Navigator.pop(context);
                _useTimerForSleep();
              },
            ),
            ListTile(
              leading: const Icon(Icons.accessibility_new),
              title: Text(l10n.recordTummyTime),
              onTap: () {
                Navigator.pop(context);
                _useTimerForTummyTime();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: Text(l10n.restartTimer),
              onTap: () {
                Navigator.pop(context);
                _restartTimer();
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop, color: Colors.red),
              title: Text(l10n.stopTimer),
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
    final childId = widget.selectedChildId;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
      return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FeedingOptions(
        childId: childId,
        editItem: null,
        timer: widget.timer,
        onSaved: () {
          widget.onTimerUsed?.call();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _useTimerForSleep() async {
    final childId = widget.selectedChildId;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
      return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SleepOptions(
        childId: childId,
        editItem: null,
        timer: widget.timer,
        onSaved: () {
          widget.onTimerUsed?.call();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _useTimerForTummyTime() async {
    final childId = widget.selectedChildId;
    if (childId == null) {
      Fluttertoast.showToast(msg: l10n.noChildSelected);
      return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TummyTimeOptions(
        childId: childId,
        editItem: null,
        timer: widget.timer,
        onSaved: () {
          widget.onTimerUsed?.call();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _restartTimer() async {
    final timerId = widget.timer['id'];
    if (timerId is! int) {
      if (mounted) Fluttertoast.showToast(msg: l10n.addFailed);
      return;
    }
    try {
      await TimerManager().restartTimer(timerId);
      if (mounted) Fluttertoast.showToast(msg: l10n.timerRestarted);
    } catch (e) {
      if (mounted) Fluttertoast.showToast(msg: '${l10n.updateFailed}: $e');
    }
  }

  Future<void> _stopTimer() async {
    final timerId = widget.timer['id'];
    if (timerId is! int) {
      if (mounted) Fluttertoast.showToast(msg: l10n.addFailed);
      return;
    }
    try {
      await TimerManager().stopTimer(timerId);
      widget.onTimerStopped?.call();
      if (mounted) Fluttertoast.showToast(msg: l10n.timerStopped);
    } catch (e) {
      if (mounted) Fluttertoast.showToast(msg: '${l10n.updateFailed}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.timer['name'] as String?;
    final timerId = widget.timer['id'];
    final durationText = TimerManager.formatDuration(_currentDuration);
    final theme = Theme.of(context);
    final iconBg = theme.brightness == Brightness.dark
        ? Colors.orange.withOpacity(0.2)
        : Colors.orange.shade100;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showUseTimerOptions(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBg,
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
                      name ?? '${l10n.timer} #$timerId',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationText,
                      style: theme.textTheme.headlineMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.stopTimer,
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


