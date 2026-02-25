import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/settings_provider.dart';
import '../localization.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.language;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DragToMoveArea(
          child: AppBar(title: Text(AppLocalization.get(lang, 'settings'))),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Language
              Text(AppLocalization.get(lang, 'language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: settings.language,
                    dropdownColor: Theme.of(context).cardColor,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'fa', child: Text('فارسی')),
                      DropdownMenuItem(value: 'zh', child: Text('中文 (Chinese)')),
                      DropdownMenuItem(value: 'es', child: Text('Español')),
                      DropdownMenuItem(value: 'ru', child: Text('Русский')),
                    ],
                    onChanged: (val) {
                      if (val != null) settings.setLanguage(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Theme
              Text('Theme', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: settings.themeMode,
                    dropdownColor: Theme.of(context).cardColor,
                    items: [
                      DropdownMenuItem(value: 'dark', child: Text(AppLocalization.get(lang, 'theme_dark'))),
                      DropdownMenuItem(value: 'light', child: Text(AppLocalization.get(lang, 'theme_light'))),
                      DropdownMenuItem(value: 'red', child: Text(AppLocalization.get(lang, 'theme_red'))),
                      DropdownMenuItem(value: 'green', child: Text(AppLocalization.get(lang, 'theme_green'))),
                    ],
                    onChanged: (val) {
                      if (val != null) settings.setTheme(val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Run at Startup
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalization.get(lang, 'launch_startup'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  value: settings.runAtStartup,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (val) {
                    settings.setRunAtStartup(val);
                  },
                ),
              ),
              
              const SizedBox(height: 50),
              const Divider(color: Colors.grey),
              const SizedBox(height: 20),
              
              // About Info
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor.withOpacity(0.1)),
                      child: Icon(Icons.network_check, size: 64, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(height: 16),
                    const Text('DNS Changer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Version 1.0.0', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.code),
                      label: const Text('View on GitHub'),
                      onPressed: () async {
                        final url = Uri.parse('https://github.com');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
