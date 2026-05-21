import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/storage.dart';

class QuickAdd extends StatefulWidget {
  const QuickAdd({super.key});

  @override
  State<QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<QuickAdd> {
  int? childId;
  final now = DateTime.now();

  @override
  void initState() {
    super.initState();
    Storage.getChildId().then((v) => setState(() => childId = v));
  }

  String fmt(DateTime t) => DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(t);

  Future feed() async {
    final s = now;
    final e = now.add(const Duration(minutes: 20));
    await ApiService.addFeeding(childId!, fmt(s), fmt(e), 'breast milk', 'left');
    if (mounted) Navigator.pop(context);
  }

  Future sleep() async {
    final s = now;
    final e = now.add(const Duration(hours: 2));
    await ApiService.addSleep(childId!, fmt(s), fmt(e));
    if (mounted) Navigator.pop(context);
  }

  Future diaper() async {
    await ApiService.addDiaper(childId!, fmt(now), true, false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('快速记录')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: feed, child: const Text('➕ 喂奶')),
            const SizedBox(height:12),
            ElevatedButton(onPressed: sleep, child: const Text('😴 睡眠')),
            const SizedBox(height:12),
            ElevatedButton(onPressed: diaper, child: const Text('💩 尿布')),
          ],
        ),
      ),
    );
  }
}
