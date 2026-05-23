import 'package:flutter/material.dart';
import 'package:babybuddy_app/utils/storage.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'system';
  bool _quickReport = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final themeMode = await Storage.getThemeMode();
    final quickReport = await Storage.getQuickReport();
    setState(() {
      _themeMode = themeMode!;
      _quickReport = quickReport!;
      _isLoading = false;
    });
  }

  Future<void> _updateThemeMode(String mode) async {
    setState(() => _themeMode = mode);
    await Storage.saveThemeMode(mode);
    widget.onThemeChanged?.call();
  }

  Future<void> _toggleQuickReport(bool value) async {
    setState(() => _quickReport = value);
    await Storage.saveQuickReport(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildThemeSection(),
                const SizedBox(height: 24),
                _buildFeaturesSection(),
              ],
            ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '主题设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '选择应用的主题模式',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              icon: Icons.phone_android,
              title: '跟随系统',
              subtitle: '自动切换深色/浅色',
              value: 'system',
              groupValue: _themeMode,
              onChanged: _updateThemeMode,
            ),
            _buildThemeOption(
              icon: Icons.wb_sunny,
              title: '浅色模式',
              subtitle: '始终使用浅色主题',
              value: 'light',
              groupValue: _themeMode,
              onChanged: _updateThemeMode,
            ),
            _buildThemeOption(
              icon: Icons.dark_mode,
              title: '深色模式',
              subtitle: '始终使用深色主题',
              value: 'dark',
              groupValue: _themeMode,
              onChanged: _updateThemeMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: groupValue,
      onChanged: (v) => onChanged(v!),
      secondary: Icon(icon),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Widget _buildFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '功能设置',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('快速提报模式'),
              subtitle: const Text('开启后点击添加按钮显示快速提报选项'),
              value: _quickReport,
              onChanged: _toggleQuickReport,
              secondary: const Icon(Icons.speed),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            ),
          ],
        ),
      ),
    );
  }
}
