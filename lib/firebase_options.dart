// Generated from Firebase project `maeumkok`. Re-generate with `flutterfire configure`
// after enabling Google Sign-In (adds OAuth client IDs).
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('MaeumKok supports Android and iOS only.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXNe-G3mEO-2tXEvgMRsLc9a6GrAolUts',
    appId: '1:101787008056:android:c65d9ce23cb93a05b6facd',
    messagingSenderId: '101787008056',
    projectId: 'maeumkok',
    storageBucket: 'maeumkok.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAxisZd9tfXCbDtmMqtnr5070hMclxFbzE',
    appId: '1:101787008056:ios:7ad6dba0e711666ab6facd',
    messagingSenderId: '101787008056',
    projectId: 'maeumkok',
    storageBucket: 'maeumkok.firebasestorage.app',
    iosBundleId: 'com.maeumkok.app',
    iosClientId: '101787008056-roc9s1msovau5fjcinl0ik244nu8qcdm.apps.googleusercontent.com',
  );
}
