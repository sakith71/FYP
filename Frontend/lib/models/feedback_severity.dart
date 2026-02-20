import 'package:flutter/material.dart';

enum FeedbackSeverity {
  information,
  warning,
  critical;

  String get label {
    switch (this) {
      case FeedbackSeverity.information:
        return 'Information';
      case FeedbackSeverity.warning:
        return 'Warning';
      case FeedbackSeverity.critical:
        return 'Critical';
    }
  }

  String get description {
    switch (this) {
      case FeedbackSeverity.information:
        return 'Low priority — general awareness';
      case FeedbackSeverity.warning:
        return 'Medium priority — caution needed';
      case FeedbackSeverity.critical:
        return 'High priority — immediate action';
    }
  }

  IconData get icon {
    switch (this) {
      case FeedbackSeverity.information:
        return Icons.info;
      case FeedbackSeverity.warning:
        return Icons.warning;
      case FeedbackSeverity.critical:
        return Icons.error;
    }
  }

  Color get color {
    switch (this) {
      case FeedbackSeverity.information:
        return const Color(0xFF2196F3);
      case FeedbackSeverity.warning:
        return const Color(0xFFFFC107);
      case FeedbackSeverity.critical:
        return const Color(0xFFFF5252);
    }
  }

  int get vibrationPulseCount {
    switch (this) {
      case FeedbackSeverity.information:
        return 1;
      case FeedbackSeverity.warning:
        return 2;
      case FeedbackSeverity.critical:
        return 3;
    }
  }

  String get audioMessage {
    switch (this) {
      case FeedbackSeverity.information:
        return 'Object detected ahead, five meters.';
      case FeedbackSeverity.warning:
        return 'Obstacle ahead right, two meters.';
      case FeedbackSeverity.critical:
        return 'Danger - obstacle directly ahead, one meter.';
    }
  }

  /// Determine severity level based on distance in meters
  static FeedbackSeverity fromDistance(double distanceInMeters) {
    if (distanceInMeters >= 4) {
      return FeedbackSeverity.information; // 5+ meters
    } else if (distanceInMeters >= 1.5) {
      return FeedbackSeverity.warning; // 2-4 meters
    } else {
      return FeedbackSeverity.critical; // < 1.5 meters
    }
  }

  /// Get distance range for this severity level
  String get distanceRange {
    switch (this) {
      case FeedbackSeverity.information:
        return '4+ meters';
      case FeedbackSeverity.warning:
        return '1.5 - 4 meters';
      case FeedbackSeverity.critical:
        return '< 1.5 meters';
    }
  }
}
