import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_request.dart';
import '../../providers/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../shared/chat_screen.dart';
import '../shared/track_location_screen.dart';
import 'review_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requests.isEmpty) {
      return const Center(child: Text('No service requests yet'));
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
                      Expanded(
                        child: Text(request.category,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      StatusChip(label: formatStatus(status), color: statusColor(status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(request.description),
                  if (request.technicianName != null)
                    Text('Technician: ${request.technicianName}'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (request.isActive)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrackLocationScreen(
                                request: request,
                                trackingTechnician: true,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Track'),
                        ),
                      if (request.technicianId != null)
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
                      if (request.status == RequestStatus.completed)
                        FilledButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewScreen(request: request),
                              ),
                            );
                            _load();
                          },
                          icon: const Icon(Icons.star, size: 18),
                          label: const Text('Rate'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
