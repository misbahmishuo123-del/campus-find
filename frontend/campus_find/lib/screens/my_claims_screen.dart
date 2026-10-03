import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/claim.dart';
import '../providers/claim_provider.dart';
import '../widgets/status_chip.dart';
import '../widgets/common_views.dart';

class MyClaimsScreen extends StatefulWidget {
  final bool embedded;
  const MyClaimsScreen({super.key, this.embedded = false});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  List<Claim> _claims = [];
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
    final provider = context.read<ClaimProvider>();
    final claims = await provider.fetchMyClaims();
    if (!mounted) return;
    setState(() {
      _claims = claims;
      _error = provider.error;
      _loading = false;
    });
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);
    if (_claims.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        title: 'No claims yet',
        subtitle: 'Claims you submit on found items will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _claims.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, i) {
          final c = _claims[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.item?.title ?? 'Item',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      StatusChip(status: c.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Submitted ${DateFormat('MMM d, y • h:mm a').format(c.createdAt)}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text(c.reason,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13)),
                  if (c.verificationMatched != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          c.verificationMatched!
                              ? Icons.verified
                              : Icons.help_center_outlined,
                          size: 16,
                          color: c.verificationMatched!
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          c.verificationMatched!
                              ? 'Verification answer matched'
                              : 'Verification answer did not match',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                  if (c.adminNotes != null && c.adminNotes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Staff note: ${c.adminNotes}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
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
      appBar: AppBar(title: const Text('My Claims')),
      body: _body(),
    );
  }
}
