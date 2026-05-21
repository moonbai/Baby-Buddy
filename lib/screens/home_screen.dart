import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/screens/child_select.dart';
import 'package:babybuddy_app/screens/quick_add.dart';
import 'package:babybuddy_app/utils/storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List timeline = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> loadTimeline() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await ApiService.getTimeline();
      setState(() => timeline = data);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      if (mounted) {
        Fluttertoast.showToast(msg: '加载时间线失败');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    loadTimeline();
  }

  Future<void> logout() async {
    await Storage.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baby Buddy'),
        actions: [
          IconButton(onPressed: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ChildSelect())), icon: const Icon(Icons.person)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const QuickAdd())),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: loadTimeline,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && timeline.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && timeline.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(fontSize: 18, color: Colors.red[300]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: loadTimeline,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (timeline.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无记录',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: timeline.length,
      itemBuilder: (c,i){
        final item = timeline[i];
        return ListTile(
          title: Text(item['model'] ?? ''),
          subtitle: Text(item['time'] ?? ''),
        );
      },
    );
  }
}
