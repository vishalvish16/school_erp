// =============================================================================
// FILE: lib/firebase_options.dart
// PURPOSE: Firebase configuration for web and mobile.
// Generated from Firebase Console — web + Android apps.
// =============================================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (Platform.isAndroid) return android;
    if (Platform.isIOS) return ios;
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBNXatchHcc5u22a1NmhdqQPb7kdOJw0JI',
    appId: '1:551095455768:web:e870172d5c9359c4ee736d',
    messagingSenderId: '551095455768',
    projectId: 'school-erp-ai',
    authDomain: 'school-erp-ai.firebaseapp.com',
    storageBucket: 'school-erp-ai.firebasestorage.app',
    measurementId: 'G-ZKTBH2PQG1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBaVw4b5m66arG1VU-OKZqKpoFLEJ4SQXE',
    appId: '1:551095455768:android:d5231bc488e1fc0aee736d',
    messagingSenderId: '551095455768',
    projectId: 'school-erp-ai',
    storageBucket: 'school-erp-ai.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBNXatchHcc5u22a1NmhdqQPb7kdOJw0JI',
    appId: '1:551095455768:ios:PLACEHOLDER',
    messagingSenderId: '551095455768',
    projectId: 'school-erp-ai',
    storageBucket: 'school-erp-ai.firebasestorage.app',
    iosBundleId: 'com.schoolerp.schoolErpAdmin',
  );
}
