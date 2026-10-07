import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/review.dart';
import '../providers/app_state.dart';
import '../services/api_error.dart';
import '../widgets/common_widgets.dart';

class ReviewsListWidget extends StatelessWidget {
  const ReviewsListWidget({
    super.key,
    required this.reviews,
    this.showReportForTechnicianId,
    this.emptyText = 'No reviews yet',
  });

  final List<Review> reviews;
  final String? showReportForTechnicianId;
  final String emptyText;

  Future<void> _report(
    BuildContext context,
    String technicianId, {
    String? reviewId,
  }) async {
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
            labelText: 'Reason for report',
            hintText: 'Describe the issue...',
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
            reportedUserId: technicianId,
            reason: reasonCtrl.text.trim(),
            reviewId: reviewId,
          );
      reasonCtrl.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report sent to admin')),
        );
      }
    } catch (e) {
      reasonCtrl.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Card(child: ListTile(title: Text(emptyText)));
    }

    return Column(
      children: reviews.map((r) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      child: Text(
                        r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : '?',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          RatingStars(rating: r.rating, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
                if (r.actualIssue.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Issue: ${r.actualIssue}', style: Theme.of(context).textTheme.bodySmall),
                ],
                if (r.comment.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(r.comment),
                ],
                if (showReportForTechnicianId != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _report(
                        context,
                        showReportForTechnicianId!,
                        reviewId: r.id,
                      ),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('Report'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
