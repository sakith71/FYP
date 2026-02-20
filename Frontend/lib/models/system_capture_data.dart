class SystemCaptureData {
  final String? audioPath;
  final double? latitude;
  final double? longitude;
  final DateTime captureTime;
  final String? locationAddress;

  SystemCaptureData({
    this.audioPath,
    this.latitude,
    this.longitude,
    required this.captureTime,
    this.locationAddress,
  });

  @override
  String toString() {
    return 'SystemCaptureData('
        'audioPath: $audioPath, '
        'latitude: $latitude, '
        'longitude: $longitude, '
        'time: ${captureTime.toString()}, '
        'location: $locationAddress)';
  }
}
