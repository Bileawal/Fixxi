import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_state.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/customer/customer_shell.dart';
import 'screens/technician/technician_pending_screen.dart';
import 'screens/technician/technician_rejected_screen.dart';
import 'screens/technician/technician_shell.dart';
import 'screens/technician/technician_test_screen.dart';
import 'widgets/common_widgets.dart';

class FixxiApp extends StatelessWidget {
  const FixxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Fixxi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: app.isDark ? ThemeMode.dark : ThemeMode.light,
      home: KeyedSubtree(
        key: ValueKey(app.isLoggedIn ? 'logged-in' : 'logged-out'),
        child: const _RootRouter(),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    if (!app.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FixxiLogo(size: 80),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (!app.isLoggedIn) {
      return const WelcomeScreen();
    }

    if (app.isAdmin) {
      return const AdminShell();
    }

    if (app.isTechnician) {
      final profile = app.technicianProfile;
      if (profile == null || profile.isPendingAdmin) {
        return const TechnicianPendingScreen();
      }
      if (profile.isRejected) {
        return const TechnicianRejectedScreen();
      }
      if (profile.needsTest) {
        return const TechnicianTestScreen();
      }
      return const TechnicianShell();
    }

    return const CustomerShell();
  }
}
