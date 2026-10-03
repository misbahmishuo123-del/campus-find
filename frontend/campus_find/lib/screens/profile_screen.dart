import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';
import 'my_reports_screen.dart';
import 'my_claims_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AuthProvider>().logout();
    }
  }

  Widget _body(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primary.withOpacity(0.15),
                child: Text(
                  (user?.name.isNotEmpty ?? false)
                      ? user!.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.name ?? '',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(user?.email ?? '',
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text((user?.role ?? '').toUpperCase(),
                    style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (user?.department != null && user!.department!.isNotEmpty)
          _InfoRow(
              icon: Icons.apartment_outlined,
              label: 'Department',
              value: user.department!),
        _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Account type',
            value: (user?.role ?? 'student')),
        const SizedBox(height: 16),
        _MenuTile(
          icon: Icons.folder_outlined,
          label: 'My reports',
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyReportsScreen())),
        ),
        _MenuTile(
          icon: Icons.assignment_outlined,
          label: 'My claims',
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyClaimsScreen())),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error),
          ),
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text('${AppConfig.appName} • v1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (embedded) return _body(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _body(context),
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
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text('$label: ',
              style: TextStyle(color: Colors.grey.shade600)),
          Expanded(
              child: Text(value.isEmpty ? '—' : value,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
