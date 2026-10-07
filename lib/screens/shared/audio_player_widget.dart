import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key, required this.url, required this.isMe});

  final String url;
  final bool isMe;

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late final AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _playerStateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
            _isPlaying = false;
          }
        });
      }
    });

    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      setState(() => _isLoading = true);
      try {
        if (_position > Duration.zero && _position < _duration) {
          await _player.resume();
        } else {
          await _player.play(UrlSource(widget.url));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot play audio: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMe
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;

    final maxMs = _duration.inMilliseconds.toDouble();
    final posMs = _position.inMilliseconds
        .toDouble()
        .clamp(0.0, maxMs > 0 ? maxMs : 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play / Pause / Loading button
        SizedBox(
          width: 36,
          height: 36,
          child: _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: color,
                    size: 32,
                  ),
                  onPressed: _togglePlay,
                ),
        ),

        // Slider
        Flexible(
          child: Slider(
            min: 0.0,
            max: maxMs > 0 ? maxMs : 1.0,
            value: posMs,
            activeColor: color,
            inactiveColor: color.withOpacity(0.3),
            onChanged: maxMs > 0
                ? (v) => _player.seek(Duration(milliseconds: v.toInt()))
                : null,
          ),
        ),

        // Duration text
        Text(
          _fmt(_isPlaying || _position > Duration.zero ? _position : _duration),
          style: TextStyle(color: color, fontSize: 11),
        ),
      ],
    );
  }
}
