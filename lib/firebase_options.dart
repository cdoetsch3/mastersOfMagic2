import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

/// Firebase configuration for Masters of Magic 2. Only the web app is
/// registered so far (the platform Phase 1 ships on). The web `apiKey` is a
/// public client identifier, not a secret. Regenerate with
/// `firebase apps:sdkconfig` when adding mobile platforms.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Firebase is only configured for web so far. Register the '
      '${defaultTargetPlatform.name} app and add its options here.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCxrP_bHldRzeKhf90RnzArZ1DU3tKH57Q',
    appId: '1:764809462905:web:549057ef25e32da91780a8',
    messagingSenderId: '764809462905',
    projectId: 'mastersofmagic2',
    authDomain: 'mastersofmagic2.firebaseapp.com',
    storageBucket: 'mastersofmagic2.firebasestorage.app',
    measurementId: 'G-1R64J730Q5',
  );
}
