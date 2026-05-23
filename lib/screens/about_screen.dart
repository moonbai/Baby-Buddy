import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:babybuddy_app/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.about),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.child_care,
                    size: 84,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Baby Buddy',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.babyGrowthAssistant,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF616161),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFEEEEEE)),
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF2196F3)),
            title: Text(l10n.author, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('Mars', style: TextStyle(color: Color(0xFF757575))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFEEEEEE)),
          ListTile(
            leading: const Icon(Icons.link, color: Color(0xFF2196F3)),
            title: Text(l10n.sourceRepo, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: const Text('https://github.com/moonbai/Baby-Buddy',
                style: TextStyle(color: Color(0xFF757575), fontSize: 13)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onTap: () => _launchUrl('https://github.com/moonbai/Baby-Buddy'),
          ),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFEEEEEE)),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Color(0xFF2196F3)),
            title: Text(l10n.projectIntro, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              l10n.projectDesc,
              style: const TextStyle(color: Color(0xFF757575), height: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFEEEEEE)),
          ListTile(
            leading: const Icon(Icons.copyright, color: Color(0xFF2196F3)),
            title: Text(l10n.copyrightInfo, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(l10n.copyrightText, style: const TextStyle(color: Color(0xFF757575))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ],
      ),
    );
  }
}
