import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import 'customer_signup_screen.dart';
import 'login_screen.dart';
import 'technician_signup_screen.dart';

class RoleAuthScreen extends StatelessWidget {
  const RoleAuthScreen({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isCustomer = role == UserRole.customer;
    return Scaffold(
      appBar: AppBar(
        title: Text(isCustomer ? 'Customer' : 'Technician'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(
              isCustomer ? Icons.person_outline : Icons.engineering,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isCustomer ? 'Customer account' : 'Technician account',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
              ),
              icon: const Icon(Icons.login),
              label: Text('${role.label} Login'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isCustomer
                      ? const CustomerSignupScreen()
                      : const TechnicianSignupScreen(),
                ),
              ),
              icon: const Icon(Icons.person_add),
              label: Text('${role.label} Sign Up'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
