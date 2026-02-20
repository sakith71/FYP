import 'package:battery_plus/battery_plus.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class SystemStatusService {
  final Battery _battery = Battery();

  // Get current location (latitude, longitude)
  Future<Map<String, double>> getLocation() async {
    try {
      // Check location permission
      final permission = await checkLocationPermission();
      if (!permission) {
        return {'latitude': 0.0, 'longitude': 0.0};
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        forceAndroidLocationManager: true,
      );

      return {'latitude': position.latitude, 'longitude': position.longitude};
    } catch (e) {
      // Use a logger or debugPrint in a real app
      return {'latitude': 0.0, 'longitude': 0.0};
    }
  }

  // Check and request location permission
  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return true;
    }

    return false;
  }

  // Get location availability
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current timestamp as formatted string
  String getCurrentTimeString() {
    final now = DateTime.now();
    return now.toString();
  }

  // Get current time as DateTime
  DateTime getCurrentTime() {
    return DateTime.now();
  }

  // Get formatted time for display (HH:mm:ss)
  String getFormattedTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  // Get battery level (0-100)
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
