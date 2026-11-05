import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCMEfHkmIKNB4aiLE0j4W_QPAiz_nt3fgA',
    appId: '1:884775143490:android:fa8917d2e4fcb78e1d05db',
    messagingSenderId: '884775143490',
    projectId: 'gautam-egg-store',
    storageBucket: 'gautam-egg-store.firebasestorage.app',
  );
}
