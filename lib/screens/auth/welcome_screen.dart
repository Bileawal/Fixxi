import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user_role.dart';
import '../../providers/app_state.dart';
import '../../widgets/common_widgets.dart';
import 'admin_login_screen.dart';
import 'role_auth_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Admin login',
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(app.isDark ? Icons.light_mode : Icons.dark_mode),
                    onPressed: () => app.toggleTheme(),
                  ),
                ],
              ),
              const Spacer(),
              const FixxiLogo(size: 96),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Book trusted technicians for home repairs',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              Text(
                'Continue as',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleAuthScreen(role: UserRole.customer),
                    ),
                  ),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Customer'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoleAuthScreen(role: UserRole.technician),
                    ),
                  ),
                  icon: const Icon(Icons.engineering),
                  label: const Text('Technician'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
