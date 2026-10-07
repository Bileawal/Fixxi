import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated')),
      );
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
    final profile = context.watch<AppState>().technicianProfile;
    final testScore = profile?.testScore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AppState>().logout();
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
              'You have passed the skill test. Your profile, ID documents, and test score '
              'are being reviewed by admin. You will be notified once approved.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (testScore != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.verified, color: Colors.green),
                  title: const Text('Test passed'),
                  subtitle: Text('Your score: ${testScore.round()}%'),
                ),
              ),
            ],
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
