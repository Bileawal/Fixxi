import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/app_state.dart';
import '../../services/api_error.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.request});

  final ServiceRequest request;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _commentCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _issueCtrl = TextEditingController();
  double _rating = 5;
  bool _loading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _costCtrl.dispose();
    _issueCtrl.dispose();
    super.dispose();
  }

  Future<void> _reportTechnician() async {
    final techId = widget.request.technicianId;
    if (techId == null) return;
    
    final api = context.read<AppState>().api;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report technician'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Why are you reporting?',
            hintText: 'Describe the problem...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Report')),
        ],
      ),
    );
    if (ok != true || reasonCtrl.text.trim().isEmpty) {
      reasonCtrl.dispose();
      return;
    }
    try {
      await api.submitReport(
            reportedUserId: techId,
            reason: reasonCtrl.text.trim(),
          );
      reasonCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report sent to admin')),
        );
      }
    } catch (e) {
      reasonCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e))),
        );
      }
    }
  }

  Future<void> _submit() async {
    final techId = widget.request.technicianId;
    if (techId == null) return;

    final cost = double.tryParse(_costCtrl.text.trim());
    if (cost == null || cost < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter total repair cost (Rs)')),
      );
      return;
    }

    if (_issueCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the actual issue')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AppState>().api.addReview(
            technicianId: techId,
            requestId: widget.request.id,
            rating: _rating,
            comment: _commentCtrl.text.trim(),
            repairCost: cost,
            actualIssue: _issueCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Technician'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.red),
            tooltip: 'Report',
            onPressed: _reportTechnician,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How was ${widget.request.technicianName}?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  iconSize: 40,
                  onPressed: () => setState(() => _rating = i + 1.0),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total repair cost (Rs) *',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _issueCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Actual issue *',
                hintText: 'e.g. Leaking pipe under sink',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Review comment (optional)',
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _reportTechnician,
              icon: const Icon(Icons.flag_outlined, color: Colors.red),
              label: const Text(
                'Report',
                style: TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}
