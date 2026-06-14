import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';

class TechnicianRejectedScreen extends StatelessWidget {
  const TechnicianRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reason = context.watch<AppState>().technicianProfile?.rejectionReason;

    return Scaffold(
      appBar: AppBar(title: const Text('Application Rejected')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            Text(
              'Your application was rejected',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (reason != null) ...[
              const SizedBox(height: 12),
              Text(reason, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () async {
                await context.read<AppState>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                }
              },
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}
