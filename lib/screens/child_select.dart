import 'package:flutter/material.dart';
import 'package:babybuddy_app/api/api_service.dart';
import 'package:babybuddy_app/utils/storage.dart';

class ChildSelect extends StatefulWidget {
  const ChildSelect({super.key});

  @override
  State<ChildSelect> createState() => _ChildSelectState();
}

class _ChildSelectState extends State<ChildSelect> {
  List children = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final list = await ApiService.getChildren();
    setState(() => children = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择宝宝')),
      body: ListView.builder(
        itemCount: children.length,
        itemBuilder: (c, i) {
          final item = children[i];
          return ListTile(
            title: Text(item['first_name'] + ' ' + item['last_name']),
            onTap: () async {
              await Storage.saveChildId(item['id']);
              if (mounted) Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
