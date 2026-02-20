import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as camera;
import '../widgets/detection_widgets/detection_header.dart';
import '../widgets/detection_widgets/audio_output_card.dart';
import '../widgets/detection_widgets/note_card.dart';
import '../widgets/detection_widgets/camera_preview.dart';
import '../widgets/detection_widgets/gesture_card.dart';
import '../widgets/detection_widgets/feedback_severity_overlay.dart';
import '../models/feedback_severity.dart';
import 'report_hazard_page.dart';
import 'history_logs_page.dart';
import 'error_states_page.dart';
import 'settings_page.dart';

class DetectionActivePage extends StatefulWidget {
  const DetectionActivePage({super.key});

  @override
  State<DetectionActivePage> createState() => _DetectionActivePageState();
}

class _DetectionActivePageState extends State<DetectionActivePage> {
  int tapCount = 0;
  DateTime? lastTapTime;
  camera.CameraController? _cameraController;
  List<camera.CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await camera.availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = camera.CameraController(
          _cameras![0],
          camera.ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void handleTap() {
    final now = DateTime.now();
    if (lastTapTime != null && now.difference(lastTapTime!).inSeconds > 2) {
      tapCount = 0;
    }

    tapCount++;
    lastTapTime = now;

    if (tapCount >= 5) {
      tapCount = 0;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ErrorStatesPage()),
      );
    }
  }

  /// Show feedback based on distance to detected object (in meters)
  void showFeedbackForDistance(double distanceInMeters) {
    final severity = FeedbackSeverity.fromDistance(distanceInMeters);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => FeedbackSeverityOverlay(
        severity: severity,
        objectDistance: distanceInMeters,
        onDismiss: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleTap,
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportHazardPage()),
        );
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -500) {
          // Swipe up - Settings
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        } else if (details.primaryVelocity! > 500) {
          // Swipe down - History
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoryLogsPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.grey[100],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const DetectionHeader(isSuccess: true),
              const SizedBox(height: 16),
              const AudioOutputCard(
                message: '"Obstacle ahead right, two meters."',
              ),
              const SizedBox(height: 16),
              const NoteCard(note: 'Haptic feedback: Double pulse vibration'),
              const SizedBox(height: 24),
              Expanded(child: CameraPreview(controller: _cameraController)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureCard(
                        icon: Icons.swipe_down,
                        title: 'GESTURE',
                        description: 'Swipe DOWN for History',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureCard(
                        icon: Icons.touch_app,
                        title: 'GESTURE',
                        description: 'Tap 5 Times for Error Status',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureCard(
                        icon: Icons.swipe_up,
                        title: 'GESTURE',
                        description: 'Swipe UP for Settings',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureCard(
                        icon: Icons.touch_app,
                        title: 'GESTURE',
                        description: 'Long Press to Report Hazard',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
