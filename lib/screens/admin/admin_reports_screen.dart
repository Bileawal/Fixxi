import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/api_error.dart';
import 'admin_user_detail_screen.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<AppState>().api.adminListReports(status: 'pending');
      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e))),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _openReport(Map<String, dynamic> report) async {
    final noteCtrl = TextEditingController(text: report['adminNote'] as String? ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('From: ${report['reporterName']}'),
              Text('Against: ${report['reportedUserName']}'),
              const SizedBox(height: 8),
              Text(report['reason'] as String? ?? ''),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Admin note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<AppState>().api.adminUpdateReport(
                    report['id'] as String,
                    status: 'resolved',
                    adminNote: noteCtrl.text.trim(),
                  );
              noteCtrl.dispose();
              if (ctx.mounted) Navigator.pop(ctx);
              _load();
            },
            child: const Text('Resolve'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminUserDetailScreen(
                    userId: report['reportedUserId'] as String,
                  ),
                ),
              );
            },
            child: const Text('View user'),
          ),
        ],
      ),
    );
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reports.isEmpty) {
      return const Center(child: Text('No pending reports'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _reports.length,
        itemBuilder: (context, i) {
          final r = _reports[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.flag, color: Colors.red),
              title: Text('${r['reporterName']} → ${r['reportedUserName']}'),
              subtitle: Text(
                (r['reason'] as String? ?? '').length > 60
                    ? '${(r['reason'] as String).substring(0, 60)}...'
                    : r['reason'] as String? ?? '',
              ),
              onTap: () => _openReport(r),
            ),
          );
        },
      ),
    );
  }
}
