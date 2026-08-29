import 'package:flutter/material.dart';
import 'package:babybuddy_app/utils/storage.dart';
import 'package:babybuddy_app/main.dart';
import 'package:babybuddy_app/generated/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onThemeChanged;

  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'system';
  String _language = 'zh';
  bool _quickReport = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 并行加载所有设置，避免 3 次串行 await
  Future<void> _loadSettings() async {
    final results = await Future.wait([
      Storage.getThemeMode(),
      Storage.getQuickReport(),
      Storage.getLanguage(),
    ]);
    if (!mounted) return;
    setState(() {
      _themeMode = results[0] as String;
      _quickReport = results[1] as bool;
      _language = results[2] as String;
      _isLoading = false;
    });
  }

  Future<void> _updateThemeMode(String mode) async {
    setState(() => _themeMode = mode);
    await Storage.saveThemeMode(mode);
    // MyApp.updateThemeMode 现在是异步的：立即改 UI 状态并持久化
    if (mounted) {
      await MyApp.of(context)?.updateThemeMode(mode);
    }
    widget.onThemeChanged?.call();
  }

  Future<void> _toggleQuickReport(bool value) async {
    setState(() => _quickReport = value);
    await Storage.saveQuickReport(value);
  }

  Future<void> _updateLanguage(String language) async {
    setState(() => _language = language);
    await Storage.saveLanguage(language);
    if (mounted) {
      MyApp.of(context)?.updateLanguage(language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildThemeSection(),
                const SizedBox(height: 24),
                _buildLanguageSection(),
                const SizedBox(height: 24),
                _buildFeaturesSection(),
              ],
            ),
    );
  }

  // ============== 主题 ==============
  Widget _buildThemeSection() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.themeSettings, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chooseTheme,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              icon: Icons.phone_android,
              title: l10n.followSystem,
              subtitle: l10n.followSystemSubtitle,
              value: 'system',
            ),
            _buildThemeOption(
              icon: Icons.wb_sunny,
              title: l10n.lightMode,
              subtitle: l10n.lightModeSubtitle,
              value: 'light',
            ),
            _buildThemeOption(
              icon: Icons.dark_mode,
              title: l10n.darkMode,
              subtitle: l10n.darkModeSubtitle,
              value: 'dark',
            ),
          ],
        ),
      ),
    );
  }

  // ============== 语言 ==============
  Widget _buildLanguageSection() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.languageSettings, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chooseLanguage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(title: l10n.chinese, value: 'zh'),
            _buildLanguageOption(title: l10n.english, value: 'en'),
          ],
        ),
      ),
    );
  }

  // ============== 功能开关 ==============
  Widget _buildFeaturesSection() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(l10n.featureSettings, style: theme.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: _quickReport
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.quickReportMode,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.quickReportModeSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: _quickReport, onChanged: _toggleQuickReport),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============== 通用组件 ==============

  Widget _buildLanguageOption({
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == _language;
    return InkWell(
      onTap: () => _updateLanguage(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.translate,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _language,
              onChanged: (v) => _updateLanguage(v!),
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
  }) {
    final theme = Theme.of(context);
    final isSelected = value == _themeMode;
    return InkWell(
      onTap: () => _updateThemeMode(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _themeMode,
              onChanged: (v) => _updateThemeMode(v!),
            ),
          ],
        ),
      ),
    );
  }
}
