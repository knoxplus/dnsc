import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/dns_engine.dart';
import '../models/dns_model.dart';
import 'dns_provider.dart';

class PlatformModel {
  final String id;
  final String name;
  final String testUrl;

  PlatformModel(this.id, this.name, this.testUrl);
}

class PlatformTestProvider extends ChangeNotifier {
  final DnsEngine _dnsEngine = DnsEngine();

  List<PlatformModel> availablePlatforms = [
    PlatformModel('spotify', 'Spotify', 'https://open.spotify.com'),
    PlatformModel('chatgpt', 'ChatGPT', 'https://chatgpt.com'),
    PlatformModel('google_flow', 'Google Flow (Firebase)', 'https://firebase.google.com'),
    PlatformModel('youtube', 'YouTube', 'https://www.youtube.com'),
    PlatformModel('soundcloud', 'SoundCloud', 'https://soundcloud.com'),
  ];

  PlatformModel? _selectedPlatform;
  PlatformModel? get selectedPlatform => _selectedPlatform;

  bool _isTesting = false;
  bool get isTesting => _isTesting;

  String _currentTestDnsName = '';
  String get currentTestDnsName => _currentTestDnsName;

  // Map of DNS ID to Result (e.g., "OK (200)", "Timeout", "Error 403")
  Map<String, String> _testResults = {};
  Map<String, String> get testResults => _testResults;

  PlatformTestProvider() {
    _selectedPlatform = availablePlatforms.first;
  }

  void selectPlatform(PlatformModel platform) {
    _selectedPlatform = platform;
    notifyListeners();
  }

  void clearResults() {
    _testResults.clear();
    notifyListeners();
  }

  Future<void> stopTest() async {
    _isTesting = false;
    notifyListeners();
  }

  Future<void> runBulkTest(List<DnsModel> dnsList, DnsModel? originalDns, bool originalDnsActive) async {
    if (_selectedPlatform == null || _isTesting) return;

    _isTesting = true;
    _testResults.clear();
    notifyListeners();

    for (var dns in dnsList) {
      if (!_isTesting) break; // Allow early cancellation

      _currentTestDnsName = dns.name;
      _testResults[dns.id] = 'Testing...';
      notifyListeners();

      try {
        // 1. Swap System DNS
        await _dnsEngine.setDns(dns.primary, dns.secondary);
        
        // 2. Flush System DNS
        await _dnsEngine.flushDns();

        // Small delay to ensure network adapter catches up
        await Future.delayed(const Duration(milliseconds: 1500));

        // 3. Perform HTTP Request
        final response = await http.get(Uri.parse(_selectedPlatform!.testUrl)).timeout(const Duration(seconds: 4));
        
        if (response.statusCode >= 200 && response.statusCode < 400) {
          _testResults[dns.id] = 'Accessible (${response.statusCode})';
        } else {
          _testResults[dns.id] = 'Blocked (${response.statusCode})';
        }
      } catch (e) {
        _testResults[dns.id] = 'Failed / Timeout';
      }

      notifyListeners();
    }

    _isTesting = false;
    _currentTestDnsName = '';
    
    // Restore Original DNS State
    if (originalDnsActive && originalDns != null) {
      await _dnsEngine.setDns(originalDns.primary, originalDns.secondary);
    } else {
      await _dnsEngine.clearDns();
    }
    await _dnsEngine.flushDns();

    notifyListeners();
  }
}
