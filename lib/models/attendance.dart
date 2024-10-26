class Attendance {
  String id;
  String qrCode;
  DateTime timestamp;
  double latitude;
  double longitude;
  String uid; // Ditambahkan UID
  String status; // Ditambahkan Nama

  Attendance({
    required this.id,
    required this.qrCode,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.uid, // Ditambahkan UID
    required this.status, // Ditambahkan Nama
  });

  Map<String, dynamic> toMap() {
    return {
      'qr_code': qrCode,
      'checkin': timestamp,
      'location': {
        'latitude': latitude,
        'longitude': longitude,
      },
      'uid': uid, // Disimpan UID,
      'status': status,
    };
  }
}

class Checkout {
  String id;
  DateTime timestamp;
  double latitude;
  double longitude;
  String uid; // Ditambahkan UID

  Checkout({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.uid,
  });

  Map<String, dynamic> toMap() {
    return {
      'checkout': timestamp,
      'uid': uid,
    };
  }
}