import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';

class AdminTechnicianDetailScreen extends StatefulWidget {
  const AdminTechnicianDetailScreen({super.key, required this.profileId});

  final String profileId;

  @override
  State<AdminTechnicianDetailScreen> createState() =>
      _AdminTechnicianDetailScreenState();
}

class _AdminTechnicianDetailScreenState extends State<AdminTechnicianDetailScreen> {
  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppState>().api;
      final data = await api.adminGetTechnician(widget.profileId);
      final messages = await api.adminListMessages(technicianId: widget.profileId);
      setState(() {
        _data = data;
        _messages = messages;
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

  Future<void> _approve() async {
    setState(() => _acting = true);
    try {
      await context.read<AppState>().api.adminApprove(widget.profileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Technician approved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reject() async {
    final api = context.read<AppState>().api;
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject application'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (reason == null) return;

    setState(() => _acting = true);
    try {
      await api.adminReject(widget.profileId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Technician rejected')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _resetTestTries() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset test attempts?'),
        content: const Text(
          'This will reset the technician\'s test tries to 0 and allow them to take the test again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _acting = true);
    try {
      await context.read<AppState>().api.adminResetTestTries(widget.profileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test attempts reset')),
        );
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_data == null) {
      return const Scaffold(body: Center(child: Text('Not found')));
    }

    final user = _data!['user'] as Map<String, dynamic>?;
    final status = _data!['status'] as String?;
    final testScore = _data!['testScore'];
    final testTries = _data!['testTries'] as int? ?? 0;
    final isLocked = status == 'test_locked' || testTries >= 3;

    return Scaffold(
      appBar: AppBar(title: Text(user?['name'] as String? ?? 'Technician')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoTile('Email', user?['email']),
            _InfoTile('Phone', user?['phone']),
            _InfoTile('Address', user?['address']),
            _InfoTile('Father name', user?['fatherName']),
            _InfoTile('Skills', (_data!['skills'] as List?)?.join(', ')),
            _InfoTile('Extra skills', _data!['extraSkills']),
            _InfoTile('Status', status),
            _InfoTile('Test tries', '$testTries / 3'),
            if (testScore != null) _InfoTile('Test score', '$testScore%'),
            if (_data!['rejectionReason'] != null)
              _InfoTile('Rejection reason', _data!['rejectionReason']),
            const SizedBox(height: 16),
            const Text('ID Card - Front', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _IdImage(url: _data!['idCardFrontUrl'] as String?),
            const SizedBox(height: 16),
            const Text('ID Card - Back', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _IdImage(url: _data!['idCardBackUrl'] as String?),
            if (_messages.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Messages from technician', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._messages.map(
                (m) => Card(
                  child: ListTile(
                    title: Text(m['message'] as String? ?? ''),
                    subtitle: Text(m['createdAt']?.toString() ?? ''),
                  ),
                ),
              ),
            ],
            if (isLocked) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _acting ? null : _resetTestTries,
                child: const Text('Reset test attempts'),
              ),
            ],
            if (status == 'pending_admin') ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _acting ? null : _approve,
                child: const Text('Approve'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _acting ? null : _reject,
                child: const Text('Reject'),
              ),
            ],

          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.label, this.value);

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.labelSmall),
      subtitle: Text(value.toString()),
    );
  }
}

class _IdImage extends StatelessWidget {
  const _IdImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('No image')));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => const SizedBox(
          height: 180,
          child: Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }
}
