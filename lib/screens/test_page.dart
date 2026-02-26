import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/platform_test_provider.dart';
import '../providers/dns_provider.dart';
import '../services/speed_test_service.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight + 48),
          child: Column(
            children: [
              // We'll leave the very top area empty since the DragArea handles window drags from main_layout
              SizedBox(height: kToolbarHeight), 
              TabBar(
                labelColor: Color(0xFF6318FF),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF6318FF),
                tabs: [
                  Tab(text: 'Platform Test', icon: Icon(Icons.public)),
                  Tab(text: 'Speed Test', icon: Icon(Icons.speed)),
                ],
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PlatformTestView(),
            SpeedTestView(),
          ],
        ),
      ),
    );
  }
}

class PlatformTestView extends StatelessWidget {
  const PlatformTestView({super.key});

  @override
  Widget build(BuildContext context) {
    final platformProvider = context.watch<PlatformTestProvider>();
    final dnsProvider = context.watch<DnsProvider>();
    
    // Combine both default and custom DNS into one testing pool
    final testableDnsList = [...dnsProvider.exploreList, ...dnsProvider.customDnsList];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Target Platform:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Horizontal Platform Selector
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: platformProvider.availablePlatforms.length,
              itemBuilder: (context, index) {
                final platform = platformProvider.availablePlatforms[index];
                final isSelected = platformProvider.selectedPlatform?.id == platform.id;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(platform.name, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade400)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6318FF),
                    backgroundColor: const Color(0xFF161824),
                    onSelected: (selected) {
                      if (selected && !platformProvider.isTesting) {
                        platformProvider.selectPlatform(platform);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: platformProvider.isTesting 
                    ? null 
                    : () {
                        platformProvider.runBulkTest(
                          testableDnsList,
                          dnsProvider.selectedDns,
                          dnsProvider.isDnsActive
                        );
                      },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run Bulk Test'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6318FF), foregroundColor: Colors.white),
              ),
              const SizedBox(width: 12),
              if (platformProvider.isTesting)
                ElevatedButton.icon(
                  onPressed: () => platformProvider.stopTest(),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                )
              else
                OutlinedButton.icon(
                  onPressed: platformProvider.testResults.isEmpty ? null : () => platformProvider.clearResults(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          if (platformProvider.isTesting)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Testing: ${platformProvider.currentTestDnsName}... (Internet may drop temporarily)',
                style: const TextStyle(color: Colors.orangeAccent, fontStyle: FontStyle.italic),
              ),
            ),
            
          // Results List
          Expanded(
            child: ListView.builder(
              itemCount: testableDnsList.length,
              itemBuilder: (context, index) {
                final dns = testableDnsList[index];
                final result = platformProvider.testResults[dns.id] ?? 'Pending';
                
                Color statusColor = Colors.grey;
                if (result.contains('Accessible')) statusColor = Colors.greenAccent;
                if (result.contains('Blocked') || result.contains('Failed')) statusColor = Colors.redAccent;
                if (result.contains('Testing')) statusColor = Colors.orangeAccent;

                return Card(
                  color: const Color(0xFF1A1C29),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(dns.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${dns.primary} / ${dns.secondary}'),
                    trailing: Text(
                      result,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class SpeedTestView extends StatefulWidget {
  const SpeedTestView({super.key});

  @override
  State<SpeedTestView> createState() => _SpeedTestViewState();
}

class _SpeedTestViewState extends State<SpeedTestView> {
  final SpeedTestService _speedService = SpeedTestService();
  bool _isTesting = false;
  String _statusMessage = 'Ready to test system connection speed.';
  SpeedTestResult? _result;

  void _runSpeedTest() async {
    setState(() {
      _isTesting = true;
      _result = null;
      _statusMessage = 'Initializing...';
    });
    
    final result = await _speedService.runFullTest(
      onProgress: (status) {
        if (mounted) setState(() => _statusMessage = status);
      }
    );
    
    if (mounted) {
      setState(() {
        _result = result;
        _isTesting = false;
        _statusMessage = 'Test Complete.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_statusMessage, style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Ping', _result != null ? '${_result!.averagePing} ms' : '--', Icons.compare_arrows),
                _buildStatCard('Jitter', _result != null ? '${_result!.jitter} ms' : '--', Icons.show_chart),
                _buildStatCard('Download', _result != null ? '${_result!.downloadSpeedMbps} Mbps' : '--', Icons.download),
              ],
            ),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                onPressed: _isTesting ? null : _runSpeedTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6318FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _isTesting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Start Speed Test', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.grey.shade500),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(color: Colors.grey.shade400)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
