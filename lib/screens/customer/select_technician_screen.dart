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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final techs = await context.read<AppState>().api.nearbyTechnicians(
            category: widget.requestBody['category'] as String?,
            urgentOnly: widget.isUrgent,
          );
      setState(() {
        _techs = techs;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      setState(() => _loading = false);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isUrgent ? 'Available technicians' : 'Nearby technicians'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _techs.isEmpty
              ? const Center(child: Text('No technicians found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _techs.length,
                  itemBuilder: (context, i) {
                    final tech = _techs[i];
                    final dist = tech.distanceKm ?? 0;
                    return Card(
                      child: ListTile(
                        title: Text(tech.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RatingStars(rating: tech.rating, size: 14),
                            Text('${dist.toStringAsFixed(1)} km • Rs ${tech.checkFee ?? 300}'),
                          ],
                        ),
                        trailing: FilledButton(
                          onPressed: () => _send(tech),
                          child: const Text('Send'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
