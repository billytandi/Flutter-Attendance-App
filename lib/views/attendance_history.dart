import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Query data absensi berdasarkan UID karyawan yang sedang login
    QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('uid', isEqualTo: user.uid)  // Filter berdasarkan UID
        .orderBy('timestamp', descending: true)  // Urutkan berdasarkan timestamp
        .get();

    // Buat list untuk menyimpan data absensi
    List<Map<String, dynamic>> attendanceHistory = attendanceSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    return attendanceHistory;
  } else {
    throw Exception("User tidak ditemukan");
  }
}

class AttendanceHistoryPage extends StatefulWidget {
  @override
  _AttendanceHistoryPageState createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  Future<List<Map<String, dynamic>>>? _attendanceHistory;

  @override
  void initState() {
    super.initState();
    _attendanceHistory = getAttendanceHistory();  // Ambil data riwayat absen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Absensi'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _attendanceHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Belum ada riwayat'));
          } else {
            // Tampilkan riwayat absensi
            List<Map<String, dynamic>> history = snapshot.data!;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Agar tabel bisa di-scroll horizontal jika kolom banyak
              child: DataTable(
                columns: [
                  DataColumn(label: Text('Tanggal')),
                  DataColumn(label: Text('Jam')),
                  DataColumn(label: Text('Lokasi')),
                  DataColumn(label: Text('Keterangan')),
                ],
                rows: history.map((attendance) {
                  DateTime timestamp = attendance['timestamp'].toDate();
                  String formattedDate = '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}';
                  String formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

                  String location = '${attendance['location']['latitude']}, ${attendance['location']['longitude']}';
                  String keterangan = attendance.containsKey('keterangan') ? attendance['keterangan'] : 'Tidak ada keterangan';

                  return DataRow(cells: [
                    DataCell(Text(formattedDate)),
                    DataCell(Text(formattedTime)),
                    DataCell(Text(location)),
                    DataCell(Text(keterangan)),
                  ]);
                }).toList(),
              ),
            );
          }
        },
      ),
    );
  }
}
