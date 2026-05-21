import 'package:flutter/material.dart';
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

  Future<void> loadTimeline() async {
    final data = await ApiService.getTimeline();
    setState(() => timeline = data);
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
        child: ListView.builder(
          itemCount: timeline.length,
          itemBuilder: (c,i){
            final item = timeline[i];
            return ListTile(
              title: Text(item['model'] ?? ''),
              subtitle: Text(item['time'] ?? ''),
            );
          },
        ),
      ),
    );
  }
}
