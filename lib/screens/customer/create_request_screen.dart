import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/app_user.dart';
import '../../models/service_request.dart';
import '../../providers/app_state.dart';
import 'select_technician_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({
    super.key,
    this.preselectedTechnician,
    this.initialCategory,
    this.initialDescription,
    this.initialType,
  });

  final AppUser? preselectedTechnician;
  final String? initialCategory;
  final String? initialDescription;
  final RequestType? initialType;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  String _category = AppConstants.categories.first;
  RequestType _type = RequestType.urgent;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _loading = false;

  bool get _scheduleOnly =>
      widget.preselectedTechnician != null && !widget.preselectedTechnician!.isAvailable;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _category = widget.initialCategory!;
    }
    if (widget.initialDescription != null) {
      _descCtrl.text = widget.initialDescription!;
    }
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
    if (_scheduleOnly) {
      _type = RequestType.scheduled;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      _scheduledDate = date;
      _scheduledTime = time;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == RequestType.scheduled && (_scheduledDate == null || _scheduledTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select date and time for scheduled service')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final app = context.read<AppState>();
      final user = app.currentUser!;

      DateTime? scheduledAt;
      if (_type == RequestType.scheduled && _scheduledDate != null && _scheduledTime != null) {
        scheduledAt = DateTime(
          _scheduledDate!.year,
          _scheduledDate!.month,
          _scheduledDate!.day,
          _scheduledTime!.hour,
          _scheduledTime!.minute,
        );
      }

      final body = {
        'category': _category,
        'description': _descCtrl.text.trim(),
        'type': _type.name,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
        'address': user.address,
        if (widget.preselectedTechnician != null)
          'technicianId': widget.preselectedTechnician!.id,
      };

      if (widget.preselectedTechnician != null) {
        await app.api.createRequest(body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request sent to ${widget.preselectedTechnician!.name}')),
        );
        Navigator.pop(context);
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SelectTechnicianScreen(
            requestBody: body,
            isUrgent: _type == RequestType.urgent,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_scheduleOnly)
                Card(
                  color: Colors.orange.shade100,
                  child: ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.orange),
                    title: Text('${widget.preselectedTechnician!.name} is offline'),
                    subtitle: const Text('Only scheduled booking is available (no urgent).'),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Problem category'),
                items: AppConstants.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe the problem',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.trim().length < 10 ? 'Min 10 characters' : null,
              ),
              const SizedBox(height: 20),
              if (_scheduleOnly)
                SegmentedButton<RequestType>(
                  segments: const [
                    ButtonSegment(
                      value: RequestType.scheduled,
                      label: Text('Scheduled'),
                      icon: Icon(Icons.calendar_month),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (_) {},
                )
              else
                SegmentedButton<RequestType>(
                  segments: const [
                    ButtonSegment(value: RequestType.urgent, label: Text('Urgent'), icon: Icon(Icons.flash_on)),
                    ButtonSegment(value: RequestType.scheduled, label: Text('Scheduled'), icon: Icon(Icons.calendar_month)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
              if (_type == RequestType.scheduled) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickSchedule,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    _scheduledDate == null
                        ? 'Pick date & time'
                        : DateFormat('EEE, MMM d • hh:mm a').format(
                            DateTime(
                              _scheduledDate!.year,
                              _scheduledDate!.month,
                              _scheduledDate!.day,
                              _scheduledTime!.hour,
                              _scheduledTime!.minute,
                            ),
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.preselectedTechnician != null ? 'Send Request' : 'Find Technicians'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
