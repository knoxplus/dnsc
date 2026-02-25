import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

class SettingsProvider with ChangeNotifier {
  String _language = 'en';
  String get language => _language;

  String _themeMode = 'dark';
  String get themeMode => _themeMode;

  bool _runAtStartup = false;
  bool get runAtStartup => _runAtStartup;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _language = prefs.getString('app_language') ?? 'en';
    _themeMode = prefs.getString('app_theme') ?? 'dark';
    
    // Sync UI with actual OS startup state
    _runAtStartup = await launchAtStartup.isEnabled();
    
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _language = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
    notifyListeners();
  }

  Future<void> setTheme(String themeStr) async {
    _themeMode = themeStr;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', themeStr);
    notifyListeners();
  }

  Future<void> setRunAtStartup(bool enable) async {
    if (enable) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
    _runAtStartup = await launchAtStartup.isEnabled();
    notifyListeners();
  }
}
