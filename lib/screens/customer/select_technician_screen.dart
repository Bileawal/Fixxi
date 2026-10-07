import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/app_state.dart';
import '../../widgets/common_widgets.dart';

class SelectTechnicianScreen extends StatefulWidget {
  const SelectTechnicianScreen({
    super.key,
    required this.requestBody,
    required this.isUrgent,
  });

  final Map<String, dynamic> requestBody;
  final bool isUrgent;

  @override
  State<SelectTechnicianScreen> createState() => _SelectTechnicianScreenState();
}

class _SelectTechnicianScreenState extends State<SelectTechnicianScreen> {
  List<AppUser> _techs = [];
  bool _loading = true;
  bool _relaxedFilter = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool relaxCategory = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<AppState>().api;
    try {
      var techs = await api.nearbyTechnicians(
            category: relaxCategory ? null : widget.requestBody['category'] as String?,
            urgentOnly: widget.isUrgent,
          );

      if (techs.isEmpty && !relaxCategory) {
        techs = await api.nearbyTechnicians(
              category: null,
              urgentOnly: widget.isUrgent,
            );
        if (techs.isNotEmpty) {
          _relaxedFilter = true;
        }
      }

      if (mounted) {
        setState(() {
          _techs = techs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _send(AppUser tech) async {
    try {
      final body = Map<String, dynamic>.from(widget.requestBody);
      body['technicianId'] = tech.id;
      await context.read<AppState>().api.createRequest(body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request sent to ${tech.name}')),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.requestBody['category'] as String? ?? 'All';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUrgent ? 'Available Technicians' : 'Nearby Technicians'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: () => _load(), child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _techs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              widget.isUrgent
                                  ? 'No available technicians nearby for $category right now.'
                                  : 'No technicians found nearby.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(onPressed: () => _load(relaxCategory: true), child: const Text('Show all nearby')),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_relaxedFilter)
                          MaterialBanner(
                            content: Text('Showing all nearby technicians ($category specialist not found).'),
                            actions: [TextButton(onPressed: () {}, child: const Text('OK'))],
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Text(
                            '${_techs.length} technician${_techs.length == 1 ? '' : 's'} • $category',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _techs.length,
                            itemBuilder: (context, i) {
                              final tech = _techs[i];
                              final dist = tech.distanceKm ?? 0;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(tech.name.isNotEmpty ? tech.name[0].toUpperCase() : '?'),
                                  ),
                                  title: Text(tech.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (tech.skills.isNotEmpty)
                                        Text(tech.skills.join(', '), style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 4),
                                      RatingStars(rating: tech.rating, size: 14),
                                      Text('${dist.toStringAsFixed(1)} km • Check fee Rs ${tech.checkFee ?? 300}'),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: FilledButton(
                                    onPressed: () => _send(tech),
                                    child: const Text('Send'),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
