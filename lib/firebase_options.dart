import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Configurazione Firebase del progetto `totoitaliano-aa72e`.
///
/// Per ora solo la parte web (usata dalla build pubblicata su Firebase
/// Hosting): sono identificativi pubblici, non segreti — la protezione dei
/// dati sta nelle Security Rules (`firestore.rules`). Android/iOS verranno
/// aggiunti rieseguendo `flutterfire configure`, che rigenera questo file.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
        'Configurazione Firebase disponibile solo per il web: esegui '
        '`flutterfire configure` per Android/iOS.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAg6RUwClJjZ7pDr-yaHzs0b6KPmWhSo9s',
    appId: '1:426909825335:web:a6009844833f5c764e82b2',
    messagingSenderId: '426909825335',
    projectId: 'totoitaliano-aa72e',
    authDomain: 'totoitaliano-aa72e.firebaseapp.com',
    storageBucket: 'totoitaliano-aa72e.firebasestorage.app',
  );
}
