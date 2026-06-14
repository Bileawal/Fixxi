import 'package:flutter/material.dart';

import '../../models/service_request.dart';

class TrackLocationScreen extends StatelessWidget {
  const TrackLocationScreen({
    super.key,
    required this.request,
    required this.trackingTechnician,
  });

  final ServiceRequest request;
  final bool trackingTechnician;

  @override
  Widget build(BuildContext context) {
    final title = trackingTechnician ? 'Track Technician' : 'Customer Location';
    final person = trackingTechnician
        ? request.technicianName ?? 'Technician'
        : request.customerName;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: CustomPaint(
              painter: _MapGridPainter(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
              size: Size.infinite,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  '$person is on the way',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Demo map — live GPS integration coming later',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _TrackRow(label: 'Distance', value: '~${request.distanceKm.toStringAsFixed(1)} km'),
                        _TrackRow(label: 'ETA', value: '~12 min'),
                        _TrackRow(label: 'Status', value: request.status.name),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 40.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
