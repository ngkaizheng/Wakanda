// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBeV0neM8rnMM_vMjqWtEGc70ci_l4HBb0',
    appId: '1:630749909011:web:e22fde75a384ad9b8eafe6',
    messagingSenderId: '630749909011',
    projectId: 'human-resource-pjt',
    authDomain: 'human-resource-pjt.firebaseapp.com',
    storageBucket: 'human-resource-pjt.appspot.com',
    measurementId: 'G-WHLLX9F45N',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDmi-oGA0dXvEwGfu-jah1bzhkBouwP8uU',
    appId: '1:630749909011:android:154adf1bf0552b218eafe6',
    messagingSenderId: '630749909011',
    projectId: 'human-resource-pjt',
    storageBucket: 'human-resource-pjt.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAdtuo6nKzb-TT2HFrDPZ1c5g55L5G9HzI',
    appId: '1:630749909011:ios:0d09c9986f3cd87e8eafe6',
    messagingSenderId: '630749909011',
    projectId: 'human-resource-pjt',
    storageBucket: 'human-resource-pjt.appspot.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAdtuo6nKzb-TT2HFrDPZ1c5g55L5G9HzI',
    appId: '1:630749909011:ios:01a9bcc5b0f018dc8eafe6',
    messagingSenderId: '630749909011',
    projectId: 'human-resource-pjt',
    storageBucket: 'human-resource-pjt.appspot.com',
    iosBundleId: 'com.example.flutterApplication1.RunnerTests',
  );
}