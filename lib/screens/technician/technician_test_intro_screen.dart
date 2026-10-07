import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/api_error.dart';
import 'technician_test_screen.dart';

class TechnicianTestIntroScreen extends StatefulWidget {
  const TechnicianTestIntroScreen({super.key});

  @override
  State<TechnicianTestIntroScreen> createState() => _TechnicianTestIntroScreenState();
}

class _TechnicianTestIntroScreenState extends State<TechnicianTestIntroScreen> {
  final _msgCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  void _contactAdmin() {
    _msgCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Admin'),
        content: TextField(
          controller: _msgCtrl,
          decoration: const InputDecoration(
            hintText: 'Type your message to admin here...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: _sending
                ? null
                : () async {
                    final msg = _msgCtrl.text.trim();
                    if (msg.isEmpty) return;
                    setState(() => _sending = true);
                    try {
                      await context.read<AppState>().api.sendAdminMessage(msg);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Message sent to admin.')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyApiError(e))),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _sending = false);
                    }
                  },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final profile = app.technicianProfile;
    final tries = profile?.testTries ?? 0;
    final isLocked = profile?.isTestLocked ?? false;
    final skill = profile?.skills.isNotEmpty == true ? profile!.skills.first : 'your skill';

    return Scaffold(
      appBar: AppBar(title: const Text('Skill Verification')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.assignment_rounded, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Skill Verification Test',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Field: $skill — 10 MCQs (English + Urdu)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.timer),
                      title: Text('30 Minutes'),
                      subtitle: Text('Time limit for the test'),
                    ),
                    ListTile(
                      leading: Icon(Icons.verified),
                      title: Text('80% Passing Score'),
                      subtitle: Text('You need at least 8 out of 10 correct to pass'),
                    ),
                    ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('3 Attempts'),
                      subtitle: Text('Each attempt has different questions'),
                    ),
                    ListTile(
                      leading: Icon(Icons.quiz),
                      title: Text('10 MCQs'),
                      subtitle: Text('5 easy + 5 difficult, related to your field'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Attempts used: $tries / 3',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (profile?.testScore != null && !profile!.isPendingAdmin) ...[
              const SizedBox(height: 8),
              Text(
                'Last score: ${profile.testScore!.round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Spacer(),
            if (isLocked) ...[
              const Text(
                'You have failed 3 times. Contact admin to reset your attempts.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _contactAdmin,
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Contact Admin'),
              ),
            ] else ...[
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TechnicianTestScreen()),
                  );
                },
                child: const Text('Start Test'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                await app.logout();
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
