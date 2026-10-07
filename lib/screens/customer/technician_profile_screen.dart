import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/fee_calculator.dart';
import '../../models/app_user.dart';
import '../../models/review.dart';
import '../../providers/app_state.dart';
import '../../services/api_error.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/reviews_list_widget.dart';
import 'create_request_screen.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key, required this.technician});

  final AppUser technician;

  @override
  State<TechnicianProfileScreen> createState() => _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  List<Review> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reviews = await context.read<AppState>().api.getReviews(widget.technician.id);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load reviews: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _reportTechnician() async {
    final api = context.read<AppState>().api;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Report ${widget.technician.name}'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Reason'),
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
            reportedUserId: widget.technician.id,
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

  @override
  Widget build(BuildContext context) {
    final tech = widget.technician;
    final dist = tech.distanceKm ?? 2.5;
    final fee = tech.checkFee ?? checkFeeForDistanceKm(dist);
    final scheduleOnly = !tech.isAvailable;

    return Scaffold(
      appBar: AppBar(
        title: Text(tech.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.red),
            tooltip: 'Report',
            onPressed: _reportTechnician,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (scheduleOnly)
            Card(
              color: Colors.orange.shade100,
              child: const ListTile(
                leading: Icon(Icons.schedule, color: Colors.orange),
                title: Text('Currently offline'),
                subtitle: Text('Urgent booking not available. You can schedule only.'),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(tech.name[0], style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(height: 12),
                  Text(tech.name, style: Theme.of(context).textTheme.headlineSmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RatingStars(rating: tech.rating),
                      const SizedBox(width: 8),
                      Text('${tech.rating} (${tech.reviewCount} reviews)'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: tech.skills
                        .map((s) => Chip(label: Text(s), visualDensity: VisualDensity.compact))
                        .toList(),
                  ),
                  const Divider(height: 28),
                  _InfoRow(icon: Icons.phone, text: tech.phone),
                  _InfoRow(icon: Icons.location_on, text: tech.address ?? 'Lahore'),
                  _InfoRow(icon: Icons.place, text: '${dist.toStringAsFixed(1)} km away'),
                  _InfoRow(icon: Icons.payments, text: 'Rs $fee check fee'),
                  _InfoRow(
                    icon: tech.isAvailable ? Icons.check_circle : Icons.schedule,
                    text: tech.isAvailable ? 'Available now' : 'Schedule only',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Customer Reviews', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
          else
            ReviewsListWidget(
              reviews: _reviews,
              showReportForTechnicianId: tech.id,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateRequestScreen(preselectedTechnician: tech),
              ),
            ),
            icon: Icon(scheduleOnly ? Icons.calendar_month : Icons.send),
            label: Text(scheduleOnly ? 'Schedule Service' : 'Send Service Request'),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
