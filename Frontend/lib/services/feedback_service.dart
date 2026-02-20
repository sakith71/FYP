import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/feedback_severity.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  final FlutterTts _tts = FlutterTts();
  bool _isTtsInitialized = false;

  FeedbackService._internal();

  factory FeedbackService() {
    return _instance;
  }

  Future<void> _initTts() async {
    if (_isTtsInitialized) return;
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<void> provideFeedback(FeedbackSeverity severity) async {
    // Run both feedback types concurrently
    await Future.wait([
      _triggerVibration(severity),
      _speakMessage(severity),
    ]);
  }

  Future<void> _triggerVibration(FeedbackSeverity severity) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        final pulseCount = severity.vibrationPulseCount;

        // Construct pattern: [wait, vibrate, wait, vibrate, ...]
        final pattern = <int>[];
        for (int i = 0; i < pulseCount; i++) {
          pattern.add(i == 0 ? 0 : 150); // No wait for first pulse, 150ms for others
          pattern.add(100); // 100ms vibration
        }

        await Vibration.vibrate(pattern: pattern);
      }
    } catch (e) {
      debugPrint('Error triggering vibration: $e');
    }
  }

  Future<void> _speakMessage(FeedbackSeverity severity) async {
    try {
      if (!_isTtsInitialized) {
        await _initTts();
      }
      await _tts.stop();
      await _tts.speak(severity.audioMessage);
    } catch (e) {
      debugPrint('Error speaking message: $e');
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
