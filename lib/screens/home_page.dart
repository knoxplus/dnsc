import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../models/dns_model.dart';
import '../providers/dns_provider.dart';
import '../providers/settings_provider.dart';
import '../localization.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DnsProvider>();
    final lang = context.watch<SettingsProvider>().language;

    return Scaffold(
      body: Stack(
        children: [
          // Drag handle for frameless top area
          const Positioned(
            top: 0, left: 0, right: 0, height: 40,
            child: DragToMoveArea(child: SizedBox()),
          ),
          

          
          // Center main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Status Text
                Text(
                  provider.isConnecting ? AppLocalization.get(lang, 'please_wait') : (provider.isDnsActive ? AppLocalization.get(lang, 'dns_active') : AppLocalization.get(lang, 'dns_off')),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                ),
                const SizedBox(height: 12),
                
                // Selected DNS Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20, height: 14,
                      decoration: BoxDecoration(
                        color: provider.isConnecting ? Colors.orangeAccent : (provider.isDnsActive ? Colors.greenAccent : Colors.grey),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      provider.selectedDns?.name ?? AppLocalization.get(lang, 'no_dns_selected'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Text('•', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 12),
                    Text(
                      provider.selectedDns?.primary ?? '0.0.0.0',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    // Ping Action Badge
                    GestureDetector(
                      onTap: () => provider.checkPing(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: provider.pingColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: provider.pingColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.speed_rounded, size: 14, color: provider.pingColor),
                            const SizedBox(width: 6),
                            Text(
                              provider.pingResult == 'N/A' ? AppLocalization.get(lang, 'test_ping') : provider.pingResult,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: provider.pingColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),

                // Giant Glowing Button with Loading Wrapper
                _buildGlowingButton(context, provider),

                const SizedBox(height: 32),
                
                // Click to connect text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(provider.isConnecting ? Icons.hourglass_top_rounded : Icons.touch_app_outlined, color: Colors.grey.shade500, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      provider.isConnecting ? AppLocalization.get(lang, 'please_wait') : (provider.isDnsActive ? AppLocalization.get(lang, 'click_disconnect') : AppLocalization.get(lang, 'click_connect')),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                    ),
                  ],
                ),
                
                const Spacer(flex: 1),

                // Bottom Panel 1: Location / DNS Dropdown
                _buildDnsSelectorPanel(context, provider),

                const SizedBox(height: 16),

                // Bottom Panel 2: Flush DNS promo style
                _buildFlushDnsPanel(context, provider),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingButton(BuildContext context, DnsProvider provider) {
    return GestureDetector(
      onTap: provider.isConnecting ? null : () => provider.toggleDns(!provider.isDnsActive),
      child: Stack(
         alignment: Alignment.center,
         children: [
            // Loading Ring Overlay
            if (provider.isConnecting)
              const SizedBox(
                width: 200, height: 200,
                child: CircularProgressIndicator(
                   color: Colors.purpleAccent,
                   strokeWidth: 4,
                )
              ),
              
            // Core Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                   colors: provider.isDnsActive 
                       ? [const Color(0xFF5321FF), const Color(0xFF8B21FF)] 
                       : [Colors.grey.shade800, Colors.grey.shade900],
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                ),
                boxShadow: [
                   BoxShadow(
                     color: provider.isDnsActive ? const Color(0xFF6318FF).withOpacity(0.6) : Colors.black.withOpacity(0.3),
                     blurRadius: provider.isDnsActive ? 60 : 15,
                     spreadRadius: provider.isDnsActive ? 20 : 2,
                   )
                ]
              ),
              child: Center(
                child: Icon(
                  Icons.power_settings_new_rounded,
                  size: 64,
                  color: provider.isDnsActive ? Colors.white : Colors.white.withOpacity(0.4),
                ),
              ),
            ),
         ],
      ),
    );
  }

  Widget _buildDnsSelectorPanel(BuildContext context, DnsProvider provider) {
     return Container(
        width: 380,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
           color: const Color(0xFF161824),
           borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
           children: [
              Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
                 child: const Icon(Icons.language_rounded, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DnsModel>(
                     isExpanded: true,
                     value: provider.selectedDns,
                     dropdownColor: const Color(0xFF1A1C29),
                     icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                     items: [...provider.defaultDnsList, ...provider.customDnsList].map((dns) {
                        return DropdownMenuItem(
                           value: dns,
                           child: Text(
                             dns.name + (dns.isCustom ? ' (Custom)' : ''), 
                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                           )
                        );
                     }).toList(),
                     onChanged: provider.isConnecting ? null : (val) {
                        if (val != null) provider.selectDns(val);
                     }
                  )
                ),
              ),
           ]
        ),
     );
  }

  Widget _buildFlushDnsPanel(BuildContext context, DnsProvider provider) {
     return Container(
        width: 380,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
           color: const Color(0xFF221634),
           borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
           children: [
              Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withOpacity(0.1)
                 ),
                 child: const Icon(Icons.cleaning_services_rounded, size: 20, color: Colors.white70),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text('Flush DNS Cache ✨', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Clear local cache', style: TextStyle(fontSize: 12, color: Colors.white54)),
                   ]
                ),
              ),
              ElevatedButton(
                 style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC751D9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                 ),
                 onPressed: provider.isConnecting ? null : () {
                    provider.flushDns();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DNS Cache Flushed')));
                 },
                 child: const Text('Flush', style: TextStyle(fontWeight: FontWeight.bold)),
              )
           ]
        )
     );
  }
}
