import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.child_care,
                    size: 80,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Baby Buddy',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '宝宝成长记录助手',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('作者'),
            subtitle: const Text('Mars'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('源码仓库'),
            subtitle: const Text('https://github.com/moonbai/Baby-Buddy'),
            onTap: () => _launchUrl('https://github.com/moonbai/Baby-Buddy'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('项目简介'),
            subtitle: const Text(
              '这是一个 Baby Buddy 的 Flutter 移动客户端应用，'
              '用于方便地记录和查看宝宝的成长数据。',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.copyright),
            title: const Text('版权信息'),
            subtitle: const Text('© 2024 保留所有权利'),
          ),
        ],
      ),
    );
  }
}
