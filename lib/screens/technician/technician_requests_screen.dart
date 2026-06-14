import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../shared/chat_screen.dart';
import '../shared/track_location_screen.dart';

class TechnicianRequestsScreen extends StatefulWidget {
  const TechnicianRequestsScreen({super.key});

  @override
  State<TechnicianRequestsScreen> createState() => _TechnicianRequestsScreenState();
}

class _TechnicianRequestsScreenState extends State<TechnicianRequestsScreen> {
  List<ServiceRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await context.read<AppState>().api.myRequests();
      setState(() {
        _requests = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await context.read<AppState>().api.updateRequestStatus(id, status);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requests.isEmpty) {
      return const Center(child: Text('No requests yet'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, i) {
          final request = _requests[i];
          final status = request.status.name;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(request.category, style: Theme.of(context).textTheme.titleMedium)),
                      StatusChip(label: formatStatus(status), color: statusColor(status)),
                    ],
                  ),
                  Text('Customer: ${request.customerName}'),
                  Text(request.description),
                  if (request.status == RequestStatus.pending) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(request.id, 'rejected'),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _updateStatus(request.id, 'accepted'),
                            child: const Text('Accept'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (request.isActive) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrackLocationScreen(
                                request: request,
                                trackingTechnician: false,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Customer'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(request: request),
                            ),
                          ),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Chat'),
                        ),
                        if (request.status == RequestStatus.accepted)
                          FilledButton(
                            onPressed: () => _updateStatus(request.id, 'inProgress'),
                            child: const Text('Start'),
                          ),
                        if (request.status == RequestStatus.inProgress)
                          FilledButton(
                            onPressed: () => _updateStatus(request.id, 'completed'),
                            child: const Text('Done'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
