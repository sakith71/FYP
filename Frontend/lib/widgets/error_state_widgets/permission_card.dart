import 'package:flutter/material.dart';

class PermissionCard extends StatelessWidget {
  final String title;
  final String description;
  final String permissionType;
  final String? voiceCommandText;
  final VoidCallback onAllow;
  final VoidCallback? onDeny;
  final bool isGranted;

  const PermissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.permissionType,
    this.voiceCommandText,
    required this.onAllow,
    this.onDeny,
    this.isGranted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(
          color: isGranted ? Colors.green[400]! : Colors.grey[400]!,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isGranted ? Colors.green[50] : Colors.grey[50],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGranted ? Icons.shield_outlined : Icons.shield_outlined,
            size: 56,
            color: isGranted ? Colors.green[700] : Colors.black87,
          ),
          const SizedBox(height: 24),
          Text(
            isGranted ? 'Permission Granted' : title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isGranted ? Colors.green[800] : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          if (voiceCommandText != null) ...[
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 24,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permissionType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voiceCommandText!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),
          if (isGranted)
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Allowed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAllow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Allow',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
