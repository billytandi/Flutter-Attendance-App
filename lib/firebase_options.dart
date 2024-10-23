// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB42FTzBVIAVz2ssUm7-8V-OhT-IOS7raQ',
    appId: '1:627962989643:web:5fe7137a24848d3b27d1ce',
    messagingSenderId: '627962989643',
    projectId: 'attendance-app-f9eae',
    authDomain: 'attendance-app-f9eae.firebaseapp.com',
    storageBucket: 'attendance-app-f9eae.appspot.com',
    measurementId: 'G-XTTF81E9BE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCXoTCUoA0lnphvyWYG_ZIlNmm0CjX26SY',
    appId: '1:627962989643:android:0009bfa03b0473b327d1ce',
    messagingSenderId: '627962989643',
    projectId: 'attendance-app-f9eae',
    storageBucket: 'attendance-app-f9eae.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDsVzezeDiHsztIybdnW_9zLi1Ra8aGWME',
    appId: '1:627962989643:ios:370cdb8c6f199c0c27d1ce',
    messagingSenderId: '627962989643',
    projectId: 'attendance-app-f9eae',
    storageBucket: 'attendance-app-f9eae.appspot.com',
    iosBundleId: 'com.example.skripsi',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDsVzezeDiHsztIybdnW_9zLi1Ra8aGWME',
    appId: '1:627962989643:ios:370cdb8c6f199c0c27d1ce',
    messagingSenderId: '627962989643',
    projectId: 'attendance-app-f9eae',
    storageBucket: 'attendance-app-f9eae.appspot.com',
    iosBundleId: 'com.example.skripsi',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB42FTzBVIAVz2ssUm7-8V-OhT-IOS7raQ',
    appId: '1:627962989643:web:e46a2fbd6116aa2727d1ce',
    messagingSenderId: '627962989643',
    projectId: 'attendance-app-f9eae',
    authDomain: 'attendance-app-f9eae.firebaseapp.com',
    storageBucket: 'attendance-app-f9eae.appspot.com',
    measurementId: 'G-JCP8XSLND9',
  );

}