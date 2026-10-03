import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/common_views.dart';
import 'item_details_screen.dart';

/// Lists items of a single type. Used for both the "Lost Items" and
/// "Found Items" screens (screens 6 and 7).
class ItemsByTypeScreen extends StatefulWidget {
  final String type; // 'lost' | 'found'
  const ItemsByTypeScreen({super.key, required this.type});

  @override
  State<ItemsByTypeScreen> createState() => _ItemsByTypeScreenState();
}

class _ItemsByTypeScreenState extends State<ItemsByTypeScreen> {
  List<Item> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = context.read<ItemProvider>();
    final items = await provider.fetchItems(filters: {
      'type': widget.type,
      'limit': '50',
    });
    if (!mounted) return;
    setState(() {
      _items = items;
      _error = provider.error;
      _loading = false;
    });
  }

  bool get isLost => widget.type == 'lost';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isLost ? 'Lost Items' : 'Found Items')),
      body: _loading
          ? const LoadingView()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? EmptyState(
                      icon: isLost
                          ? Icons.report_gmailerrorred
                          : Icons.check_circle_outline,
                      title: isLost ? 'No lost items' : 'No found items',
                      subtitle: 'Nothing has been reported in this list yet.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          return ItemCard(
                            item: item,
                            onTap: () async {
                              await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ItemDetailsScreen(itemId: item.id)));
                              _load();
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
