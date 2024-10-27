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
  late String _currentTime = '00:00:00';
  late Timer _timer;
  String userName = '';
  String userPosition = '';
  bool isLoading = true;

  // Initialize to default values
  DateTime? checkInTimestamp;
  String checkInStatus = 'Belum In';
  String formattedCheckInTime = '-'; // Default value
  String checkOutStatus = 'Belum Check Out'; // Default value
  String formattedCheckOutTime = '-'; // Default value
  String formattedBreakTime = '-'; // Default value
  int workingDays = 0;
  int absenceDays = 0;
  DateTime? lastFetchDate;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _currentTime = _formatCurrentTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _currentTime = _formatCurrentTime();
      });
    });
    _fetchWorkingDays();
    _fetchAbsenceDays();
    _fetchAttendanceData();
  }

  Future<int> getWorkingDaysCount() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: _user!.uid)
          .where('status', whereIn: ['Hadir', 'Late']).get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error fetching working days count: $e');
      return 0;
    }
  }

  Future<void> _fetchWorkingDays() async {
    int count = await getWorkingDaysCount();
    setState(() {
      workingDays = count;
    });
  }

  Future<void> _fetchAbsenceDays() async {
    int count = await getAbsenceDaysCount();
    setState(() {
      absenceDays = count;
    });
  }

  Future<int> getAbsenceDaysCount() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: _user!.uid)
          .where('status', whereNotIn: ['Hadir']).get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error fetching absence days count: $e');
      return 0;
    }
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
          userName = userData['name'];
          userPosition = userData['position'];
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

  void _resetDailyAttendance() {
    setState(() {
      formattedCheckInTime = '-';
      checkInStatus = 'Belum Check In';
      formattedCheckOutTime = '-';
      checkOutStatus = 'Belum Check Out';
    });
  }

  Future<void> _fetchAttendanceData() async {
    try {
      DateTime currentDate = DateTime.now();
      var startOfDay = DateTime(
          currentDate.year, currentDate.month, currentDate.day, 0, 0, 0);
      var endOfDay = DateTime(
          currentDate.year, currentDate.month, currentDate.day, 23, 59, 59);

      // Query today's attendance record
      var querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: _user!.uid)
          .where('checkin', isGreaterThanOrEqualTo: startOfDay)
          .where('checkin', isLessThanOrEqualTo: endOfDay)
          .limit(1)
          .get();

      // Check if there is no attendance record for today
      if (querySnapshot.docs.isEmpty) {
        // Reset UI if no check-in record exists for today
        setState(() {
          formattedCheckInTime = '-';
          checkInStatus = 'Belum Check In';
          formattedCheckOutTime = '-';
          checkOutStatus = 'Belum Check Out';
        });
        return;
      }

      // Otherwise, retrieve today's attendance data
      var attendanceDoc = querySnapshot.docs.first.data();

      DateTime? checkInTimestamp =
          (attendanceDoc['checkin'] as Timestamp?)?.toDate();
      DateTime? checkOutTimestamp =
          (attendanceDoc['checkout'] as Timestamp?)?.toDate();

      setState(() {
        // Update UI with today's check-in data if exists
        if (checkInTimestamp != null) {
          formattedCheckInTime = DateFormat('HH:mm').format(checkInTimestamp);
          checkInStatus = 'Sudah Check In';
        } else {
          checkInStatus = 'Belum Check In';
        }

        // Update UI with today's check-out data if exists
        if (checkOutTimestamp != null) {
          formattedCheckOutTime = DateFormat('HH:mm').format(checkOutTimestamp);
          print(formattedCheckOutTime);
          print(checkOutTimestamp);
          checkOutStatus = checkOutTimestamp.hour > 18
              ? 'Lembur'
              : (checkOutTimestamp.hour > 16 ||
                      (checkOutTimestamp.hour == 16 &&
                          checkOutTimestamp.minute >= 30))
                  ? 'On Time'
                  : 'Pulang Cepat';
        } else {
          checkOutStatus = 'Belum Check Out';
        }
      });
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
                  const SizedBox(height: 10),
                  _buildAttendanceSection(
                      formattedCheckInTime,
                      checkInStatus,
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
      height: 250,
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _showWorkStatusOptions,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.work),
                      SizedBox(width: 10),
                      Text('Work Status'),
                    ]),
              ),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Konfirmasi Checkout'),
                        content: const Text(
                            'Apakah Anda yakin ingin melakukan checkout?'),
                        actions: [
                          TextButton(
                            child: const Text('Batal'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: const Text('Ya, Checkout'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _setCheckoutTime();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.work),
                    SizedBox(width: 10),
                    Text('Check Out'),
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
                MaterialPageRoute(
                    builder: (context) => AttendanceHistoryPage()),
              );
            },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.history),
              const SizedBox(width: 10),
              const Text('History'),
            ]),
          ),
        ],
      ),
    );
  }

  void _navigateToQRScanPage(String status) async {
    bool alreadyCheckedIn = await _checkIfCheckedInToday();

    if (!alreadyCheckedIn && status == 'Hadir') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QRScanPage()),
      );
    }
    _fetchAttendanceData();
  }

  Future<bool> _checkIfCheckedInToday() async {
    var today = DateTime.now();
    var startOfDay = DateTime(today.year, today.month, today.day, 0, 0, 0);
    var endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    var querySnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('uid', isEqualTo: _user!.uid)
        .where('checkin', isGreaterThanOrEqualTo: startOfDay)
        .where('checkin', isLessThanOrEqualTo: endOfDay)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda sudah melakukan check-in hari ini')),
      );
      return true;
    }
    return false;
  }

  void _showConfirmationDialog(String status) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Status Kehadiran'),
          content: Text(
              'Apakah Anda yakin ingin menandai kehadiran Anda sebagai $status?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _setWorkStatus(status);
                Navigator.of(context).pop();
              },
              child: Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  void _showWorkStatusOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Work Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusOption('WFO', Icons.work, () {
                    Navigator.of(context).pop();
                    _navigateToQRScanPage("Hadir");
                  }),
                  _buildStatusOption('Late', Icons.access_time, () {
                    Navigator.of(context).pop();
                    _setWorkStatus('Telat');
                  }),
                  _buildStatusOption('Permit', Icons.approval, () {
                    Navigator.of(context).pop();
                    _setWorkStatus('Izin');
                  }),
                  _buildStatusOption('Sick', Icons.sick, () {
                    Navigator.of(context).pop();
                    _setWorkStatus('Sakit');
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(String status, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        if (status == 'Late' || status == 'Permit' || status == 'Sick') {
          _showConfirmationDialog(status);
        } else {
          onTap();
        }
      },
      child: Column(
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),
          Text(status),
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
              _buildInfoCard(Icons.holiday_village, 'Istirahat',
                  absenceDays.toString(), 'Tidak Hadir'),
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
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin logout dari aplikasi?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tidak'),
            ),
            TextButton(
              onPressed: () {
                _logout();
                Navigator.of(context).pop();
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  Future<void> _setWorkStatus(String status) async {
    try {
      var today = DateTime.now();
      var startOfDay = DateTime(today.year, today.month, today.day, 0, 0, 0);
      var endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      var querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: _user!.uid)
          .where('checkin', isGreaterThanOrEqualTo: startOfDay)
          .where('checkin', isLessThanOrEqualTo: endOfDay)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda sudah melakukan check-in hari ini')),
        );
        return;
      }

      // If not checked in, get the current position

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final location = {'lat': position.latitude, 'long': position.longitude};

      final qrCode = "-"; // Set QR code if applicable, else keep as '-'
      await FirebaseFirestore.instance.collection('attendance').add({
        'uid': _user!.uid,
        'employee_name': userName,
        'status': status, // Save the selected work status
        'checkin': FieldValue.serverTimestamp(), // Set the check-in time
        'location': location,
        'qr_code': qrCode, // Optional QR code field
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Status kehadiran berhasil disimpan sebagai $status')),
      );

      _fetchAttendanceData();
      _fetchWorkingDays();
      _fetchAbsenceDays();
    } catch (e) {
      print('Error setting work status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan status kehadiran: $e')),
      );
    }
  }

  Future<void> _setCheckoutTime() async {
    try {
      var today = DateTime.now();
      var startOfDay = DateTime(today.year, today.month, today.day, 0, 0, 0);
      var endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Query today's attendance record
      var querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: _user!.uid)
          .where('checkin', isGreaterThanOrEqualTo: startOfDay)
          .where('checkin', isLessThanOrEqualTo: endOfDay)
          .limit(1)
          .get();

      // Check if user has checked in today
      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda belum check-in hari ini')),
        );
        return;
      }

      var attendanceDoc = querySnapshot.docs.first;

      // Check if the 'checkout' field exists and if it already has a value
      if (attendanceDoc.data().containsKey('checkout') &&
          attendanceDoc['checkout'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda sudah melakukan checkout hari ini')),
        );
        return; // Exit if already checked out
      }

      // Update the Firestore document with checkout time using document ID
      await FirebaseFirestore.instance
          .collection('attendance')
          .doc(attendanceDoc.id) // Use the specific document ID
          .update({'checkout': FieldValue.serverTimestamp()});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout berhasil disimpan')),
      );

      _fetchAttendanceData(); // Refresh data after successful checkout
    } catch (e) {
      print('Error updating checkout time: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal melakukan checkout: $e')),
      );
    }
  }
}
