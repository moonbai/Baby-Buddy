import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/storage.dart';

class ChildSelect extends StatefulWidget {
  const ChildSelect({super.key});

  @override
  State<ChildSelect> createState() => _ChildSelectState();
}

class _ChildSelectState extends State<ChildSelect> {
  List children = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final list = await ApiService.getChildren();
      setState(() {
        children = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: '加载宝宝列表失败');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择宝宝')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
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
              onPressed: load,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '暂无宝宝，请先在 Baby Buddy 添加宝宝',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (c, i) {
        final item = children[i];
        final firstName = item['first_name'] ?? '';
        final lastName = item['last_name'] ?? '';
        return ListTile(
          leading: CircleAvatar(
            child: Text(firstName.isNotEmpty ? firstName[0].toUpperCase() : '?'),
          ),
          title: Text('$firstName $lastName'),
          subtitle: item['birth_date'] != null 
              ? Text('生日: ${item['birth_date']}') 
              : null,
          onTap: () async {
            await Storage.saveChildId(item['id']);
            if (mounted) {
              Fluttertoast.showToast(msg: '已选择 $firstName');
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }
}
