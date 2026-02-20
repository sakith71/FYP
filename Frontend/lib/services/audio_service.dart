import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;
  bool _isRecording = false;

  // Play beep sound
  Future<void> playBeep() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/beep-06.mp3'));
    } catch (e) {
      debugPrint('Error playing beep: $e');
    }
  }

  // Check and request microphone permission
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }

    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  // Start recording
  Future<bool> startRecording() async {
    try {
      // Check permission first
      final hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        debugPrint('Microphone permission denied');
        return false;
      }

      // Check if recorder can be used
      if (await _audioRecorder.hasPermission()) {
        // Get temporary directory
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _recordingPath = '${directory.path}/hazard_report_$timestamp.m4a';

        // Start recording
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _recordingPath!,
        );

        _isRecording = true;
        debugPrint('Recording started: $_recordingPath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        _isRecording = false;
        debugPrint('Recording stopped: $path');
        return path;
      }
      return null;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  // Check if currently recording
  bool get isRecording => _isRecording;

  // Get recording path
  String? get recordingPath => _recordingPath;

  // Cancel recording (stop and delete file)
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        final path = await stopRecording();
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            debugPrint('Recording cancelled and deleted');
          }
        }
      }
      _recordingPath = null;
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
    }
  }

  // Play recorded audio
  Future<void> playRecording(String path) async {
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      debugPrint('Error playing recording: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
  }
}
