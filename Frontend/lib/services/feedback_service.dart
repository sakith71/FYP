import 'package:vibration/vibration.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/feedback_severity.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  final FlutterTts _tts = FlutterTts();

  FeedbackService._internal();

  factory FeedbackService() {
    return _instance;
  }

  Future<void> provideFeedback(FeedbackSeverity severity) async {
    // Trigger vibration
    await _triggerVibration(severity);

    // Provide audio feedback
    await _speakMessage(severity);
  }

  Future<void> _triggerVibration(FeedbackSeverity severity) async {
    try {
      final canVibrate = await Vibration.hasVibrator();
      if (canVibrate == true) {
        final pulseCount = severity.vibrationPulseCount;
        const pulseDuration = 100; // milliseconds
        const pauseDuration = 150; // milliseconds between pulses

        for (int i = 0; i < pulseCount; i++) {
          await Vibration.vibrate(duration: pulseDuration);
          if (i < pulseCount - 1) {
            await Future.delayed(const Duration(milliseconds: pauseDuration));
          }
        }
      }
    } catch (e) {
      print('Error triggering vibration: $e');
    }
  }

  Future<void> _speakMessage(FeedbackSeverity severity) async {
    try {
      await _tts.stop();
      await _tts.speak(severity.audioMessage);
    } catch (e) {
      print('Error speaking message: $e');
    }
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
