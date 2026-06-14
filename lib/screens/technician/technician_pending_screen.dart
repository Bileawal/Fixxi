import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import 'technician_rejected_screen.dart';
import 'technician_test_screen.dart';

class TechnicianPendingScreen extends StatefulWidget {
  const TechnicianPendingScreen({super.key});

  @override
  State<TechnicianPendingScreen> createState() => _TechnicianPendingScreenState();
}

class _TechnicianPendingScreenState extends State<TechnicianPendingScreen> {
  bool _checking = false;

  Future<void> _refreshStatus() async {
    setState(() => _checking = true);
    try {
      final app = context.read<AppState>();
      final result = await app.api.getMe();
      app.setSession(result);
      if (!mounted) return;
      final profile = result.technicianProfile;
      if (profile == null) return;

      if (profile.isRejected) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TechnicianRejectedScreen()),
        );
      } else if (profile.needsTest) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TechnicianTestScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AppState>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Waiting for admin approval',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your profile and ID documents are being reviewed. '
              'You will be notified once approved to take the skill test.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _checking ? null : _refreshStatus,
              icon: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Check status'),
            ),
          ],
        ),
      ),
    );
  }
}
