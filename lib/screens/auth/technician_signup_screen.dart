import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/api_error.dart';

class TechnicianSignupScreen extends StatefulWidget {
  const TechnicianSignupScreen({super.key});

  @override
  State<TechnicianSignupScreen> createState() => _TechnicianSignupScreenState();
}

class _TechnicianSignupScreenState extends State<TechnicianSignupScreen> {
  final _picker = ImagePicker();
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _fatherCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _extraSkillsCtrl = TextEditingController();
  final Set<String> _skills = {};
  File? _idFront;
  File? _idBack;
  bool _loading = false;

  static const _skillOptions = ['Plumber', 'Electrician', 'Carpenter'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fatherCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _extraSkillsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickId(bool front) async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) {
      setState(() {
        if (front) {
          _idFront = File(x.path);
        } else {
          _idBack = File(x.path);
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_idFront == null || _idBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload both sides of ID card')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final app = context.read<AppState>();
      final result = await app.api.registerTechnician(
        name: _nameCtrl.text.trim(),
        fatherName: _fatherCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        skills: _skills.toList(),
        extraSkills: _extraSkillsCtrl.text.trim(),
        idCardFront: _idFront!,
        idCardBack: _idBack!,
      );
      app.setSession(result);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _validateStep() {
    switch (_step) {
      case 0:
        return _nameCtrl.text.isNotEmpty &&
            _fatherCtrl.text.isNotEmpty &&
            _addressCtrl.text.isNotEmpty &&
            _phoneCtrl.text.length >= 10 &&
            _emailCtrl.text.contains('@');
      case 1:
        return _skills.isNotEmpty;
      case 2:
        return _idFront != null && _idBack != null;
      case 3:
        final v = _passCtrl.text;
        return v.length >= 8 &&
            v.contains(RegExp(r'[A-Z]')) &&
            v.contains(RegExp(r'[0-9]')) &&
            v.contains(RegExp(r'[^a-zA-Z0-9]'));
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Technician Sign Up (${_step + 1}/4)')),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_step + 1) / 4),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStep(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (!_validateStep()) {
                              if (_step == 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Password must have 8+ chars, 1 capital, 1 number, and 1 special char')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Fill all required fields')),
                                );
                              }
                              return;
                            }
                            if (_step < 3) {
                              setState(() => _step++);
                            } else {
                              _submit();
                            }
                          },
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_step < 3 ? 'Next' : 'Submit & Proceed to Test'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 12),
            TextField(controller: _fatherCtrl, decoration: const InputDecoration(labelText: 'Father name')),
            const SizedBox(height: 12),
            TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select skills'),
            const SizedBox(height: 8),
            ..._skillOptions.map(
              (s) => CheckboxListTile(
                title: Text(s),
                value: _skills.contains(s),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _skills.add(s);
                    } else {
                      _skills.remove(s);
                    }
                  });
                },
              ),
            ),
            TextField(
              controller: _extraSkillsCtrl,
              decoration: const InputDecoration(labelText: 'Extra skills (optional)'),
            ),
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Skill test'),
                subtitle: Text('After completing the sign-up, you will take a skill test. You must pass to be sent for admin approval.'),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            ListTile(
              title: const Text('ID card - Front'),
              trailing: _idFront != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () => _pickId(true),
            ),
            if (_idFront != null) Image.file(_idFront!, height: 120, fit: BoxFit.cover),
            const Divider(),
            ListTile(
              title: const Text('ID card - Back'),
              trailing: _idBack != null ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () => _pickId(false),
            ),
            if (_idBack != null) Image.file(_idBack!, height: 120, fit: BoxFit.cover),
          ],
        );
      default:
        return TextField(
          controller: _passCtrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            helperText: 'Min 8 chars, 1 capital, 1 number, 1 special char',
            helperMaxLines: 2,
          ),
        );
    }
  }
}
