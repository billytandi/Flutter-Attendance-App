class Attendance {
  String id;
  String qrCode;
  DateTime timestamp;
  double latitude;
  double longitude;

  Attendance({
    required this.id,
    required this.qrCode,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'qr_code': qrCode,
      'timestamp': timestamp,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
    };
  }
}
