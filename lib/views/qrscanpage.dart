import 'dart:convert';
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
  bool isProcessing = false;

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
    } else {
      controller!.resumeCamera();
    }
  }

  Future<void> _recordAttendance(String qrCode) async {
    setState(() {
      isProcessing = true;
    });

    try {
      // Decode QR Code
      Map<String, dynamic> qrData = jsonDecode(qrCode);
      String location = qrData['location'];

      // Get UID
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot employeeSnapshot = await FirebaseFirestore.instance
            .collection('employees')
            .doc(user.uid)
            .get();

        String employeeName = employeeSnapshot['name'];

        // Get current location
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        // Record attendance
        await FirebaseFirestore.instance.collection('attendance').add({
          'qr_code': qrCode,
          'location_from_qr': location,
          'timestamp': DateTime.now(),
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'employee_name': employeeName,
          'uid': user.uid,
          'status' : 'Hadir'
        });

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Absensi Berhasil'),
            content: Text(
                'Selamat Pagi $employeeName di $location!'),
            actions: [
              TextButton(
                onPressed: () {
                  controller?.pauseCamera();
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Home()),
                    (Route<dynamic> route) => false,
                  );
                  setState(() {
                    isProcessing = false;
                  });
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User tidak ditemukan, silakan login kembali'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal memproses absensi: $e'),
      ));
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
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
                    _recordAttendance(scanData.code!);
                  }
                });
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Arahkan kamera ke QR Code'),
            ),
          ),
        ],
      ),
    );
  }
}
