import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'providers/dns_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  launchAtStartup.setup(
    appName: 'DNS Changer',
    appPath: Platform.resolvedExecutable,
  );

  WindowOptions windowOptions = const WindowOptions(
    size: Size(850, 650),
    minimumSize: Size(850, 650),
    maximumSize: Size(850, 650),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setResizable(false);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DnsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const DnsChangerApp(),
    ),
  );
}

class DnsChangerApp extends StatelessWidget {
  const DnsChangerApp({super.key});

  ThemeData _getThemeData(String themeMode) {
    Color primary = const Color(0xFF6318FF);
    Color scaffoldBg = const Color(0xFF0F111A);
    Color cardColor = const Color(0xFF1A1C29);
    Brightness brightness = Brightness.dark;

    switch (themeMode) {
      case 'light':
        primary = const Color(0xFF4A148C);
        scaffoldBg = const Color(0xFFF5F5F5);
        cardColor = Colors.white;
        brightness = Brightness.light;
        break;
      case 'red':
        primary = Colors.redAccent.shade400;
        scaffoldBg = const Color(0xFF1A0A0A);
        cardColor = const Color(0xFF291010);
        break;
      case 'green':
        primary = Colors.greenAccent.shade700;
        scaffoldBg = const Color(0xFF0F1712);
        cardColor = const Color(0xFF152219);
        break;
      case 'dark':
      default:
        break;
    }

    return ThemeData(
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: scaffoldBg,
      cardColor: cardColor,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: brightness == Brightness.dark ? Colors.white : Colors.black87,
      ),
      fontFamily: 'Segoe UI',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'DNS Changer',
          debugShowCheckedModeBanner: false,
          theme: _getThemeData(settings.themeMode),
          home: const MainLayout(),
        );
      },
    );
  }
}
