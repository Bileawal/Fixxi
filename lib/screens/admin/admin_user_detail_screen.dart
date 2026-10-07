import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/utils/firestore_helpers.dart';
import '../../providers/app_state.dart';
import '../../services/api_error.dart';

class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _activityFilter = '1 Week';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<AppState>().api.adminGetUserProfile(widget.userId);
      setState(() {
        _data = data;
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

  Future<void> _suspend() async {
    final api = context.read<AppState>().api;
    final reasonCtrl = TextEditingController();
    String duration = 'week';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Suspend account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: duration,
                decoration: const InputDecoration(labelText: 'Duration'),
                items: const [
                  DropdownMenuItem(value: 'week', child: Text('1 Week')),
                  DropdownMenuItem(value: 'month', child: Text('1 Month')),
                  DropdownMenuItem(value: 'permanent', child: Text('Permanent')),
                ],
                onChanged: (v) => setLocal(() => duration = v ?? 'week'),
              ),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Suspend')),
          ],
        ),
      ),
    );
    if (ok != true) {
      reasonCtrl.dispose();
      return;
    }
    try {
      await api.adminSuspendUser(
            widget.userId,
            duration: duration,
            reason: reasonCtrl.text.trim(),
          );
      reasonCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User suspended')),
        );
        _load();
      }
    } catch (e) {
      reasonCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e))),
        );
      }
    }
  }

  Future<void> _unsuspend() async {
    try {
      await context.read<AppState>().api.adminUnsuspendUser(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suspension lifted')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e))),
        );
      }
    }
  }

  Future<void> _notify() async {
    final api = context.read<AppState>().api;
    final titleCtrl = TextEditingController(text: 'Message from Fixxi Admin');
    final bodyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (ok != true || bodyCtrl.text.trim().isEmpty) {
      titleCtrl.dispose();
      bodyCtrl.dispose();
      return;
    }
    try {
      await api.adminNotifyUser(
            widget.userId,
            title: titleCtrl.text.trim(),
            body: bodyCtrl.text.trim(),
          );
      titleCtrl.dispose();
      bodyCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent')),
        );
      }
    } catch (e) {
      titleCtrl.dispose();
      bodyCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e))),
        );
      }
    }
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _requestTile(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? '';
    final type = r['type'] as String? ?? '';
    final created = r['createdAt'];
    final createdLabel = created != null
        ? DateFormat('dd MMM yyyy').format(parseFirestoreDate(created))
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${r['category']} • $status'),
        subtitle: Text(
          'Customer: ${r['customerName'] ?? '?'}\nTechnician: ${r['technicianName'] ?? 'Unassigned'}\n${r['description']}\nType: $type${createdLabel != null ? ' • $createdLabel' : ''}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _reviewTile(Map<String, dynamic> r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('${r['customerName']} • ${r['rating']}★'),
        subtitle: Text(
          'Rs ${r['repairCost'] ?? 0}${r['actualIssue'] != null && (r['actualIssue'] as String).isNotEmpty ? '\nIssue: ${r['actualIssue']}' : ''}${r['comment'] != null && (r['comment'] as String).isNotEmpty ? '\n${r['comment']}' : ''}',
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Not found')),
      );
    }

    final user = _data!['user'] as Map<String, dynamic>;
    final activities = _data!['activities'] as Map<String, dynamic>;
    final allRequests = (activities['requests'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final allReviews = (activities['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final allReportsAgainst =
        (activities['reportsAgainst'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
    DateTime now = DateTime.now();
    DateTime cutoff;
    if (_activityFilter == '1 Week') {
      cutoff = now.subtract(const Duration(days: 7));
    } else if (_activityFilter == '1 Month') {
      cutoff = DateTime(now.year, now.month - 1, now.day);
    } else {
      cutoff = DateTime(now.year - 1, now.month, now.day);
    }

    bool isWithinFilter(dynamic timestamp) {
      if (timestamp == null) return true;
      try {
         final dt = parseFirestoreDate(timestamp);
         return dt.isAfter(cutoff);
      } catch (_) {
         return true;
      }
    }

    final requests = allRequests.where((r) => isWithinFilter(r['createdAt'])).toList();
    final reviews = allReviews.where((r) => isWithinFilter(r['createdAt'])).toList();
    final reportsAgainst = allReportsAgainst.where((r) => isWithinFilter(r['createdAt'])).toList();

    final completed =
        requests.where((r) => r['status'] == 'completed').toList();
    final suspended = user['isSuspendedFlag'] == true || user['isSuspended'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(user['name'] as String? ?? 'Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              value: _activityFilter,
              dropdownColor: Theme.of(context).cardColor,
              underline: const SizedBox(),
              icon: const Icon(Icons.filter_list, color: Colors.white),
              selectedItemBuilder: (BuildContext context) {
                return ['1 Week', '1 Month', '1 Year'].map((String value) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList();
              },
              items: const [
                DropdownMenuItem(value: '1 Week', child: Text('1 Week')),
                DropdownMenuItem(value: '1 Month', child: Text('1 Month')),
                DropdownMenuItem(value: '1 Year', child: Text('1 Year')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _activityFilter = v);
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(user['role'] as String? ?? '').toUpperCase()} Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Email: ${user['email']}'),
                  Text('Phone: ${user['phone']}'),
                  if (user['address'] != null) Text('Address: ${user['address']}'),
                  if (user['role'] == 'technician') ...[
                    Text('Rating: ${user['rating']} (${user['reviewCount']} reviews)'),
                    Text('Available: ${user['isAvailable'] == true ? 'Yes' : 'No (schedule only)'}'),
                  ],
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _notify,
                icon: const Icon(Icons.message),
                label: const Text('Message'),
              ),
              if (suspended)
                OutlinedButton.icon(
                  onPressed: _unsuspend,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('Unsuspend'),
                )
              else
                FilledButton.icon(
                  onPressed: _suspend,
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.block),
                  label: const Text('Suspend'),
                ),
            ],
          ),
          _sectionTitle('All requests (${requests.length})'),
          if (requests.isEmpty)
            const Text('No requests yet')
          else
            ...requests.map(_requestTile),
          _sectionTitle('Completed orders (${completed.length})'),
          if (completed.isEmpty)
            const Text('No completed orders')
          else
            ...completed.map(_requestTile),
          _sectionTitle('Reviews (${reviews.length})'),
          if (reviews.isEmpty)
            const Text('No reviews yet')
          else
            ...reviews.map(_reviewTile),
          _sectionTitle('Reports against user (${reportsAgainst.length})'),
          if (reportsAgainst.isEmpty)
            const Text('No reports')
          else
            ...reportsAgainst.map(
              (r) => ListTile(
                title: Text('By ${r['reporterName']}'),
                subtitle: Text(r['reason'] as String? ?? ''),
              ),
            ),
        ],
      ),
    );
  }
}
