import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'camera_screen.dart';

Future<void> main() async {
  // Flutter binding must be initialised before calling any platform channel.
  WidgetsFlutterBinding.ensureInitialized();

  // Verify at least one camera exists before launching the app.
  final List<CameraDescription> cameras = await availableCameras();
  if (cameras.isEmpty) {
    // No cameras — show an error screen.
    runApp(const _NoCameraApp());
    return;
  }

  runApp(ObstacleDetectorApp(cameras: cameras));
}

class ObstacleDetectorApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const ObstacleDetectorApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Obstacle Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.greenAccent,
          secondary: Colors.amberAccent,
        ),
      ),
      home: CameraScreen(cameras: cameras),
    );
  }
}

// ─── Fallback when no camera hardware is available ─────────────────
class _NoCameraApp extends StatelessWidget {
  const _NoCameraApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No camera available on this device.',
            style: TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
