import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // Query data absensi berdasarkan UID karyawan yang sedang login
    QuerySnapshot attendanceSnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('uid', isEqualTo: user.uid) // Filter berdasarkan UID
        .orderBy('timestamp', descending: true) // Urutkan berdasarkan timestamp
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
    _attendanceHistory = getAttendanceHistory(); // Ambil data riwayat absen
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
            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> attendance = history[index];

                // Ambil dan format timestamp
                DateTime timestamp = attendance['timestamp'].toDate();
                String formattedDate = '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}';
                String formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

                String location;
                String keterangan;

                // Mengambil lokasi dari qr_code
                if (attendance.containsKey('qr_code')) {
                  String qrCode = attendance['qr_code'];
                  try {
                    Map<String, dynamic> qrData = jsonDecode(qrCode);
                    location = qrData.containsKey('location') 
                      ? qrData['location'] 
                      : '-'; // Jika tidak ada kunci 'location', isi dengan '-'
                  } catch (e) {
                    location = '-';
                    print('Kesalahan saat mendekode qr_code: $e');
                  }
                } else {
                  location = '-';
                }

                // Mengambil keterangan
                keterangan = attendance.containsKey('status') 
                  ? attendance['status'] 
                  : 'Tidak ada keterangan';

                // Tampilkan dalam Card untuk tampilan yang lebih modern
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Lokasi Absen: $location',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Text(
                          'Keterangan: $keterangan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
