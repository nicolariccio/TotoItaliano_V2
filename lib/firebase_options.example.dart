// Questo è un TEMPLATE. NON contiene credenziali reali.
//
// Per generare il vero file `lib/firebase_options.dart` (gitignored, mai
// da committare):
//   1. Installa la FlutterFire CLI:  dart pub global activate flutterfire_cli
//   2. Dalla root del progetto:      flutterfire configure
//   3. Seleziona/crea il progetto Firebase e le piattaforme (Android/iOS).
//
// Il comando genera automaticamente `lib/firebase_options.dart` con le
// chiavi corrette per ogni piattaforma. Quel file NON è un segreto nel
// senso classico (le API key client di Firebase sono per design visibili
// nel bundle dell'app), ma lo teniamo comunque fuori da Git per evitare
// di legare il repository pubblico a un progetto Firebase specifico e per
// permettere ambienti diversi (dev/staging/prod) senza conflitti.
//
// La vera protezione dei dati sta nelle Firestore Security Rules e nelle
// Cloud Functions, non nel nascondere questo file.

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'DefaultFirebaseOptions non è stato configurato. '
      'Esegui `flutterfire configure` per generare lib/firebase_options.dart.',
    );
  }
}
