import 'dart:async';

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
  Timer? _timer;
  int _timeLeftSeconds = 30 * 60;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftSeconds > 0) {
        setState(() {
          _timeLeftSeconds--;
        });
      } else {
        _timer?.cancel();
        if (!_submitting) {
          _submit(autoSubmit: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final profile = context.read<AppState>().technicianProfile;
      final category = profile?.skills.isNotEmpty == true ? profile!.skills.first : null;
      final qs = await context.read<AppState>().api.getTestQuestions(category: category);
      setState(() {
        _questions = qs;
        _loading = false;
      });
      _startTimer();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _submit({bool autoSubmit = false}) async {
    if (_submitting) return;

    if (!autoSubmit && _answers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer all questions')),
      );
      return;
    }

    setState(() => _submitting = true);
    _timer?.cancel();

    try {
      final app = context.read<AppState>();
      final payload = _questions.map((q) {
        final id = q['id'] as String;
        return {
          'questionId': id,
          'optionIndex': _answers[id] ?? 0,
        };
      }).toList();

      final res = await app.api.submitTest(
        payload,
        sessionQuestions: _questions,
      );
      final profileJson = res['technicianProfile'] as Map<String, dynamic>;
      app.updateTechnicianProfile(TechnicianProfile.fromJson(profileJson));

      if (!mounted) return;
      final passed = res['passed'] as bool? ?? false;
      final score = res['score'];
      final msg = res['message'] as String? ?? '';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(passed ? 'Passed!' : 'Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your score: $score%',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(msg),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        _startTimer();
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

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Skill Verification Test')),
        body: const Center(child: Text('No test questions available')),
      );
    }

    final mins = _timeLeftSeconds ~/ 60;
    final secs = _timeLeftSeconds % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Leave test?'),
            content: const Text('Your progress will be lost. Are you sure?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pop();
                },
                child: const Text('Leave'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Skill Verification Test'),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
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
                          Text(
                            '${i + 1}. ${q['question']}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          ...List.generate(options.length, (oi) {
                            return RadioListTile<int>(
                              title: Text(options[oi]),
                              value: oi,
                              groupValue: _answers[id],
                              onChanged: _submitting
                                  ? null
                                  : (v) => setState(() => _answers[id] = v!),
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
                  onPressed: _submitting ? null : () => _submit(autoSubmit: false),
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
      ),
    );
  }
}
