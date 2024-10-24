import 'dart:convert'; // Untuk decode JSON dari QR Code
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:skripsi/views/home.dart';
import '../viewmodels/attendance_viewmodel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScanPage extends StatefulWidget {
  @override
  _QRScanPageState createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final GlobalKey qrKey = GlobalKey();
  QRViewController? controller;
  final AttendanceViewModel _attendanceViewModel = AttendanceViewModel();
  bool isProcessing =
      false; // Flag untuk memastikan hanya satu kali proses scan

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isIOS) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  /// Proses scan QR Code dan simpan data absensi ke Firestore.
  ///
  /// Berikut adalah proses yang dilakukan:
  ///
  /// 1. Decode QR Code yang berisi JSON.
  /// 2. Dapatkan lokasi dari QR Code.
  /// 3. Dapatkan UID karyawan yang sedang login.
  /// 4. Ambil data karyawan dari Firestore berdasarkan UID.
  /// 5. Dapatkan lokasi saat ini.
  /// 6. Simpan data absensi ke Firestore.
  /// 7. Tampilkan pop-up sukses jika berhasil.
  Future<void> _recordAttendance(String qrCode) async {
    setState(() {
      isProcessing = true; // Menampilkan loading icon
    });

    // Tunggu 1 detik untuk loading
    await Future.delayed(Duration(seconds: 1));

    try {
      // Decode QR Code yang berisi JSON
      Map<String, dynamic> qrData = jsonDecode(qrCode);
      String location = qrData['location'];

      // Dapatkan UID karyawan yang sedang login
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Ambil data karyawan dari Firestore berdasarkan UID
        DocumentSnapshot employeeSnapshot = await FirebaseFirestore.instance
            .collection('employees')
            .doc(user.uid)
            .get();

        String employeeName = employeeSnapshot['name']; // Ambil nama karyawan

        // Dapatkan lokasi saat ini
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        // Simpan data absensi ke Firestore
        await FirebaseFirestore.instance.collection('attendance').add({
          'qr_code': qrCode,
          'location_from_qr': location, // Lokasi dari QR Code
          'timestamp': DateTime.now(),
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'employee_name': employeeName, // Tambahkan nama karyawan
          'uid': user.uid // Tambahkan UID karyawan
        });

        // Tampilkan pop-up sukses setelah berhasil menyimpan data
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Absensi Berhasil'),
            content: Text(
                'Absensi berhasil disimpan dengan nama $employeeName di lokasi $location!'),
            actions: [
              TextButton(
                onPressed: () {
                  // Stop the QR code scanner and pause the camera here
                  controller?.pauseCamera(); // Pausing the camera

                  // Navigate back to the Home page
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Home()),
                    (Route<dynamic> route) => false,
                  );

                  // Reset the processing flag
                  setState(() {
                    isProcessing = false; // Set kembali flag ke false
                  });
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Tampilkan pesan error jika user tidak ditemukan
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User tidak ditemukan, silakan login kembali'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal memproses absensi: $e'),
      ));
      setState(() {
        isProcessing =
            false; // Kembalikan state processing ke false jika ada error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR Code')),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: (QRViewController controller) {
                this.controller = controller;
                controller.scannedDataStream.listen((scanData) {
                  if (!isProcessing) {
                    // Cek jika tidak dalam proses
                    _recordAttendance(scanData.code!); // Jalankan hanya sekali
                  }
                });
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: isProcessing // Tampilkan loading jika sedang memproses
                  ? CircularProgressIndicator()
                  : Text('Arahkan kamera ke QR Code'),
            ),
          ),
        ],
      ),
    );
  }
}
