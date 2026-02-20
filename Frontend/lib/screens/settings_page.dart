import 'package:flutter/material.dart';
import 'package:voxeye/widgets/share_widgets/voice_command_banner.dart';
import '../widgets/settings_widgets/speed_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String selectedSpeed = 'Normal';
  String selectedVoice = 'Voice A';
  double vibrationIntensity = 0.7;
  String selectedSensitivity = 'Medium';
  String selectedVerbosity = 'Balanced';

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
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const Divider(height: 1),
          const VoiceCommandBanner(
            command: 'Voice: \'Settings menu. Audio, Vibration, Sensitivity.\'',
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Audio Settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Audio Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Speech Speed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SpeedButton(
                        label: 'Slow',
                        isSelected: selectedSpeed == 'Slow',
                        onTap: () =>
                            setState(() => selectedSpeed = 'Slow'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SpeedButton(
                        label: 'Normal',
                        isSelected: selectedSpeed == 'Normal',
                        onTap: () =>
                            setState(() => selectedSpeed = 'Normal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SpeedButton(
                        label: 'Fast',
                        isSelected: selectedSpeed == 'Fast',
                        onTap: () =>
                            setState(() => selectedSpeed = 'Fast'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Voice Selection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SpeedButton(
                        label: 'Voice A',
                        isSelected: selectedVoice == 'Voice A',
                        onTap: () =>
                            setState(() => selectedVoice = 'Voice A'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SpeedButton(
                        label: 'Voice B',
                        isSelected: selectedVoice == 'Voice B',
                        onTap: () =>
                            setState(() => selectedVoice = 'Voice B'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Vibration Settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vibration Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Intensity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.black,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 14,
                    ),
                    overlayColor: Colors.black.withValues(alpha: 0.1),
                    trackHeight: 8,
                  ),
                  child: Slider(
                    value: vibrationIntensity,
                    onChanged: (value) =>
                        setState(() => vibrationIntensity = value),
                    min: 0,
                    max: 1,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Detection Sensitivity
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detection Sensitivity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SpeedButton(
                        label: 'Low',
                        isSelected: selectedSensitivity == 'Low',
                        onTap: () =>
                            setState(() => selectedSensitivity = 'Low'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SpeedButton(
                        label: 'Medium',
                        isSelected: selectedSensitivity == 'Medium',
                        onTap: () =>
                            setState(() => selectedSensitivity = 'Medium'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SpeedButton(
                        label: 'High',
                        isSelected: selectedSensitivity == 'High',
                        onTap: () =>
                            setState(() => selectedSensitivity = 'High'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Feedback Verbosity
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feedback Verbosity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                _buildRadioRow(
                  'Minimal (Warnings only)',
                  'Minimal',
                  selectedVerbosity == 'Minimal',
                  () => setState(() => selectedVerbosity = 'Minimal'),
                ),
                const SizedBox(height: 12),
                _buildRadioRow(
                  'Balanced',
                  'Balanced',
                  selectedVerbosity == 'Balanced',
                  () => setState(() => selectedVerbosity = 'Balanced'),
                ),
                const SizedBox(height: 12),
                _buildRadioRow(
                  'Detailed',
                  'Detailed',
                  selectedVerbosity == 'Detailed',
                  () => setState(() => selectedVerbosity = 'Detailed'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRadioRow(
    String label,
    String value,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? Colors.grey[100] : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
