import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/settings_provider.dart';
import '../localization.dart';
import 'home_page.dart';
import 'explore_page.dart';
import 'custom_dns_page.dart';
import 'about_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ExplorePage(), // Acting as 'Explore'
    const CustomDnsPage(), // Acting as 'Add DNS'
    const AboutPage(), // Settings/Other
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsProvider>().language;

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar Panel matching ClearVPN mockup
          Container(
            width: 90,
            decoration: const BoxDecoration(
              color: Color(0xFF0A0C10), // Very dark background for sidebar
            ),
            child: Column(
              children: [
                // Drag Area for Top Left Sidebar
                DragToMoveArea(
                  child: Container(
                    padding: const EdgeInsets.only(top: 48, bottom: 24),
                    color: Colors.transparent, // Expand drag area
                    height: 80,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 32),
                _buildNavItem(Icons.language_rounded, 0, AppLocalization.get(lang, 'dns')),
                const SizedBox(height: 32),
                _buildNavItem(Icons.bar_chart_rounded, 1, AppLocalization.get(lang, 'explore')),
                const SizedBox(height: 32),
                _buildNavItem(Icons.extension_rounded, 2, AppLocalization.get(lang, 'add_dns')),
                const Spacer(),
                _buildNavItem(Icons.settings_rounded, 3, AppLocalization.get(lang, 'settings')),
                const SizedBox(height: 32), // Bottom padding
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: _pages[_currentIndex],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildNavItem(IconData icon, int index, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.white : Colors.white54;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        color: Colors.transparent, // Expand tap area
        width: double.infinity,
        child: Column(
          children: [
             AnimatedContainer(
               duration: const Duration(milliseconds: 200),
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: isSelected ? Colors.grey.withOpacity(0.15) : Colors.transparent,
                 borderRadius: BorderRadius.circular(16)
               ),
               child: Icon(icon, size: 28, color: color),
             ),
             const SizedBox(height: 6),
             Text(
               label, 
               style: TextStyle(
                 color: color, 
                 fontSize: 11, 
                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
               )
             )
          ]
        )
      ),
    );
  }
}
