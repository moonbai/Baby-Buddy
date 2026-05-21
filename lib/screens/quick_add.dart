import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    Storage.getChildId().then((v) => setState(() => childId = v));
  }

  String fmt(DateTime t) => DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(t);

  Future<void> feed() async {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final s = now;
      final e = now.add(const Duration(minutes: 20));
      await ApiService.addFeeding(childId!, fmt(s), fmt(e), 'breast milk', 'left');
      if (mounted) {
        Fluttertoast.showToast(msg: '喂奶记录已添加');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: '添加失败: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> sleep() async {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final s = now;
      final e = now.add(const Duration(hours: 2));
      await ApiService.addSleep(childId!, fmt(s), fmt(e));
      if (mounted) {
        Fluttertoast.showToast(msg: '睡眠记录已添加');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: '添加失败: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> diaper() async {
    if (childId == null) {
      Fluttertoast.showToast(msg: '请先选择宝宝');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.addDiaper(childId!, fmt(now), true, false);
      if (mounted) {
        Fluttertoast.showToast(msg: '尿布记录已添加');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: '添加失败: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('快速记录')),
      body: Center(
        child: _isLoading
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: feed,
                  child: const Text('➕ 喂奶'),
                ),
                const SizedBox(height:12),
                ElevatedButton(
                  onPressed: sleep,
                  child: const Text('😴 睡眠'),
                ),
                const SizedBox(height:12),
                ElevatedButton(
                  onPressed: diaper,
                  child: const Text('💩 尿布'),
                ),
              ],
            ),
      ),
    );
  }
}
