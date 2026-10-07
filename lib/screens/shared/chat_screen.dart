import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/chat_message.dart';
import '../../models/service_request.dart';
import '../../providers/app_state.dart';
import '../../services/cloudinary_service.dart';
import 'audio_player_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.request});

  final ServiceRequest request;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;

  // Voice note states
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isUploadingAudio = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final app = context.read<AppState>();
      final msgs = await app.api.getMessages(
        widget.request.id,
        app.currentUser!.id,
      );
      if (mounted) {
        setState(() {
          _messages = msgs;
          _loading = false;
        });
        // Scroll to bottom after loading
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    try {
      await context.read<AppState>().api.sendMessage(widget.request.id, text);
      _ctrl.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _uploadAndSendAudio(File(path));
      }
    } else {
      // Check permissions and start recording
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() => _isRecording = true);
    }
  }

  Future<void> _uploadAndSendAudio(File file) async {
    setState(() => _isUploadingAudio = true);
    try {
      final app = context.read<AppState>();
      final cloudinary = CloudinaryService();
      final url = await cloudinary.uploadAudio(
        file,
        folder: 'chat_audio',
        fileName: 'audio_${DateTime.now().millisecondsSinceEpoch}',
      );

      await app.api.sendMessage(widget.request.id, '🎤 Voice note', audioUrl: url);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send audio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          app.isCustomer
              ? widget.request.technicianName ?? 'Chat'
              : widget.request.customerName,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: m.isMe
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: m.audioUrl != null && m.audioUrl!.isNotEmpty
                              ? AudioPlayerWidget(url: m.audioUrl!, isMe: m.isMe)
                              : Text(m.text),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  if (_isUploadingAudio)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (_isRecording)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic, color: Theme.of(context).colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Text(
                              'Recording...',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendText(),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (!_isRecording && !_isUploadingAudio)
                    IconButton.filledTonal(
                      onPressed: _toggleRecording,
                      icon: const Icon(Icons.mic),
                    ),
                  if (_isRecording)
                    IconButton.filled(
                      onPressed: _toggleRecording,
                      icon: const Icon(Icons.stop),
                      style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                    )
                  else if (!_isUploadingAudio)
                    IconButton.filled(
                      onPressed: _sendText,
                      icon: const Icon(Icons.send),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
