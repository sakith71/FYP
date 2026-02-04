import 'package:battery_plus/battery_plus.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class SystemStatusService {
  final Battery _battery = Battery();

  // Get current battery level (0-100)
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return -1; // Return -1 if unable to get battery level
    }
  }

  // Get battery state (charging, discharging, etc.)
  Future<BatteryState> getBatteryState() async {
    try {
      return await _battery.batteryState;
    } catch (e) {
      return BatteryState.unknown;
    }
  }

  // Check if camera is available
  Future<bool> isCameraAvailable() async {
    try {
      // Check camera permission first
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        return false;
      }

      // Try to get available cameras
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get camera availability status message
  Future<String> getCameraStatus() async {
    try {
      final permissionStatus = await Permission.camera.status;

      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        return 'Camera permission denied';
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return 'No camera found';
      }

      return 'Camera available';
    } catch (e) {
      return 'Camera unavailable: ${e.toString()}';
    }
  }

  // Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }
}
