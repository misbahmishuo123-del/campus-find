import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../widgets/common_views.dart';
import 'item_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool embedded;
  const NotificationsScreen({super.key, this.embedded = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<NotificationProvider>().fetch());
  }

  IconData _icon(String type) {
    switch (type) {
      case 'match':
        return Icons.compare_arrows;
      case 'claim':
        return Icons.assignment_outlined;
      case 'returned':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'match':
        return const Color(0xFF283593);
      case 'claim':
        return const Color(0xFFEF6C00);
      case 'returned':
        return const Color(0xFF1B5E20);
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _body() {
    final provider = context.watch<NotificationProvider>();
    if (provider.loading && provider.notifications.isEmpty) {
      return const LoadingView();
    }
    if (provider.error != null && provider.notifications.isEmpty) {
      return ErrorView(
          message: provider.error!,
          onRetry: () => context.read<NotificationProvider>().fetch());
    }
    if (provider.notifications.isEmpty) {
      return const EmptyState(
        icon: Icons.notifications_off_outlined,
        title: 'No notifications',
        subtitle: 'Updates about matches and claims will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<NotificationProvider>().fetch(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final n = provider.notifications[i];
          return _NotificationTile(
            notification: n,
            icon: _icon(n.type),
            color: _color(n.type),
            onTap: () async {
              if (!n.read) {
                context.read<NotificationProvider>().markRead(n.id);
              }
              if (n.itemId != null) {
                await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ItemDetailsScreen(itemId: n.itemId!)));
                if (context.mounted) {
                  context.read<NotificationProvider>().fetch();
                }
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    if (widget.embedded) {
      return Stack(
        children: [
          _body(),
          if (provider.unread > 0)
            Positioned(
              right: 16,
              bottom: 84,
              child: FloatingActionButton.small(
                heroTag: 'markAllRead',
                onPressed: () =>
                    context.read<NotificationProvider>().markAllRead(),
                tooltip: 'Mark all as read',
                child: const Icon(Icons.done_all),
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unread > 0)
            IconButton(
              tooltip: 'Mark all as read',
              icon: const Icon(Icons.done_all),
              onPressed: () =>
                  context.read<NotificationProvider>().markAllRead(),
            ),
        ],
      ),
      body: _body(),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.read ? Colors.white : color.withOpacity(0.06),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.read ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y • h:mm a').format(notification.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: notification.read
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
      ),
    );
  }
}
