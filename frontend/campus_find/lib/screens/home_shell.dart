import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'dashboard_screen.dart';
import 'search_screen.dart';
import 'my_cases_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'report_item_screen.dart';

/// Student/staff home: bottom navigation between the main sections.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    SearchScreen(),
    MyCasesScreen(),
    NotificationsScreen(embedded: true),
    ProfileScreen(embedded: true),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetch();
    });
  }

  void _openReportChooser() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('What would you like to report?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred,
                  color: Color(0xFFC62828)),
              title: const Text('Report a Lost item'),
              subtitle: const Text('I lost something on campus'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ReportItemScreen(type: 'lost')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF00695C)),
              title: const Text('Report a Found item'),
              subtitle: const Text('I found something on campus'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ReportItemScreen(type: 'found')));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unread;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(_index, user?.name)),
        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none),
                  Positioned(
                    right: 0,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$unread',
                        style: const TextStyle(fontSize: 9, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReportChooser,
        icon: const Icon(Icons.add),
        label: const Text('Report'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'My Cases'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }

  String _titleFor(int index, String? name) {
    switch (index) {
      case 0:
        final firstName = (name ?? 'there').split(' ').first;
        return 'Hi, $firstName';
      case 1:
        return 'Search items';
      case 2:
        return 'My cases';
      case 3:
        return 'Notifications';
      case 4:
        return 'Profile';
      default:
        return 'CampusFind';
    }
  }
}
