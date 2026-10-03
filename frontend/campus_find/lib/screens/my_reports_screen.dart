import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/item_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/common_views.dart';
import 'item_details_screen.dart';
import 'possible_matches_screen.dart';

class MyReportsScreen extends StatefulWidget {
  final bool embedded;
  const MyReportsScreen({super.key, this.embedded = false});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
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
    final items = await provider.fetchMyReports();
    if (!mounted) return;
    setState(() {
      _items = items;
      _error = provider.error;
      _loading = false;
    });
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open,
        title: 'No reports yet',
        subtitle: 'Items you report as lost or found will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return ItemCard(
            item: item,
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ItemDetailsScreen(itemId: item.id)));
              _load();
            },
            trailing: IconButton(
              tooltip: 'Possible matches',
              icon: const Icon(Icons.compare_arrows),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PossibleMatchesScreen(item: item))),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _body();
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: _body(),
    );
  }
}
