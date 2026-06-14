import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import 'admin_technician_detail_screen.dart';

class AdminTechnicianListScreen extends StatefulWidget {
  const AdminTechnicianListScreen({
    super.key,
    required this.status,
    required this.title,
  });

  final String? status;
  final String title;

  @override
  State<AdminTechnicianListScreen> createState() => _AdminTechnicianListScreenState();
}

class _AdminTechnicianListScreenState extends State<AdminTechnicianListScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<AppState>().api.adminListTechnicians(
            status: widget.status,
          );
      setState(() {
        _list = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_list.isEmpty) {
      return Center(child: Text('No technicians in ${widget.title}'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _list.length,
        itemBuilder: (context, i) {
          final item = _list[i];
          final user = item['user'] as Map<String, dynamic>?;
          return Card(
            child: ListTile(
              title: Text(user?['name'] as String? ?? 'Technician'),
              subtitle: Text(
                '${(item['skills'] as List?)?.join(', ') ?? ''}\nStatus: ${item['status']}',
              ),
              isThreeLine: true,
              trailing: item['testScore'] != null
                  ? Chip(label: Text('${item['testScore']}%'))
                  : null,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminTechnicianDetailScreen(
                      profileId: item['id'] as String,
                    ),
                  ),
                );
                _load();
              },
            ),
          );
        },
      ),
    );
  }
}
