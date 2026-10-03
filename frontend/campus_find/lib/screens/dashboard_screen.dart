import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../widgets/item_card.dart';
import '../widgets/common_views.dart';
import 'report_item_screen.dart';
import 'search_screen.dart';
import 'item_details_screen.dart';
import 'items_by_type_screen.dart';
import 'my_reports_screen.dart';
import 'my_claims_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Item> _recent = [];
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
    final items = await context
        .read<ItemProvider>()
        .fetchItems(filters: {'limit': '6'});
    if (!mounted) return;
    setState(() {
      _recent = items;
      _error = context.read<ItemProvider>().error;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomeCard(name: user?.name ?? 'there', role: user?.role ?? ''),
          const SizedBox(height: 16),
          const _SectionTitle('Quick actions'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _ActionTile(
                icon: Icons.search,
                label: 'Search',
                color: const Color(0xFF283593),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              _ActionTile(
                icon: Icons.report_gmailerrorred,
                label: 'Report Lost',
                color: const Color(0xFFC62828),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ReportItemScreen(type: 'lost'))),
              ),
              _ActionTile(
                icon: Icons.check_circle_outline,
                label: 'Report Found',
                color: const Color(0xFF00695C),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ReportItemScreen(type: 'found'))),
              ),
              _ActionTile(
                icon: Icons.folder_outlined,
                label: 'My Reports',
                color: const Color(0xFFEF6C00),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyReportsScreen())),
              ),
              _ActionTile(
                icon: Icons.assignment_outlined,
                label: 'My Claims',
                color: const Color(0xFF6A1B9A),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyClaimsScreen())),
              ),
              _ActionTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                color: const Color(0xFF455A64),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const NotificationsScreen())),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Browse'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ItemsByTypeScreen(type: 'lost'))),
                  icon: const Icon(Icons.report_gmailerrorred,
                      color: Color(0xFFC62828)),
                  label: const Text('Lost items'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ItemsByTypeScreen(type: 'found'))),
                  icon: const Icon(Icons.check_circle_outline,
                      color: Color(0xFF00695C)),
                  label: const Text('Found items'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Recently reported'),
          const SizedBox(height: 4),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: LoadingView(),
            )
          else if (_error != null)
            ErrorView(message: _error!, onRetry: _load)
          else if (_recent.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No items yet',
              subtitle: 'Reported lost and found items will appear here.',
            )
          else
            ..._recent.map((item) => ItemCard(
                  item: item,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ItemDetailsScreen(itemId: item.id)));
                    _load();
                  },
                )),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  final String role;
  const _WelcomeCard({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),
                const SizedBox(height: 2),
                Text(
                  name.split(' ').first,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700));
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
