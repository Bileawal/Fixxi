import 'package:flutter/material.dart';

class FixxiLogo extends StatelessWidget {
  const FixxiLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(size * 0.22),
          ),
          child: Icon(Icons.home_repair_service, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}

class AiComingSoonButton extends StatelessWidget {
  const AiComingSoonButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.auto_awesome, size: 40, color: Color(0xFF0D9488)),
            title: const Text('AI Diagnosis'),
            content: const Text(
              'AI problem detection and cost estimation is coming soon. '
              'For now, create a service request manually.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.auto_awesome),
      label: const Text('AI'),
      tooltip: 'AI Diagnosis (Coming Soon)',
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 18});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating > i && rating < i + 1;
        return Icon(
          filled
              ? Icons.star
              : half
                  ? Icons.star_half
                  : Icons.star_border,
          size: size,
          color: Colors.amber,
        );
      }),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'accepted':
    case 'inProgress':
      return Colors.blue;
    case 'completed':
      return Colors.green;
    case 'rejected':
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

String formatStatus(String status) {
  if (status == 'inProgress') return 'In Progress';
  return status[0].toUpperCase() + status.substring(1);
}
