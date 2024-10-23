import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';
import 'qrscanpage.dart';

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
  final int workingDays = 16;
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
    checkInTime = DateTime.now().subtract(const Duration(hours: 7, minutes: 30));
    checkOutTime = DateTime.now().subtract(const Duration(hours: 16, minutes: 30));
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
          userPosition = userData['position'] ?? 'Posisi tidak tersedia';
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
          formattedCheckInTime = attendanceData['checkInTime'] != null
              ? DateFormat('HH:mm').format(attendanceData['checkInTime'].toDate())
              : '-';
          formattedCheckOutTime = attendanceData['checkOutTime'] != null
              ? DateFormat('HH:mm').format(attendanceData['checkOutTime'].toDate())
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
            onPressed: _logout,
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
      height: 180,
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QRScanPage()),
              );
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.qr_code_scanner),
              SizedBox(width: 10),
              Text('Check-in with QR Code'),
            ]),
          )
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

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}