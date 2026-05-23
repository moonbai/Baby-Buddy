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

  Future<void> _loadSettings() async {
    final themeMode = await Storage.getThemeMode();
    final quickReport = await Storage.getQuickReport();
    final language = await Storage.getLanguage();
    setState(() {
      _themeMode = themeMode!;
      _quickReport = quickReport!;
      _language = language!;
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

  Future<void> _updateLanguage(String language) async {
    setState(() => _language = language);
    await Storage.saveLanguage(language);
    MyApp.of(context)?.updateLanguage(language);
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

  Widget _buildThemeSection() {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.themeSettings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chooseTheme,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            _buildThemeOption(
              icon: Icons.phone_android,
              title: l10n.followSystem,
              subtitle: l10n.followSystemSubtitle,
              value: 'system',
              groupValue: _themeMode,
              onChanged: _updateThemeMode,
            ),
            _buildThemeOption(
              icon: Icons.wb_sunny,
              title: l10n.lightMode,
              subtitle: l10n.lightModeSubtitle,
              value: 'light',
              groupValue: _themeMode,
              onChanged: _updateThemeMode,
            ),
            _buildThemeOption(
              icon: Icons.dark_mode,
              title: l10n.darkMode,
              subtitle: l10n.darkModeSubtitle,
              value: 'dark',
              groupValue: _themeMode,
              onChanged: _updateThemeMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.languageSettings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chooseLanguage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            _buildLanguageOption(
              title: l10n.chinese,
              value: 'zh',
              groupValue: _language,
              onChanged: _updateLanguage,
            ),
            _buildLanguageOption(
              title: l10n.english,
              value: 'en',
              groupValue: _language,
              onChanged: _updateLanguage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Row(
          children: [
            Icon(
              Icons.translate,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
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
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
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
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final l10n = AppLocalizations.of(context)!;
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
                  l10n.featureSettings,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.speed,
                  color: _quickReport ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.quickReportModeSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _quickReport,
                  onChanged: _toggleQuickReport,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
