import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/claim.dart';
import '../providers/admin_provider.dart';
import '../widgets/status_chip.dart';
import '../widgets/common_views.dart';
import 'admin_claim_details_screen.dart';

/// Screen 18: Admin list of claims with a status filter.
class AdminClaimsScreen extends StatefulWidget {
  const AdminClaimsScreen({super.key});

  @override
  State<AdminClaimsScreen> createState() => _AdminClaimsScreenState();
}

class _AdminClaimsScreenState extends State<AdminClaimsScreen> {
  String? _filter; // null = all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<AdminProvider>().fetchClaims(status: _filter);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final claims = provider.claims;

    return Scaffold(
      appBar: AppBar(title: const Text('Claims Review')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('All', null),
                  _chip('Pending', 'pending'),
                  _chip('Approved', 'approved'),
                  _chip('Rejected', 'rejected'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: provider.loading
                ? const LoadingView()
                : provider.error != null && claims.isEmpty
                    ? ErrorView(message: provider.error!, onRetry: _load)
                    : claims.isEmpty
                        ? const EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'No claims',
                            subtitle: 'No claims match this filter.',
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: claims.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) =>
                                  _ClaimTile(claim: claims[i], onDone: _load),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filter = value);
          _load();
        },
      ),
    );
  }
}

class _ClaimTile extends StatelessWidget {
  final Claim claim;
  final VoidCallback onDone;
  const _ClaimTile({required this.claim, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AdminClaimDetailsScreen(claimId: claim.id)));
          onDone();
        },
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          child: const Icon(Icons.assignment_outlined),
        ),
        title: Text(claim.item?.title ?? 'Item',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('by ${claim.claimant?.name ?? 'user'} • '
                '${DateFormat('MMM d, y').format(claim.createdAt)}'),
          ],
        ),
        trailing: StatusChip(status: claim.status),
      ),
    );
  }
}
