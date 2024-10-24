import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skripsi/views/attendance_history.dart';
import 'login_page.dart';
import 'qrscanpage.dart';
import 'package:geolocator/geolocator.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  late DateTime checkInTime;
  late DateTime checkOutTime;
  final Duration breakTime = const Duration(hours: 2);
  final int workingDays = 22;
  late String _currentTime = '00:00:00';
  late Timer _timer;
  String userName = '';
  String userPosition = '';
  bool isLoading = true;

  // Initialize to default values
  DateTime? checkInTimestamp;
  String checkInStatusText = 'Belum Check In';
  String formattedCheckInTime = '-'; // Default value
  String checkOutStatus = '-'; // Default value
  String formattedCheckOutTime = '-'; // Default value
  String formattedBreakTime = '-'; // Default value

  @override
  void initState() {
    super.initState();
    checkInTime =
        DateTime.now().subtract(const Duration(hours: 7, minutes: 30));
    checkOutTime =
        DateTime.now().subtract(const Duration(hours: 16, minutes: 30));
    _checkUserStatus();
    _currentTime = _formatCurrentTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _currentTime = _formatCurrentTime();
      });
    });
  }

  Future<void> _checkUserStatus() async {
    _user = _auth.currentUser;
    if (_user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      _fetchUserData();
      // Call method to fetch attendance data
      _fetchAttendanceData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(_user!.uid)
          .get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userName = userData['name'] ?? 'Nama tidak tersedia';
          userPosition = userData['position'] ?? 'Posisi dak tersedia';
          isLoading = false;
        });
      } else {
        setState(() {
          userName = 'Data pengguna tidak ditemukan';
          userPosition = '';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Error mengambil data';
        userPosition = '';
        isLoading = false;
      });
    }
  }

  // New method to fetch attendance data
  Future<void> _fetchAttendanceData() async {
    try {
      DocumentSnapshot attendanceDoc = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(_user!.uid) // Assuming the attendance document ID is the user ID
          .get();
      if (attendanceDoc.exists) {
        var attendanceData = attendanceDoc.data() as Map<String, dynamic>;
        
        setState(() {
          // Update the formatted values based on the attendance data
          formattedCheckInTime = attendanceData['timestamp'] != null
              ? DateFormat('HH:mm')
                  .format(attendanceData['timestamp'].toDate())
              : '-';
          formattedCheckOutTime = attendanceData['timestamp'] != null
              ? DateFormat('HH:mm')
                  .format(attendanceData['timestamp'].toDate())
              : '-';
          checkOutStatus = attendanceData['checkOutStatus'] ?? '-';
          // Update other fields as necessary
        });
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
    }
  }

  String _formatCurrentTime() {
    return DateFormat('HH:mm:ss').format(DateTime.now());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No changes needed in the build method
    return Scaffold(
      appBar: AppBar(
        title: const Text('SPILintern'),
        actions: [
          IconButton(
            onPressed: _showLogoutConfirmationDialog,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileSection(),
                  Text(
                    _currentTime.isNotEmpty ? _currentTime : 'Loading...',
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildAttendanceSection(
                      formattedCheckInTime,
                      checkInStatusText,
                      formattedCheckOutTime,
                      checkOutStatus,
                      formattedBreakTime),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.blue,
      ),
      height: 280,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage:
                    NetworkImage('https://via.placeholder.com/150'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Semangat Pagi!!',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    Text(
                      userPosition,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),

          //PopUp Status
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showWorkStatusOptions,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.work),
              SizedBox(width: 10),
              Text('Work Status'),
            ]),
          ),

          //History Page
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AttendanceHistoryPage()),
              );
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.history),
              SizedBox(width: 10),
              Text('History'),
            ]),
          )
        ],
      ),
    );
  }

  void _navigateToQRScanPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScanPage()),
    ).then((_) {
      // Setelah QR scan, update status Check-in
      setState(() {
        checkInStatusText = 'Sudah Check In'; // Update status
      });
    });
  }

Future<void> _setWorkStatus(String status) async {
  setState(() {
    checkInStatusText = status; // Update status di UI
  });

  try {
    // Periksa izin lokasi dan ambil posisi saat ini
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Dapatkan latitude dan longitude dari posisi pengguna
    final location = {
      'lat': position.latitude,
      'long': position.longitude
    };

    // Dapatkan data qr_code, ini bisa berasal dari logika scan QR yang sudah ada
    final qrCode = "-"; // Gantilah dengan nilai sebenarnya dari QR scanner

    // Simpan data ke Firestore
    await FirebaseFirestore.instance.collection('attendance').add({
      'employee_name': userName,
      'location': location,  // Simpan lokasi dalam format Map
      'qr_code': qrCode,
      'timestamp': FieldValue.serverTimestamp(), // Mendapatkan timestamp server
      'uid': _user!.uid,  // UID dari pengguna yang login
      'status': status,  // Status yang dipilih oleh pengguna
    });

    // Menampilkan pesan sukses jika diperlukan
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Status berhasil disimpan: $status'),
    ));
  } catch (e) {
    print('Error menyimpan status: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Gagal menyimpan status: $e'),
    ));
  }
}

  Future<void> _showWorkStatusOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Status Kerja'),
          content: SizedBox(
            height: 200, // tinggi pop-up
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusOption('WFO', Icons.business, () {
                      Navigator.of(context).pop(); // Tutup dialog
                      _navigateToQRScanPage(); // Arahkan ke QR scanner
                    }),
                    _buildStatusOption('Telat', Icons.lock_clock, () {
                      Navigator.of(context).pop(); // Tutup dialog
                      _setWorkStatus('Telat'); // Set status kerja sebagai Telat
                    }),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusOption('Izin', Icons.assignment, () {
                      Navigator.of(context).pop(); // Tutup dialog
                      _setWorkStatus('Izin'); // Set status kerja Izin
                    }),
                    _buildStatusOption('Sakit', Icons.sick, () {
                      Navigator.of(context).pop(); // Tutup dialog
                      _setWorkStatus('Sakit'); // Set status kerja sebagai Sakit
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 50),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(
    
      String formattedCheckInTime,
      String checkInStatus,
      String formattedCheckOutTime,
      String checkOutStatus,
      String formattedBreakTime) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          const Text(
            'Presensi Hari Ini',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoCard(
                  Icons.work, 'Check In', formattedCheckInTime, checkInStatus),
              _buildInfoCard(Icons.home, 'Check Out', formattedCheckOutTime,
                  checkOutStatus),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoCard(Icons.coffee, 'Waktu Istirahat',
                  formattedBreakTime, 'Rata-rata 1 Jam'),
              _buildInfoCard(Icons.calendar_today, 'Total Hari',
                  workingDays.toString(), 'Hari Kerja'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.blue),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin logout dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Tutup dialog jika tidak jadi logout
              },
              child: Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                _logout(); // Panggil fungsi logout
                Navigator.of(context).pop(); // Tutup dialog setelah logout
              },
              child: Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await _auth.signOut(); // Proses logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}
