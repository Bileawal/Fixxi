import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../providers/app_state.dart';
import '../../services/api_error.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/reviews_list_widget.dart';

class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  int _pending = 0;
  int _active = 0;
  List<Review> _reviews = [];
  bool _reviewsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReviews());
  }

  Future<void> _loadReviews() async {
    final techId = context.read<AppState>().currentUser?.id;
    if (techId == null) return;
    try {
      final reviews = await context.read<AppState>().api.getReviews(techId);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _reviewsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _reviewsLoading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final requests = await context.read<AppState>().api.myRequests();
      setState(() {
        _pending = requests.where((r) => r.status.name == 'pending').length;
        _active = requests.where((r) => r.isActive).length;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tech = context.watch<AppState>().currentUser;
    if (tech == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${tech.name.split(' ').first}!',
                    style: Theme.of(context).textTheme.headlineSmall),
                Row(
                  children: [
                    RatingStars(rating: tech.rating),
                    const SizedBox(width: 8),
                    Text('${tech.rating} (${tech.reviewCount} reviews)'),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Availability'),
                  subtitle: Text(
                    tech.isAvailable
                        ? 'Visible for urgent & scheduled jobs'
                        : 'Offline — customers can schedule only',
                  ),
                  value: tech.isAvailable,
                  onChanged: (v) async {
                    final appState = context.read<AppState>();
                    try {
                      await appState.api.setAvailability(v);
                      final me = await appState.api.getMe();
                      appState.updateUser(me.user);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyApiError(e))),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Pending', value: '$_pending', icon: Icons.pending)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: 'Active', value: '$_active', icon: Icons.work)),
          ],
        ),
        const SizedBox(height: 20),
        Text('Your Skills', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 8,
          children: tech.skills.map((s) => Chip(label: Text(s))).toList(),
        ),
        const SizedBox(height: 20),
        Text('My Reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_reviewsLoading)
          const Center(child: CircularProgressIndicator())
        else
          ReviewsListWidget(reviews: _reviews),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    );
  }
}
