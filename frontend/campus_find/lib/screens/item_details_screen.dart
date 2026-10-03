import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../widgets/status_chip.dart';
import '../widgets/common_views.dart';
import 'possible_matches_screen.dart';
import 'claim_item_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String itemId;
  const ItemDetailsScreen({super.key, required this.itemId});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  Item? _item;
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
    final item = await provider.fetchItem(widget.itemId);
    if (!mounted) return;
    setState(() {
      _item = item;
      _error = item == null ? (provider.error ?? 'Item not found') : null;
      _loading = false;
    });
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final deleted =
        await context.read<ItemProvider>().deleteItem(widget.itemId);
    if (!mounted) return;
    if (deleted) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              context.read<ItemProvider>().error ?? 'Could not delete item')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final item = _item;
    final isOwner = item != null && user != null && item.createdById == user.id;
    final canClaim = item != null &&
        !isOwner &&
        item.status != 'returned' &&
        item.status != 'closed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item details'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _error != null || item == null
              ? ErrorView(message: _error ?? 'Item not found', onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          StatusChip(status: item.type),
                          const SizedBox(width: 8),
                          StatusChip(status: item.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(item.title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${item.category[0].toUpperCase()}${item.category.substring(1)} • Reported ${DateFormat('MMM d, y').format(item.createdAt)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            item.imageUrl!,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      size: 40)),
                            ),
                          ),
                        ),
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                        const SizedBox(height: 16),
                      _InfoCard(title: 'Description', child: Text(item.description)),
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: 'Details',
                        child: Column(
                          children: [
                            _InfoRow(
                                icon: Icons.location_on_outlined,
                                label: 'Location',
                                value: item.location),
                            _InfoRow(
                                icon: Icons.event_outlined,
                                label: 'Date',
                                value:
                                    '${DateFormat('MMM d, y').format(item.date)}${item.time != null ? ' • ${item.time}' : ''}'),
                            if (item.color != null && item.color!.isNotEmpty)
                              _InfoRow(
                                  icon: Icons.palette_outlined,
                                  label: 'Color',
                                  value: item.color!),
                            if (item.brand != null && item.brand!.isNotEmpty)
                              _InfoRow(
                                  icon: Icons.label_outline,
                                  label: 'Brand',
                                  value: item.brand!),
                            if (item.status == 'returned' &&
                                item.returnedAt != null)
                              _InfoRow(
                                  icon: Icons.check_circle_outline,
                                  label: 'Returned',
                                  value: DateFormat('MMM d, y')
                                      .format(item.returnedAt!)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (item.createdBy != null)
                        _InfoCard(
                          title: 'Reported by',
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.15),
                                child: Text(
                                  item.createdBy!.name.isNotEmpty
                                      ? item.createdBy!.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.createdBy!.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        '${item.createdBy!.role}${item.createdBy!.department != null ? ' • ${item.createdBy!.department}' : ''}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    PossibleMatchesScreen(item: item))),
                        icon: const Icon(Icons.compare_arrows),
                        label: const Text('View possible matches'),
                      ),
                      const SizedBox(height: 12),
                      if (canClaim)
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ClaimItemScreen(item: item)));
                            _load();
                          },
                          icon: const Icon(Icons.back_hand_outlined),
                          label: const Text('Claim this item'),
                        )
                      else if (isOwner)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'This is your own report. You cannot claim it.',
                                    style: TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
              width: 80,
              child:
                  Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
