import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/system_status_service.dart';

class ReportHazardPage extends StatefulWidget {
  const ReportHazardPage({super.key});

  @override
  State<ReportHazardPage> createState() => _ReportHazardPageState();
}

class _ReportHazardPageState extends State<ReportHazardPage> {
  final AudioService _audioService = AudioService();
  final SystemStatusService _systemStatusService = SystemStatusService();

  bool _isRecording = false;
  bool _hasRecorded = false;
  String _statusText = '"Describe the hazard after the beep."';

  // System capture tracking
  bool _isCapturingAudio = false;
  bool _isCapturingGPS = false;
  bool _isCapturingTime = false;
  String? _gpsLocation = '';

  @override
  void initState() {
    super.initState();
    // Request location permission on startup
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    try {
      await _systemStatusService.checkLocationPermission();
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioService.stopRecording();
      if (path != null) {
        setState(() {
          _isRecording = false;
          _hasRecorded = true;
          _statusText = 'Recording completed. Tap mic to re-record.';
          _isCapturingAudio = false;
          _isCapturingGPS = false;
          _isCapturingTime = false;
        });
      }
    } else {
      // Play beep and start recording
      await _audioService.playBeep();

      // Small delay to let the beep play
      await Future.delayed(const Duration(milliseconds: 200));

      final started = await _audioService.startRecording();
      if (started) {
        // START CAPTURING SYSTEM DATA
        final locationData = await _systemStatusService.getLocation();

        setState(() {
          _isRecording = true;
          _isCapturingAudio = true;
          _isCapturingGPS = locationData['latitude'] != 0.0;
          _isCapturingTime = true;
          _gpsLocation =
              'Lat: ${locationData['latitude']?.toStringAsFixed(4) ?? 'N/A'}, '
              'Lng: ${locationData['longitude']?.toStringAsFixed(4) ?? 'N/A'}';
          _statusText = 'Recording... Tap to stop or say "Cancel"';
        });
      } else {
        setState(() {
          _statusText = 'Microphone permission denied';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable microphone permission in settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelReport() async {
    await _audioService.cancelRecording();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 1),
              const Text(
                'Report Hazard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              // System Capture Indicators
              if (_isRecording)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYSTEM CAPTURES:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Audio Capture
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isCapturingAudio
                                        ? Colors.red
                                        : Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.mic,
                                    size: 20,
                                    color: _isCapturingAudio
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Audio',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _isCapturingAudio
                                        ? Colors.red
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            // GPS Capture
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isCapturingGPS
                                        ? Colors.green
                                        : Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: _isCapturingGPS
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'GPS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _isCapturingGPS
                                        ? Colors.green
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            // Time Capture
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isCapturingTime
                                        ? Colors.blue
                                        : Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.access_time,
                                    size: 20,
                                    color: _isCapturingTime
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _isCapturingTime
                                        ? Colors.blue
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (_isCapturingGPS && _gpsLocation != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _gpsLocation!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[900],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              // Entire middle section clickable
              Expanded(
                child: GestureDetector(
                  onTap: _toggleRecording,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      const Spacer(),
                      // Microphone Button
                      Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.all(30),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.red : Colors.black,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isRecording ? Colors.red : Colors.black)
                                        .withAlpha(76),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 70,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        _statusText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Progress Bar (Animated based on recording status)
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 300),
                          alignment: Alignment.centerLeft,
                          widthFactor: _hasRecorded
                              ? 1.0
                              : (_isRecording ? 0.6 : 0.3),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isRecording ? Colors.red : Colors.black,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              // Note Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOTE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Works offline — syncs when connected',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Voice Command Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VOICE COMMAND',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Say \'Cancel\' to abort reporting',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _cancelReport,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
