import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase config for project fixxi-f0d1c (from google-services.json).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Fixxi web is not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('Fixxi iOS is not configured.');
      default:
        throw UnsupportedError('Fixxi is not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDXtxdyNwlCvcHGMFpL-l8Vbdc_0UJqQMc',
    appId: '1:650990252791:android:42ce9956ebc952b60e19f2',
    messagingSenderId: '650990252791',
    projectId: 'fixxi-f0d1c',
    storageBucket: 'fixxi-f0d1c.firebasestorage.app',
  );
}
