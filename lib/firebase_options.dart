/// Firebase configuration for DivinePath AI
///
/// This file was manually created from the Firebase Console configs.
/// In production, use `flutterfire configure` to regenerate this file.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ios;
    }
    return web;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD798gEQr4_Xgb3zY3Y1qMP6HVYuGLHTTk',
    appId: '1:366379144599:android:a7608ccda4149ad1c120d2',
    messagingSenderId: '366379144599',
    projectId: 'divinepathai-3f1cd',
    storageBucket: 'divinepathai-3f1cd.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD798gEQr4_Xgb3zY3Y1qMP6HVYuGLHTTk',
    appId: '1:366379144599:android:a7608ccda4149ad1c120d2',
    messagingSenderId: '366379144599',
    projectId: 'divinepathai-3f1cd',
    storageBucket: 'divinepathai-3f1cd.firebasestorage.app',
    iosBundleId: 'com.divinepath.ai',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBNUnKi4fF9EwtiyCiwj9ANMudiW0m_dfw',
    authDomain: 'divinepathai-3f1cd.firebaseapp.com',
    appId: '1:366379144599:web:cbb746986470e2ddc120d2',
    messagingSenderId: '366379144599',
    projectId: 'divinepathai-3f1cd',
    storageBucket: 'divinepathai-3f1cd.firebasestorage.app',
    measurementId: 'G-YEXJYBNRGQ',
  );
}
