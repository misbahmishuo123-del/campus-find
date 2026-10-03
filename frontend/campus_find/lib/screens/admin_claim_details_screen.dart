import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/status_chip.dart';
import '../widgets/common_views.dart';
import '../widgets/item_card.dart';
import 'item_details_screen.dart';

/// Screen 19: Admin opens a claim, reviews verification + possible matches,
/// then approves / rejects / marks returned.
class AdminClaimDetailsScreen extends StatefulWidget {
  final String claimId;
  const AdminClaimDetailsScreen({super.key, required this.claimId});

  @override
  State<AdminClaimDetailsScreen> createState() =>
      _AdminClaimDetailsScreenState();
}

class _AdminClaimDetailsScreenState extends State<AdminClaimDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<AdminProvider>().fetchClaimDetail(widget.claimId);
  }

  Future<void> _review(String status) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(status == 'approved' ? 'Approve claim' : 'Reject claim'),
        content: TextField(
          controller: notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes for the claimant (optional)',
            hintText: 'e.g. Verification answer matched the record.',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: status == 'rejected'
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(status == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final provider = context.read<AdminProvider>();
    final ok = await provider.reviewClaim(
      claimId: widget.claimId,
      status: status,
      adminNotes: notesCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Claim $status'
          : (provider.error ?? 'Action failed')),
      backgroundColor: ok ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
    ));
    if (ok) _load();
  }

  Future<void> _markReturned() async {
    final detail = context.read<AdminProvider>().detail;
    final itemId = detail?.claim.itemId;
    if (itemId == null) return;
    final ok = await context.read<AdminProvider>().markReturned(itemId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Item marked as returned'
          : (context.read<AdminProvider>().error ?? 'Action failed')),
      backgroundColor:
          ok ? Colors.green.shade700 : Theme.of(context).colorScheme.error,
    ));
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final detail = provider.detail;

    return Scaffold(
      appBar: AppBar(title: const Text('Claim Details')),
      body: provider.loading && detail == null
          ? const LoadingView()
          : provider.error != null && detail == null
              ? ErrorView(message: provider.error!, onRetry: _load)
              : detail == null
                  ? const EmptyState(
                      icon: Icons.error_outline, title: 'Claim not found')
                  : _buildDetail(context, provider, detail),
    );
  }

  Widget _buildDetail(
      BuildContext context, AdminProvider provider, AdminClaimDetail detail) {
    final claim = detail.claim;
    final item = claim.item;
    final pending = claim.status == 'pending';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('Claim status',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              StatusChip(status: claim.status),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'Item',
            child: item == null
                ? const Text('Item no longer available')
                : Column(
                    children: [
                      ItemCard(
                        item: item,
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    ItemDetailsScreen(itemId: item.id))),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Claimant',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(claim.claimant?.name ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(claim.claimant?.email ?? '',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                if (claim.claimant?.department != null)
                  Text(claim.claimant!.department!,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Reason for claim',
            child: Text(claim.reason),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Verification',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.verificationQuestion != null &&
                    detail.verificationQuestion!.isNotEmpty)
                  Text('Question: ${detail.verificationQuestion}',
                      style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      detail.verificationMatched == true
                          ? Icons.verified
                          : Icons.help_center_outlined,
                      color: detail.verificationMatched == true
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail.verificationMatched == true
                            ? 'The claimant\'s secret answer matched the item record.'
                            : detail.verificationMatched == false
                                ? 'The secret answer did NOT match. Verify manually.'
                                : 'No verification answer was recorded for this item.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (detail.possibleMatches.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Card(
              title: 'Possible matches',
              child: Column(
                children: detail.possibleMatches
                    .map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ItemCard(
                            item: m.item,
                            matchScore: m.score,
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailsScreen(itemId: m.item.id))),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (pending) ...[
            FilledButton.icon(
              onPressed: () => _review('approved'),
              icon: const Icon(Icons.check),
              label: const Text('Approve claim'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error)),
              onPressed: () => _review('rejected'),
              icon: const Icon(Icons.close),
              label: const Text('Reject claim'),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(
                'This claim was ${claim.status} on '
                '${claim.adminNotes != null && claim.adminNotes!.isNotEmpty ? 'with note: ${claim.adminNotes}' : 'review'}.',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          const SizedBox(height: 12),
          if (item != null && item.status != 'returned')
            FilledButton.tonalIcon(
              onPressed: _markReturned,
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Mark item as returned'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

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
