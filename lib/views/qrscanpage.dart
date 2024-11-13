import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:skripsi/views/home.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skripsi/models/haversine.dart'; // Make sure this is the correct path

class QRScanPage extends StatefulWidget {
  @override
  _QRScanPageState createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final GlobalKey qrKey = GlobalKey();
  QRViewController? controller;
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
      double qrLat = -6.315686743038531;
      double qrLon =  106.79367588428302;

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
        double userLat = position.latitude;
        double userLon = position.longitude;

        // Calculate the distance using Haversine
        double distance = rangeKantor(qrLat, qrLon, userLat, userLon);
        print("Calculated distance to office: $distance meters");
        print("User location: Latitude $userLat, Longitude $userLon");
        print("Office location: Latitude $qrLat, Longitude $qrLon");

        // Check if the user is within 50 meters of the office
        if (distance > 15) {
          // Show error if not within the range and exit the function
          print("User is outside the 15-meter range. Attendance not recorded.");

          // Show a pop-up notification with the distance information
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Jangkauan Absensi Tidak Cukup'),
              content: Text(
                'Anda berada di luar jangkauan absensi.\n'
                'Jarak ke lokasi absensi: ${distance.toStringAsFixed(2)} meter.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );

          return; // Stop the function if the user is out of range
        }

        // Proceed with recording attendance if within range
        await FirebaseFirestore.instance.collection('attendance').add({
          'qr_code': qrCode,
          'location_from_qr': location,
          'checkin': DateTime.now(),
          'location': {
            'latitude': userLat,
            'longitude': userLon,
          },
          'employee_name': employeeName,
          'uid': user.uid,
          'status': 'Hadir'
        });

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Absensi Berhasil'),
            content: Text('Selamat Pagi $employeeName di $location!\n'
                            'Jarak ke lokasi absensi: ${distance.toStringAsFixed(2)} meter.',
            ),
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
    } finally {
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
