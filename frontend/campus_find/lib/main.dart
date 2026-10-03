import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/constants.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'providers/claim_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiService();
  final storage = AuthService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: api),
        Provider<AuthService>.value(value: storage),
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(api: api, storage: storage)..restoreSession(),
        ),
        ChangeNotifierProvider(create: (_) => ItemProvider(api: api)),
        ChangeNotifierProvider(create: (_) => ClaimProvider(api: api)),
        ChangeNotifierProvider(create: (_) => AdminProvider(api: api)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(api: api)),
      ],
      child: const CampusFindApp(),
    ),
  );
}

class CampusFindApp extends StatelessWidget {
  const CampusFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootRouter(),
    );
  }
}

/// Chooses the screen based on the current auth status.
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (status == AuthStatus.unknown) {
      return const SplashScreen();
    }
    if (status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    }
    return isAdmin ? const AdminDashboardScreen() : const HomeShell();
  }
}
