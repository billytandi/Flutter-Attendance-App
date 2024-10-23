// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:skripsi/models/attendance.dart';
import 'package:skripsi/views/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:skripsi/views/attendance_history.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inisialisasi Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPILintern',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
    );
  }
}
