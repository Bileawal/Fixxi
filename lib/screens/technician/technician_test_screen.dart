import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/technician_profile.dart';
import '../../providers/app_state.dart';

class TechnicianTestScreen extends StatefulWidget {
  const TechnicianTestScreen({super.key});

  @override
  State<TechnicianTestScreen> createState() => _TechnicianTestScreenState();
}

class _TechnicianTestScreenState extends State<TechnicianTestScreen> {
  List<Map<String, dynamic>> _questions = [];
  final Map<String, int> _answers = {};
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final qs = await context.read<AppState>().api.getTestQuestions();
      setState(() {
        _questions = qs;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer all questions')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final app = context.read<AppState>();
      final payload = _answers.entries
          .map((e) => {'questionId': e.key, 'optionIndex': e.value})
          .toList();
      final res = await app.api.submitTest(payload);
      final profileJson = res['technicianProfile'] as Map<String, dynamic>;
      app.updateTechnicianProfile(TechnicianProfile.fromJson(profileJson));

      if (!mounted) return;
      final passed = res['passed'] as bool? ?? false;
      final score = res['score'];
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(passed ? 'Passed!' : 'Failed'),
          content: Text('Your score: $score%'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (passed) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Skill Verification Test')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questions.length,
              itemBuilder: (context, i) {
                final q = _questions[i];
                final id = q['id'] as String;
                final options = (q['options'] as List).cast<String>();
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ${q['question']}',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ...List.generate(options.length, (oi) {
                          return RadioListTile<int>(
                            title: Text(options[oi]),
                            value: oi,
                            groupValue: _answers[id],
                            onChanged: (v) => setState(() => _answers[id] = v!),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Test'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
