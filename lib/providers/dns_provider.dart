import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/dns_model.dart';
import '../services/dns_engine.dart';
import '../services/ping_service.dart';

class DnsProvider with ChangeNotifier {
  final DnsEngine _dnsEngine = DnsEngine();
  final PingService _pingService = PingService();

  bool _isDnsActive = false;
  bool get isDnsActive => _isDnsActive;

  DnsModel? _selectedDns;
  DnsModel? get selectedDns => _selectedDns;

  String _pingResult = 'N/A';
  String get pingResult => _pingResult;

  Color get pingColor {
    if (_pingResult == 'N/A' || _pingResult == 'Pinging...') return Colors.grey.shade400;
    if (_pingResult == 'Failed') return Colors.redAccent;
    try {
      final value = int.parse(_pingResult.replaceAll(' ms', ''));
      if (value < 90) return Colors.greenAccent;
      if (value <= 160) return Colors.orangeAccent; // Orange is a better readable yellow on dark backgrounds
      return Colors.redAccent;
    } catch (_) {
      return Colors.grey.shade400;
    }
  }

  final List<DnsModel> _defaultDnsList = [
    DnsModel(id: 'google', name: 'Google DNS', primary: '8.8.8.8', secondary: '8.8.4.4'),
    DnsModel(id: 'cloudflare', name: 'Cloudflare', primary: '1.1.1.1', secondary: '1.0.0.1'),
    DnsModel(id: 'quad9', name: 'Quad9', primary: '9.9.9.9', secondary: '149.112.112.112'),
  ];
  List<DnsModel> get defaultDnsList => _defaultDnsList;

  List<DnsModel> _customDnsList = [];
  List<DnsModel> get customDnsList => _customDnsList;

  List<DnsModel> _exploreList = [];
  List<DnsModel> get exploreList => _exploreList;
  bool _isLoadingExplore = false;
  bool get isLoadingExplore => _isLoadingExplore;

  DnsProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load custom DNS list
    final customDnsJson = prefs.getString('custom_dns_list');
    if (customDnsJson != null) {
      final List<dynamic> decoded = jsonDecode(customDnsJson);
      _customDnsList = decoded.map((e) => DnsModel.fromJson(e)).toList();
      
      // Sanitizer: Remove duplicate IDs that clash with default list to avoid Dropdown assertion crash
      final defaultIds = _defaultDnsList.map((d) => d.id).toSet();
      bool needsCleanup = false;
      
      final seenIds = <String>{};
      _customDnsList.removeWhere((d) {
        if (defaultIds.contains(d.id) || seenIds.contains(d.id)) {
          needsCleanup = true;
          return true;
        }
        seenIds.add(d.id);
        return false;
      });
      
      if (needsCleanup) {
        _saveCustomDns(); // Silent cleanup of duplicate storage keys
      }
    }

    // Load selected DNS
    final selectedDnsId = prefs.getString('selected_dns_id');
    if (selectedDnsId != null) {
      _selectedDns = _findDnsById(selectedDnsId);
    }

    // Default selection
    if (_selectedDns == null && _defaultDnsList.isNotEmpty) {
      _selectedDns = _defaultDnsList.first;
    }

    _isDnsActive = prefs.getBool('is_dns_active') ?? false;
    notifyListeners();
  }

  DnsModel? _findDnsById(String id) {
    try {
      return [..._defaultDnsList, ..._customDnsList].firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  Future<void> selectDns(DnsModel model) async {
    _selectedDns = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_dns_id', model.id);
    _pingResult = 'N/A';
    
    if (_isDnsActive) {
      await applyDns();
    }
    notifyListeners();
  }

  Future<void> toggleDns(bool isActive) async {
    if (_selectedDns == null) return;
    
    _isConnecting = true;
    notifyListeners();

    _isDnsActive = isActive;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dns_active', isActive);
    
    if (isActive) {
      await applyDns();
    } else {
      await clearDns();
    }
    
    // Slight artificial delay to allow user to see the requested loading spinner pattern
    await Future.delayed(const Duration(milliseconds: 2000));
    _isConnecting = false;
    notifyListeners();
  }

  Future<void> applyDns() async {
    if (_selectedDns != null) {
      await _dnsEngine.setDns(_selectedDns!.primary, _selectedDns!.secondary);
    }
  }

  Future<void> clearDns() async {
    await _dnsEngine.clearDns();
  }

  Future<void> flushDns() async {
    await _dnsEngine.flushDns();
  }

  Future<void> checkPing() async {
    if (_selectedDns == null) return;
    _pingResult = 'Pinging...';
    notifyListeners();
    
    final result = await _pingService.pingAddress(_selectedDns!.primary);
    _pingResult = result != null ? '$result ms' : 'Failed'; // Fixed string interpolation bug
    notifyListeners();
  }

  // individual pings state for Explore and Custom lists
  final Map<String, String> _individualPings = {};
  Map<String, String> get individualPings => _individualPings;

  Future<void> checkIndividualPing(DnsModel model) async {
    _individualPings[model.id] = 'Pinging...';
    model.isPinging = true;
    model.pingMs = null;
    notifyListeners();

    final result = await _pingService.pingAddress(model.primary); // Returns int?
    
    if (result != null) {
      _individualPings[model.id] = '$result ms';
      model.pingMs = result;
    } else {
      _individualPings[model.id] = 'Failed';
      model.pingMs = -1;
    }
    
    model.isPinging = false;
    notifyListeners();
  }

  Color getIndividualPingColor(String id) {
    final result = _individualPings[id] ?? 'N/A';
    if (result == 'N/A' || result == 'Pinging...') return Colors.grey.shade400;
    if (result == 'Failed') return Colors.redAccent;
    try {
      final value = int.parse(result.toString().replaceAll(' ms', ''));
      if (value < 90) return Colors.greenAccent;
      if (value <= 160) return Colors.orangeAccent;
      return Colors.redAccent;
    } catch (_) {
      return Colors.grey.shade400;
    }
  }

  Future<bool> addCustomDns(DnsModel model) async {
    final exists = [..._defaultDnsList, ..._customDnsList].any(
        (d) => d.primary == model.primary && d.secondary == model.secondary);
        
    if (exists) return false;

    final newModel = DnsModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}_${model.id}',
      name: model.name,
      primary: model.primary,
      secondary: model.secondary,
      tags: model.tags,
      isCustom: true,
    );

    _customDnsList.add(newModel);
    await _saveCustomDns();
    notifyListeners();
    return true;
  }

  Future<void> removeCustomDns(DnsModel model) async {
    _customDnsList.removeWhere((d) => d.id == model.id);
    if (_selectedDns?.id == model.id) {
       _selectedDns = _defaultDnsList.first;
    }
    await _saveCustomDns();
    notifyListeners();
  }

  Future<void> _saveCustomDns() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customDnsList.map((e) => e.toJson()).toList();
    await prefs.setString('custom_dns_list', jsonEncode(jsonList));
  }

  Future<void> fetchExploreDns() async {
    _isLoadingExplore = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    List<DnsModel> fallbackList = [
      DnsModel(id: 'shecan', name: 'Shecan (شکن)', primary: '178.22.122.100', secondary: '185.51.200.2', tags: ['Gaming', 'Web', 'Download']),
      DnsModel(id: 'radar', name: 'Radar Game', primary: '10.202.10.10', secondary: '10.202.10.11', tags: ['Gaming']),
      DnsModel(id: 'electro', name: 'Electro', primary: '78.157.42.100', secondary: '78.157.42.101', tags: ['Gaming', 'Download']),
      DnsModel(id: 'cloudflare', name: 'Cloudflare', primary: '1.1.1.1', secondary: '1.0.0.1', tags: ['Gaming', 'Web', 'Download']),
      DnsModel(id: 'google', name: 'Google Public DNS', primary: '8.8.8.8', secondary: '8.8.4.4', tags: ['Gaming', 'Web', 'Download']),
      DnsModel(id: 'quad9', name: 'Quad9', primary: '9.9.9.9', secondary: '149.112.112.112', tags: ['Gaming', 'Web', 'Download']),
      DnsModel(id: 'opendns', name: 'OpenDNS', primary: '208.67.222.222', secondary: '208.67.220.220', tags: ['Web', 'Download']),
      DnsModel(id: 'adguard', name: 'AdGuard DNS', primary: '94.140.14.14', secondary: '94.140.15.15', tags: ['Web', 'Ad-Block']),
      DnsModel(id: 'begzar', name: 'Begzar (بگذر)', primary: '185.55.226.26', secondary: '185.55.225.25', tags: ['Web']),
      DnsModel(id: '403_online', name: '403.online', primary: '10.202.10.202', secondary: '10.202.10.102', tags: ['Web']),
    ];

    try {
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/knoxplus/dnsc/master/explore_dns.json?t=$cacheBuster')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        _exploreList = decoded.map((e) => DnsModel.fromJson(e)).toList();
        await prefs.setString('cached_explore_dns', response.body); // Cache for offline use
      } else {
        throw Exception('Failed to load DNS list');
      }
    } catch (e) {
      // Fallback to local cache if no internet
      final cachedJson = prefs.getString('cached_explore_dns');
      if (cachedJson != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          _exploreList = decoded.map((e) => DnsModel.fromJson(e)).toList();
        } catch (_) {
          _exploreList = fallbackList;
        }
      } else {
        _exploreList = fallbackList;
      }
    }
    
    _isLoadingExplore = false;
    notifyListeners();
  }

  Future<void> pingAllExploreDns(List<DnsModel> targets) async {
    // Fire all pings concurrently for maximum speed
    final futures = targets.map((model) => checkIndividualPing(model)).toList();
    await Future.wait(futures);
  }
}
