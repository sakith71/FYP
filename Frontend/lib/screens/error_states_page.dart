import 'package:flutter/material.dart';
import '../widgets/error_state_widgets/error_card.dart';
import '../widgets/error_state_widgets/warning_card.dart';
import '../services/system_status_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

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

      setState(() {
        _batteryLevel = batteryLevel;
        _batteryState = batteryStateResult.toString().split('.').last;
        _isCameraAvailable = cameraAvailable;
        _cameraStatusMessage = cameraStatus;
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 32,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Permission Required',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
