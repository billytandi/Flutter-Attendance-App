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
  bool isProcessing = false; // Mencegah pemrosesan ganda
  bool hasShownOutOfRangeNotification = false; // Mencegah notifikasi ganda

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
    if (isProcessing) return; // Mencegah pemrosesan ulang
    setState(() {
      isProcessing = true;
    });

    try {
      // Periksa apakah layanan lokasi aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        _showSnackBar('Aktifkan layanan lokasi untuk melanjutkan.');
        return;
      }

      // Decode QR Code
      Map<String, dynamic> qrData = jsonDecode(qrCode);
      String location = qrData['location'];
      double qrLat = -6.112721;
      double qrLon = 106.881920;

      double kampusLat = -6.316056;
      double kampusLon = 106.79497;

      // Get UID
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot employeeSnapshot = await FirebaseFirestore.instance
            .collection('employees')
            .doc(user.uid)
            .get();

        String employeeName = employeeSnapshot['name'];

        // Periksa izin lokasi
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.deniedForever) {
            _showSnackBar('Izin lokasi ditolak secara permanen.');
            return;
          }
        }

        // Ambil lokasi saat ini
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );


        double userLat = position.latitude;
        double userLon = position.longitude;

        // Cek apakah menggunakan lokasi palsu
        if (position.isMocked) {
          _showSnackBar('Lokasi palsu terdeteksi. Matikan aplikasi Fake GPS.');
          return;
        }

        // Hitung jarak dengan Haversine
        double distance = rangeKantor(qrLat, qrLon, userLat, userLon);
        print("Calculated distance to office: $distance meters");
        print("User location: Latitude $userLat, Longitude $userLon");
        print("Office location: Latitude $qrLat, Longitude $qrLon");


        // Validasi jarak
        if (distance > 20) {
          if (!hasShownOutOfRangeNotification) {
            hasShownOutOfRangeNotification = true;

            // Tampilkan pop-up jika di luar jangkauan
            await showDialog(
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
                      Navigator.of(context).pop();
                      controller?.dispose(); // Tutup kamera
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => Home()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }

        // Reset flag jika jarak dalam jangkauan
        hasShownOutOfRangeNotification = false;

        // Rekam data absensi jika di dalam jangkauan
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

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Absensi Berhasil'),
            content: Text(
              'Selamat Pagi $employeeName di $location!\n'
              'Jarak ke lokasi absensi: ${distance.toStringAsFixed(2)} meter.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller?.dispose(); // Tutup kamera
                  Navigator.of(context).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => Home()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar('User tidak ditemukan, silakan login kembali');
      }
    } catch (e) {
      _showSnackBar('Gagal memproses absensi: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      isProcessing = false;
    });
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
