import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance.dart';

class AttendanceViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> recordAttendance(Attendance attendance) async {
    await _firestore.collection('attendance').add(attendance.toMap());
  }

  Future<List<Attendance>> getAttendanceHistory(String employeeID) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('attendance')
        .where('uid', isEqualTo: employeeID) // Diganti dengan field `uid`
        .get();

    return querySnapshot.docs.map((doc) {
      return Attendance(
        id: doc.id,
        qrCode: doc['qr_code'],
        timestamp: (doc['timestamp'] as Timestamp).toDate(),
        latitude: doc['location']['latitude'],
        longitude: doc['location']['longitude'],
        uid: doc['uid'], // Ditambahkan UID dari data
        status: doc['status'],
      );
    }).toList();
  }
}
