import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_views.dart';
import 'admin_claims_screen.dart';

/// Screen 17: Admin dashboard with simple statistics cards.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<AdminProvider>().fetchStats());
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  int _dig(Map<String, dynamic>? stats, String a, [String? b]) {
    if (stats == null) return 0;
    if (b == null) return (stats[a] as num?)?.toInt() ?? 0;
    final sub = stats[a] as Map<String, dynamic>?;
    return (sub?[b] as num?)?.toInt() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final user = context.watch<AuthProvider>().user;
    final stats = provider.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: _logout),
        ],
      ),
      body: provider.loading && stats == null
          ? const LoadingView()
          : provider.error != null && stats == null
              ? ErrorView(
                  message: provider.error!,
                  onRetry: () => context.read<AdminProvider>().fetchStats())
              : RefreshIndicator(
                  onRefresh: () => context.read<AdminProvider>().fetchStats(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.8)
                          ]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_moon,
                                color: Colors.white, size: 34),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Welcome, ${user?.name ?? 'Admin'}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text('Campus security overview',
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.85))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Claims',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatCard(
                              label: 'Pending',
                              value: _dig(stats, 'claims', 'pending'),
                              color: const Color(0xFFEF6C00),
                              icon: Icons.hourglass_bottom),
                          const SizedBox(width: 12),
                          _StatCard(
                              label: 'Approved',
                              value: _dig(stats, 'claims', 'approved'),
                              color: const Color(0xFF1B5E20),
                              icon: Icons.check_circle_outline),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(
                              label: 'Rejected',
                              value: _dig(stats, 'claims', 'rejected'),
                              color: const Color(0xFFC62828),
                              icon: Icons.cancel_outlined),
                          const SizedBox(width: 12),
                          _StatCard(
                              label: 'Total',
                              value: _dig(stats, 'claims', 'total'),
                              color: const Color(0xFF283593),
                              icon: Icons.assignment_outlined),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Items',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _StatCard(
                              label: 'Lost',
                              value: _dig(stats, 'items', 'lost'),
                              color: const Color(0xFFC62828),
                              icon: Icons.report_gmailerrorred),
                          const SizedBox(width: 12),
                          _StatCard(
                              label: 'Found',
                              value: _dig(stats, 'items', 'found'),
                              color: const Color(0xFF00695C),
                              icon: Icons.check_circle_outline),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(
                              label: 'Active',
                              value: _dig(stats, 'items', 'active'),
                              color: const Color(0xFFEF6C00),
                              icon: Icons.bolt_outlined),
                          const SizedBox(width: 12),
                          _StatCard(
                              label: 'Returned',
                              value: _dig(stats, 'items', 'returned'),
                              color: const Color(0xFF455A64),
                              icon: Icons.assignment_turned_in_outlined),
                        ],
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AdminClaimsScreen())),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Review claims'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_dig(stats, 'users')} registered users',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text('$value',
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
