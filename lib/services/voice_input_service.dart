import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Device speech-to-text for English + spoken Urdu (as Roman Urdu).
///
/// Android often marks the *first word* as a final result and stops. We keep
/// a listen session open, stitch chunks, and only commit after ~3s of silence
/// or when the user taps the mic to stop.
class VoiceInputService {
  VoiceInputService() : _speech = SpeechToText();

  final SpeechToText _speech;

  bool _initialized = false;
  String? _initError;
  String? _englishLocale;
  String? _urduLocale;
  String? _activeLocale;
  
  String _completedChunks = '';
  String _sessionBuffer = '';
  String get _buffer => (_completedChunks.isEmpty ? _sessionBuffer : '$_completedChunks $_sessionBuffer').trim();
  
  bool _finalEmitted = false;
  bool _triedUrduFallback = false;
  bool _sessionActive = false;
  bool _restarting = false;
  int _emptyRestarts = 0;
  DateTime? _sessionStart;
  Timer? _silenceTimer;

  void Function(String partial)? onPartial;
  void Function(String finalText)? onFinal;
  void Function(String message)? onError;
  void Function(bool listening)? onListeningChanged;

  bool get isAvailable => _initialized && _speech.isAvailable;
  bool get isListening => _sessionActive || _speech.isListening;
  String? get initError => _initError;
  String? get activeLocale => _activeLocale;
  String get lastHeard => _buffer;

  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;

    _initialized = await _speech.initialize(
      onStatus: (status) {
        debugPrint('[VoiceInput] status: $status locale=$_activeLocale');
        if (status == 'listening') {
          onListeningChanged?.call(true);
          return;
        }
        if (status != 'done' && status != 'notListening') return;
        if (_restarting) return;
        if (_sessionActive && !_finalEmitted) {
          if (_buffer.trim().isEmpty) {
            _emptyRestarts++;
            if (_emptyRestarts > 4) {
              _sessionActive = false;
              onListeningChanged?.call(false);
              onError?.call(
                  'Could not hear clearly. Please speak again or type your issue.');
              return;
            }
          } else {
            _emptyRestarts = 0;
          }
          _restartListen();
          return;
        }
        if (!_sessionActive) {
          onListeningChanged?.call(false);
          _emitFinalIfNeeded();
        }
      },
      onError: (SpeechRecognitionError error) {
        debugPrint('[VoiceInput] error: ${error.errorMsg} / ${error.permanent}');
        final msg = error.errorMsg.toLowerCase();
        final noSpeech = msg.contains('no_match') ||
            msg.contains('speech_timeout') ||
            msg.contains('error_speech_timeout') ||
            msg.contains('error_no_match');
        if (_buffer.trim().isNotEmpty) {
          _armSilenceTimer();
          if (_sessionActive) _restartListen();
          return;
        }
        if (noSpeech &&
            _sessionActive &&
            !_triedUrduFallback &&
            _urduLocale != null) {
          _triedUrduFallback = true;
          _retryWithUrdu();
          return;
        }
        if (_sessionActive && noSpeech) {
          _restartListen();
          return;
        }
        _sessionActive = false;
        onListeningChanged?.call(false);
        onError?.call(_friendlySpeechError(error));
      },
      debugLogging: kDebugMode,
    );

    if (!_initialized) {
      _initError = 'Speech recognition is not supported on this device.';
      return false;
    }

    await _pickLocales();
    _initError = null;
    return true;
  }

  Future<void> _pickLocales() async {
    final locales = await _speech.locales();
    String norm(String id) => id.replaceAll('-', '_').toLowerCase();

    const englishPref = ['en_us', 'en_gb', 'en_au', 'en_in', 'en_pk'];
    for (final pref in englishPref) {
      for (final l in locales) {
        if (norm(l.localeId) == pref) {
          _englishLocale = l.localeId;
          break;
        }
      }
      if (_englishLocale != null) break;
    }
    _englishLocale ??= () {
      for (final l in locales) {
        if (norm(l.localeId).startsWith('en_')) return l.localeId;
      }
      return 'en_US';
    }();

    for (final pref in ['ur_pk', 'ur_in', 'ur']) {
      for (final l in locales) {
        if (norm(l.localeId) == pref || norm(l.localeId).startsWith('ur')) {
          _urduLocale = l.localeId;
          break;
        }
      }
      if (_urduLocale != null) break;
    }

    _activeLocale = _englishLocale;
  }

  Future<void> _retryWithUrdu() async {
    final urdu = _urduLocale;
    if (urdu == null || !_sessionActive) return;
    _restarting = true;
    try {
      await _speech.stop();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _restarting = false;
    if (!_sessionActive || _finalEmitted) return;
    await _listenWith(urdu);
  }

  Future<bool> startListening() async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        onError?.call(_initError ?? 'Voice input unavailable.');
        return false;
      }
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      onError?.call('Microphone permission is required. Enable it in Settings.');
      return false;
    }

    _silenceTimer?.cancel();
    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }

    _completedChunks = '';
    _sessionBuffer = '';
    _finalEmitted = false;
    _triedUrduFallback = false;
    _restarting = false;
    _emptyRestarts = 0;
    _sessionActive = true;
    _sessionStart = DateTime.now();
    onListeningChanged?.call(true);

    return _listenWith(_englishLocale ?? 'en_US');
  }

  void _commitCurrentSessionBuffer() {
    if (_sessionBuffer.trim().isNotEmpty) {
      if (_completedChunks.isEmpty) {
        _completedChunks = _sessionBuffer.trim();
      } else {
        _completedChunks = '$_completedChunks ${_sessionBuffer.trim()}';
      }
      _sessionBuffer = '';
    }
  }

  Future<void> _restartListen() async {
    if (!_sessionActive || _finalEmitted || _restarting) return;
    final started = _sessionStart;
    if (started != null &&
        DateTime.now().difference(started) > const Duration(seconds: 50)) {
      await _commitSession();
      return;
    }
    _commitCurrentSessionBuffer();
    _restarting = true;
    try {
      await _speech.stop();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _restarting = false;
    if (!_sessionActive || _finalEmitted) return;
    await _listenWith(_activeLocale ?? _englishLocale ?? 'en_US');
  }

  Future<bool> _listenWith(String locale) async {
    _activeLocale = locale;
    final options = SpeechListenOptions(
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      autoPunctuation: false,
      enableHapticFeedback: false,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      localeId: locale,
    );

    await _speech.listen(
      onResult: _handleResult,
      listenOptions: options,
    );

    return _speech.isListening || _sessionActive;
  }

  void _handleResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;

    _sessionBuffer = text;

    onPartial?.call(_buffer);
    _armSilenceTimer();
  }

  void _armSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(milliseconds: 4500), () {
      if (!_sessionActive || _finalEmitted) return;
      if (_buffer.trim().isEmpty) return;
      _commitSession();
    });
  }

  Future<void> _commitSession() async {
    if (_finalEmitted) return;
    _sessionActive = false;
    _silenceTimer?.cancel();
    try {
      await _speech.stop();
    } catch (_) {}
    onListeningChanged?.call(false);
    _emitFinalIfNeeded();
  }

  void _emitFinalIfNeeded() {
    if (_finalEmitted) return;
    final text = _buffer.trim();
    if (text.isEmpty) return;
    _finalEmitted = true;
    onFinal?.call(text);
  }

  Future<String?> stopListening() async {
    await _commitSession();
    final text = _buffer.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> cancel() async {
    _sessionActive = false;
    _silenceTimer?.cancel();
    _completedChunks = '';
    _sessionBuffer = '';
    _finalEmitted = true;
    try {
      await _speech.cancel();
    } catch (_) {}
    onListeningChanged?.call(false);
  }

  String _friendlySpeechError(SpeechRecognitionError error) {
    final msg = error.errorMsg.toLowerCase();
    if (msg.contains('network') || msg.contains('error_network')) {
      return 'Voice needs internet on this device. Check connection or type instead.';
    }
    if (msg.contains('no_match') || msg.contains('speech_timeout')) {
      return 'Could not hear clearly. Please speak again or type your issue.';
    }
    if (msg.contains('not_authorized') || msg.contains('permission')) {
      return 'Microphone access denied. Allow mic permission in phone Settings.';
    }
    if (msg.contains('busy')) {
      return 'Microphone is busy. Close other apps using mic and try again.';
    }
    return 'Voice input failed. Please type your problem instead.';
  }

  void dispose() {
    _sessionActive = false;
    _silenceTimer?.cancel();
    _speech.stop();
  }
}
