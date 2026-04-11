// Configuration Firebase pour Flutter (format FlutterFire).
// Android : sn.dudu.client (google-services.json).
// iOS : bundle Xcode = sn.dudugroup.app — les constantes ci-dessous doivent correspondre
// à l’app iOS enregistrée dans la console Firebase pour ce bundle.
// Si l’init échoue encore : télécharge un nouveau GoogleService-Info.plist pour
// sn.dudugroup.app puis exécute : flutterfire configure -p dudu-8b229 --platforms=android,ios -y

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions n’est pas configuré pour le web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne gère pas cette plateforme.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAsSvfRk2J3uruLV_DG17H4O5vxF8QAj40',
    appId: '1:118330330401:android:2d94088d558a04b791c260',
    messagingSenderId: '118330330401',
    projectId: 'dudu-8b229',
    storageBucket: 'dudu-8b229.firebasestorage.app',
  );

  /// Doit correspondre à l’app iOS « sn.dudugroup.app » dans Firebase (même GOOGLE_APP_ID).
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCZAHfO0AGQn_nqVUk0SKU6mIulyNLKZmQ',
    appId: '1:118330330401:ios:3e0f77a7799c886291c260',
    messagingSenderId: '118330330401',
    projectId: 'dudu-8b229',
    storageBucket: 'dudu-8b229.firebasestorage.app',
    iosBundleId: 'sn.dudugroup.app',
  );
}
