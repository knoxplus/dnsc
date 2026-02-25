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
              
              // About Info & Sponsor
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Info Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor.withOpacity(0.1)),
                            child: Icon(Icons.network_check, size: 48, color: Theme.of(context).primaryColor),
                          ),
                          const SizedBox(height: 12),
                          const Text('DNS Changer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Version 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.code),
                            label: const Text('GitHub Repository'),
                            onPressed: () async {
                              final url = Uri.parse('https://github.com/knoxplus/dnsc');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Sponsor Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purpleAccent.withOpacity(0.1)),
                            child: const Icon(Icons.favorite_rounded, size: 48, color: Colors.purpleAccent),
                          ),
                          const SizedBox(height: 12),
                          const Text('Sponsor: IO Game', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                            'بنفش ترین رسانه خبری گیمینگ ایران',
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(fontSize: 13, color: Colors.purpleAccent),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent.withOpacity(0.2),
                              foregroundColor: Colors.purpleAccent,
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.language, size: 18),
                            label: const Text('iogame.media'),
                            onPressed: () async {
                              final url = Uri.parse('https://iogame.media');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
