import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../models/dns_model.dart';
import '../providers/dns_provider.dart';

class CustomDnsPage extends StatefulWidget {
  const CustomDnsPage({super.key});

  @override
  State<CustomDnsPage> createState() => _CustomDnsPageState();
}

class _CustomDnsPageState extends State<CustomDnsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();

  bool _isValidIp(String ip) {
    if (ip.isEmpty) return false;
    final regex = RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');
    return regex.hasMatch(ip);
  }

  Future<void> _save(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final newDns = DnsModel(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        primary: _primaryController.text.trim(),
        secondary: _secondaryController.text.trim(),
        isCustom: true,
      );
      
      final provider = context.read<DnsProvider>();
      final added = await provider.addCustomDns(newDns);
      
      if (added) {
        _nameController.clear();
        _primaryController.clear();
        _secondaryController.clear();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom DNS saved successfully!')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('DNS with these IPs already exists!'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DnsProvider>();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DragToMoveArea(
          child: AppBar(title: const Text('Add Custom DNS')),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'DNS Name (e.g. My Secure DNS)', prefixIcon: Icon(Icons.label)),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _primaryController,
                      decoration: const InputDecoration(labelText: 'Primary IP (e.g. 1.1.1.1)', prefixIcon: Icon(Icons.dns)),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Primary IP is required';
                        if (!_isValidIp(val.trim())) return 'Invalid IPv4 address format';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _secondaryController,
                      decoration: const InputDecoration(labelText: 'Secondary IP (Optional)', prefixIcon: Icon(Icons.dns)),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty && !_isValidIp(val.trim())) {
                          return 'Invalid IPv4 address format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        onPressed: () => _save(context),
                        icon: const Icon(Icons.save),
                        label: const Text('Save Custom DNS', style: TextStyle(fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Your Saved Custom DNS:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: provider.customDnsList.isEmpty 
                  ? const Center(child: Text('No custom DNS added yet.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: provider.customDnsList.length,
                      itemBuilder: (context, index) {
                        final dns = provider.customDnsList[index];
                        final pingColor = provider.getIndividualPingColor(dns.id);
                        final pingResult = provider.individualPings[dns.id] ?? 'Test Ping';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: const Color(0xFF161824),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFF6318FF),
                                  child: Icon(Icons.dns_rounded, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(dns.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text('${dns.primary} / ${dns.secondary}', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                // Ping Button
                                InkWell(
                                  onTap: () => provider.checkIndividualPing(dns),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: pingColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: pingColor.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.speed_rounded, size: 14, color: pingColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          pingResult,
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pingColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  tooltip: 'Delete',
                                  onPressed: () => provider.removeCustomDns(dns),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
