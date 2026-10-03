import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/common_views.dart';
import 'item_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String? _type; // lost | found
  String? _category;
  String? _status;

  List<Item> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<ItemProvider>();
    final items = await provider.fetchItems(filters: {
      'q': _searchCtrl.text.trim(),
      'type': _type,
      'category': _category,
      'status': _status,
      'limit': '50',
    });
    if (!mounted) return;
    setState(() {
      _results = items;
      _error = provider.error;
      _loading = false;
      _searched = true;
    });
  }

  void _reset() {
    _searchCtrl.clear();
    setState(() {
      _type = null;
      _category = null;
      _status = null;
    });
    _run();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _run(),
                decoration: InputDecoration(
                  hintText: 'Search by title, description or category',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _run),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterMenu(
                      label: _type ?? 'Type',
                      icon: Icons.swap_vert,
                      items: const {'lost': 'Lost', 'found': 'Found'},
                      value: _type,
                      onChanged: (v) => setState(() => _type = v),
                    ),
                    const SizedBox(width: 8),
                    _FilterMenu(
                      label: _category ?? 'Category',
                      icon: Icons.category_outlined,
                      items: {
                        for (final c in AppConfig.itemCategories) c: c,
                      },
                      value: _category,
                      onChanged: (v) => setState(() => _category = v),
                    ),
                    const SizedBox(width: 8),
                    _FilterMenu(
                      label: _status ?? 'Status',
                      icon: Icons.flag_outlined,
                      items: const {
                        'active': 'Active',
                        'matched': 'Matched',
                        'claimed': 'Claimed',
                        'verified': 'Verified',
                        'returned': 'Returned',
                      },
                      value: _status,
                      onChanged: (v) => setState(() => _status = v),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.clear, size: 18),
                      label: const Text('Reset'),
                      onPressed: _reset,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _run)
                  : _results.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off,
                          title: _searched ? 'No items found' : 'Search items',
                          subtitle: _searched
                              ? 'Try different keywords or filters.'
                              : 'Use the search box and filters above.',
                        )
                      : RefreshIndicator(
                          onRefresh: _run,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length + 1,
                            itemBuilder: (context, i) {
                              if (i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${_results.length} result${_results.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                        color: Colors.grey.shade600),
                                  ),
                                );
                              }
                              final item = _results[i - 1];
                              return ItemCard(
                                item: item,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => ItemDetailsScreen(
                                              itemId: item.id)));
                                  _run();
                                },
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }
}

class _FilterMenu extends StatelessWidget {
  final String label;
  final IconData icon;
  final Map<String, String> items;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _FilterMenu({
    required this.label,
    required this.icon,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = value != null;
    return PopupMenuButton<String>(
      onSelected: (v) => onChanged(v == value ? null : v),
      offset: const Offset(0, 44),
      itemBuilder: (_) => items.entries
          .map((e) => PopupMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    if (value == e.key)
                      const Icon(Icons.check, size: 18)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(e.value[0].toUpperCase() + e.value.substring(1)),
                  ],
                ),
              ))
          .toList(),
      child: Chip(
        avatar: Icon(icon, size: 18,
            color: active ? Theme.of(context).colorScheme.primary : null),
        label: Text(label[0].toUpperCase() + label.substring(1)),
        backgroundColor: active
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        side: BorderSide(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300),
      ),
    );
  }
}
