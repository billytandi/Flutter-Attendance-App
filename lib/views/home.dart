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
  }

  Future<int> getWorkingDaysCount() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: _user!.uid)
          .where('status', whereIn: ['Hadir', 'Telat']).get();
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
      _fetchAttendanceData(); // Panggil fetch attendance data
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

  Future<void> _setCheckoutTime() async {
    try {
      var today = DateTime.now();
      var startOfDay = DateTime(
          today.year, today.month, today.day, 0, 0, 0); // Awal hari (00:00)
      var endOfDay = DateTime(
          today.year, today.month, today.day, 23, 59, 59); // Akhir hari (23:59)

      // Query untuk mengambil attendance pada hari ini untuk user saat ini
      var querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: _user!.uid)
          .where('checkin',
              isGreaterThanOrEqualTo:
                  startOfDay) // Filter attendance mulai dari awal hari ini
          .where('checkin',
              isLessThanOrEqualTo: endOfDay) // Sampai akhir hari ini
          .get();

      // Jika sudah ada check-in pada hari ini
      if (querySnapshot.docs.isEmpty) {
        // Tampilkan pesan bahwa pengguna sudah melakukan check-inV
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anda sudah melakukan check-out hari ini'),
          ),
        );
        return; // Batalkan proses check-in
      }
      if (querySnapshot.docs.isNotEmpty) {
        var attendanceDoc = querySnapshot.docs.first;
        print('User UID: ${_user!.uid}');

        await FirebaseFirestore.instance
            .collection('attendance')
            .doc(attendanceDoc.id) // Use the document ID
            .update({
          'checkout': FieldValue.serverTimestamp(),
        });

        // Setelah checkout, fetch ulang data attendance untuk memperbarui UI
        _fetchAttendanceData();

        print('Checkout time updated successfully.');
      } else {
        print('Attendance document not found for user: ${_user!.uid}');
      }
    } catch (e) {
      print('Error updating checkout time: $e');
    }
  }

  Future<void> _fetchAttendanceData() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: _user!.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var attendanceDoc = querySnapshot.docs.first.data();

        DateTime? checkInTimestamp =
            (attendanceDoc['checkin'] as Timestamp?)?.toDate();
        DateTime? checkOutTimestamp =
            (attendanceDoc['checkout'] as Timestamp?)?.toDate();

        setState(() {
          if (checkInTimestamp != null) {
            formattedCheckInTime = DateFormat('HH:mm').format(checkInTimestamp);
            checkInStatus = attendanceDoc['status'] ?? 'Tidak Ada Status';
          }

          if (checkOutTimestamp != null) {
            formattedCheckOutTime =
                DateFormat('HH:mm').format(checkOutTimestamp);
            checkOutStatus = attendanceDoc['status'] ?? 'Tidak Ada Status';

            if (checkOutTimestamp.hour > 18) {
              checkOutStatus = 'Lembur';
            } else if (checkOutTimestamp.hour > 16 ||
                (checkOutTimestamp.hour == 16 &&
                    checkOutTimestamp.minute >= 30)) {
              checkOutStatus = 'On Time';
            } else {
              checkOutStatus = 'Pulang Cepat';
            }
          }
        });
      } else {
        print('Dokumen attendance tidak ditemukan.');
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
                              _setCheckoutTime(); // Update checkout time
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
    await _setWorkStatus(status);
  }

  Future<bool> _checkIfCheckedInToday() async {
    var today = DateTime.now();
    var startOfDay = DateTime(today.year, today.month, today.day, 0, 0, 0);
    var endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    var querySnapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('uid', isEqualTo: _user!.uid)
        // .where('checkin', isGreaterThanOrEqualTo: startOfDay)
        // .where('checkin', isLessThanOrEqualTo: endOfDay)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Anda sudah melakukan check-in hari ini')),
      );
      return true; // Return true if already checked in
    }
    return false; // Return false if not checked in
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
      onTap: onTap,
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

  Future<bool> _setWorkStatus(String status) async {
    try {
      // Periksa apakah pengguna sudah check-in hari ini
      var today = DateTime.now();
      var startOfDay = DateTime(
          today.year, today.month, today.day, 0, 0, 0); // Awal hari (00:00)
      var endOfDay = DateTime(
          today.year, today.month, today.day, 23, 59, 59); // Akhir hari (23:59)

      // Query untuk mengambil attendance pada hari ini untuk user saat ini
      var querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('uid', isEqualTo: _user!.uid)
          // .where('checkin', isGreaterThanOrEqualTo: startOfDay)
          // .where('checkin', isLessThanOrEqualTo: endOfDay)
          .get();

      // Jika sudah ada check-in pada hari ini
      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda sudah melakukan check-in hari ini')),
        );
        return true; // Return true jika sudah check-in
      }

      // Jika belum ada check-in, lanjutkan dengan proses penyimpanan check-in
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final location = {'lat': position.latitude, 'long': position.longitude};
      final qrCode = "-";

      await FirebaseFirestore.instance.collection('attendance').add({
        'employee_name': userName,
        'location': location,
        'qr_code': qrCode,
        'checkin': FieldValue.serverTimestamp(),
        'uid': _user!.uid,
        'status': status,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status berhasil disimpan: $status'),
      ));
      _fetchAttendanceData();
      return false; // Return false jika belum check-in dan proses berhasil
    } catch (e) {
      print('Error menyimpan status: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal melakukan check-in: $e'),
      ));
      return true; // Mengembalikan true jika terjadi error
    }
  }
}
