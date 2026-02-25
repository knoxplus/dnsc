import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/dns_provider.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String _searchQuery = '';
  String _selectedTag = 'All';
  final List<String> _availableTags = ['All', 'Gaming', 'Web', 'Download', 'Ad-Block'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DnsProvider>().fetchExploreDns();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DnsProvider>();
    
    // Filter Logic
    final filteredList = provider.exploreList.where((dns) {
      final matchesSearch = dns.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            dns.primary.contains(_searchQuery);
      final matchesTag = _selectedTag == 'All' || dns.tags.contains(_selectedTag);
      return matchesSearch && matchesTag;
    }).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: DragToMoveArea(
          child: AppBar(
            title: const Text('Explore Public DNS'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh List',
                onPressed: () => provider.fetchExploreDns(),
              )
            ],
          ),
        ),
      ),
      body: provider.isLoadingExplore
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : Column(
              children: [
                // Search & Filter Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search by name or IP...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF161824),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tag Chips
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableTags.length,
                          itemBuilder: (context, index) {
                            final tag = _availableTags[index];
                            final isSelected = _selectedTag == tag;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(tag, style: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade400)),
                                selected: isSelected,
                                selectedColor: const Color(0xFF6318FF),
                                backgroundColor: const Color(0xFF161824),
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedTag = tag);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // DNS List
                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(child: Text('No DNS matches found', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final dns = filteredList[index];
                            final pingColor = provider.getIndividualPingColor(dns.id);
                            final pingResult = provider.individualPings[dns.id] ?? 'Test Ping';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: const Color(0xFF1A1C29),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const CircleAvatar(
                                          backgroundColor: Color(0xFF6318FF),
                                          child: Icon(Icons.language_rounded, color: Colors.white, size: 20),
                                        ),
                                        const SizedBox(width: 12),
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
                                        // Action Buttons
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
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
                                            // Add Button
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.blueAccent),
                                              tooltip: 'Add to local DNS',
                                              onPressed: () async {
                                                final added = await provider.addCustomDns(dns);
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(added ? '${dns.name} added to local list!' : '${dns.name} is already in the list!'),
                                                      backgroundColor: added ? null : Colors.redAccent,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Tags Row
                                    if (dns.tags.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12.0),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: dns.tags.map((tag) {
                                            Color tagColor;
                                            switch (tag) {
                                              case 'Gaming': tagColor = Colors.purpleAccent; break;
                                              case 'Web': tagColor = Colors.lightBlueAccent; break;
                                              case 'Download': tagColor = Colors.greenAccent; break;
                                              case 'Ad-Block': tagColor = Colors.redAccent; break;
                                              default: tagColor = Colors.grey;
                                            }
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: tagColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: tagColor.withOpacity(0.3)),
                                              ),
                                              child: Text(tag, style: TextStyle(fontSize: 11, color: tagColor, fontWeight: FontWeight.w600)),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
