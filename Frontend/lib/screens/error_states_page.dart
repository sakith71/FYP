import 'package:flutter/material.dart';
import '../widgets/error_state_widgets/error_card.dart';
import '../widgets/error_state_widgets/warning_card.dart';
import '../widgets/error_state_widgets/permission_card.dart';
import '../services/system_status_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';

class ErrorStatesPage extends StatefulWidget {
  const ErrorStatesPage({super.key});

  @override
  State<ErrorStatesPage> createState() => _ErrorStatesPageState();
}

class _ErrorStatesPageState extends State<ErrorStatesPage> {
  final SystemStatusService _systemStatusService = SystemStatusService();
  final FlutterTts _flutterTts = FlutterTts();
  int _batteryLevel = -1;
  String _batteryState = 'unknown';
  bool _isCameraAvailable = false;
  String _cameraStatusMessage = 'Checking...';
  bool _isLoading = true;
  String? _batteryError;
  PermissionStatus? _microphonePermission;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadSystemStatus();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadSystemStatus() async {
    setState(() {
      _isLoading = true;
      _batteryError = null;
    });

    try {
      final batteryLevel = await _systemStatusService.getBatteryLevel();
      final batteryStateResult = await _systemStatusService.getBatteryState();
      final cameraAvailable = await _systemStatusService.isCameraAvailable();
      final cameraStatus = await _systemStatusService.getCameraStatus();
      final micPermission = await Permission.microphone.status;

      setState(() {
        _batteryLevel = batteryLevel;
        _batteryState = batteryStateResult.toString().split('.').last;
        _isCameraAvailable = cameraAvailable;
        _cameraStatusMessage = cameraStatus;
        _microphonePermission = micPermission;
        _isLoading = false;
      });

      // Trigger vibration and speak battery status
      await _triggerVibration();
      await _speakBatteryStatus();
    } catch (e) {
      setState(() {
        _batteryError = 'Error loading status: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _retryCameraConnection() async {
    // Request permission and check again
    await _systemStatusService.requestCameraPermission();
    await _loadSystemStatus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCameraAvailable
                ? 'Camera is now available'
                : 'Camera still unavailable',
          ),
          backgroundColor: _isCameraAvailable ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _requestMicrophonePermission() async {
    // Prevent concurrent permission requests
    if (_isRequestingPermission) return;

    setState(() {
      _isRequestingPermission = true;
    });

    try {
      final status = await Permission.microphone.request();

      if (!mounted) return;

      setState(() {
        _microphonePermission = status;
        _isRequestingPermission = false;
      });

      if (status.isGranted) {
        await _flutterTts.speak(
          'Microphone permission granted. Voice commands are now enabled.',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission granted'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (status.isDenied) {
        await _flutterTts.speak('Microphone permission was denied.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission denied'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (status.isPermanentlyDenied) {
        await _flutterTts.speak(
          'Microphone permission is permanently denied. Please enable it in app settings.',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Microphone permission permanently denied. Open app settings?',
              ),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  openAppSettings();
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isRequestingPermission = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _triggerVibration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    if (_batteryLevel <= 15) {
      // Long continuous pulse for critical battery
      await Vibration.vibrate(duration: 1000);
    } else if (_batteryLevel <= 30) {
      // Short pulses for low battery
      await Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
    } else {
      // Single short pulse for normal status
      await Vibration.vibrate(duration: 200);
    }
  }

  Future<void> _speakBatteryStatus() async {
    String message = '';

    if (_batteryLevel < 0) {
      message = 'Unable to determine battery level';
    } else {
      message = 'Battery level is $_batteryLevel percent';

      if (_batteryState == 'charging') {
        message += ', charging';
      } else if (_batteryState == 'full') {
        message += ', fully charged';
      } else if (_batteryState == 'discharging') {
        message += ', discharging';
      }

      if (_batteryLevel <= 15) {
        message +=
            '. Warning: Critical battery level. Detection may stop soon to preserve power';
      } else if (_batteryLevel <= 30) {
        message += '. Battery is getting low. Consider charging soon';
      }
    }

    await _flutterTts.speak(message);
  }

  String _getBatteryDescription() {
    if (_batteryLevel < 0) {
      return _batteryError ?? 'Unable to determine battery level.';
    }

    String stateText = '';
    if (_batteryState == 'charging') {
      stateText = ' (Charging)';
    } else if (_batteryState == 'full') {
      stateText = ' (Fully Charged)';
    } else if (_batteryState == 'discharging') {
      stateText = ' (Discharging)';
    }

    if (_batteryLevel <= 15) {
      return 'Detection may stop soon to preserve power.$stateText';
    } else if (_batteryLevel <= 30) {
      return 'Battery is getting low. Consider charging soon.$stateText';
    } else {
      return 'Battery level is adequate for detection.$stateText';
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Error States',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Camera Status Card
                ErrorCard(
                  icon: _isCameraAvailable
                      ? Icons.videocam_outlined
                      : Icons.videocam_off_outlined,
                  title: _isCameraAvailable
                      ? 'Camera Available'
                      : 'Camera Unavailable',
                  description: _cameraStatusMessage,
                  voiceCommand: _isCameraAvailable
                      ? 'Audio: \'Camera ready\''
                      : 'Audio: \'Camera unavailable. Retrying...\'',
                  buttonText: _isCameraAvailable
                      ? 'Refresh Status'
                      : 'Retry Connection',
                  onButtonPressed: _retryCameraConnection,
                ),
                const SizedBox(height: 16),
                // Battery Status Card
                if (_batteryLevel >= 0)
                  WarningCard(
                    icon: _batteryState == 'charging'
                        ? Icons.battery_charging_full
                        : _batteryLevel <= 15
                        ? Icons.battery_alert
                        : _batteryLevel <= 30
                        ? Icons.battery_3_bar
                        : _batteryLevel <= 50
                        ? Icons.battery_5_bar
                        : Icons.battery_full,
                    title: _batteryLevel <= 15
                        ? 'Low Battery ($_batteryLevel%)'
                        : 'Battery Level: $_batteryLevel%',
                    description: _getBatteryDescription(),
                    note: _batteryLevel <= 15
                        ? 'Vibration: Long continuous pulse'
                        : 'State: ${_batteryState.toUpperCase()}',
                  )
                else
                  WarningCard(
                    icon: Icons.battery_unknown,
                    title: 'Battery Status Unknown',
                    description:
                        _batteryError ?? 'Unable to read battery level.',
                    note: 'Please check device settings',
                  ),
                const SizedBox(height: 16),
                // Permission Required
                PermissionCard(
                  title: 'Permission Required',
                  description:
                      'VoxEye needs access to your Microphone for voice commands.',
                  permissionType: 'Voice Command',
                  voiceCommandText:
                      'Spoken explanation plays BEFORE system dialog appears',
                  onAllow: _requestMicrophonePermission,
                  onDeny: () {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Microphone permission is required for voice commands',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  isGranted:
                      _microphonePermission != null &&
                      _microphonePermission!.isGranted,
                ),
              ],
            ),
    );
  }
}
