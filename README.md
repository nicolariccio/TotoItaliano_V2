# TotoItaliano

> "Il calcio italiano, la tua sfida."

Piattaforma mobile di pronostici calcistici (Serie A) — Flutter + Firebase.

## Stato del progetto

**Phase 1 — Project setup** completata. Vedi [ROADMAP](#roadmap) sotto per lo stato delle fasi successive.

Le schermate delle feature non ancora implementate mostrano un placeholder
con l'indicazione della fase in cui verranno costruite (vedi
`lib/core/widgets/placeholder_screen.dart`) — la navigazione end-to-end
funziona già tra tutte le sezioni.

## Setup ambiente locale

Questo repository è stato creato **senza** Flutter SDK disponibile in
ambiente di sviluppo: il codice Dart/Flutter è scritto a mano seguendo le
convenzioni standard, ma non è ancora stato validato con `flutter analyze`
/ `flutter test` / `flutter build`. Prima di continuare lo sviluppo:

1. **Installa Flutter** (canale stable): https://docs.flutter.dev/get-started/install
   ```bash
   flutter doctor
   ```

2. **Genera i progetti nativi Android/iOS** (non versionati a mano: contengono
   file binari/generati da `flutter create`). Dalla root del repo:
   ```bash
   flutter create . --project-name totoitaliano --org com.totoitaliano
   ```
   Questo comando è "additivo": non tocca `lib/`, `pubspec.yaml` o gli altri
   file già presenti, crea solo `android/`, `ios/`, ecc.

3. **Installa le dipendenze**:
   ```bash
   flutter pub get
   ```

4. **Configura Firebase** (Auth, Firestore, Functions, FCM, Storage, Analytics):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Genera `lib/firebase_options.dart` (gitignored di proposito, vedi
   `lib/firebase_options.example.dart` per i dettagli). Serve un progetto
   Firebase reale (Blaze plan se userai le Cloud Functions).

5. **Genera il codice** (freezed/json_serializable/riverpod_generator, da
   Phase 2 in poi quando verranno introdotti i modelli):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

6. **Verifica**:
   ```bash
   flutter analyze
   flutter test
   flutter run
   ```

## Architettura

Clean architecture modulare, per feature:

```
lib/
  core/          theme, routing, errors, costanti, widget condivisi
  data/          modelli/repository/datasource condivisi (introdotti dalla Phase 3)
  features/
    auth/
    home/
    predictions/
    leaderboard/
    leagues/
    profile/
    competitions/
    referrals/
    payments/
  ognuna con data/ domain/ presentation/
```

- **State management**: Riverpod (provider + notifier), niente mix con altri
  approcci.
- **Routing**: `go_router` centralizzato in `lib/core/routing/app_router.dart`,
  con redirect guard basato su stato di autenticazione (Firebase Auth) e
  onboarding completato. Bottom navigation a 5 tab tramite
  `StatefulShellRoute.indexedStack`.
- **Backend**: Firebase (Auth, Firestore, Functions, FCM, Storage, Analytics).
  La logica sensibile (scoring, lock pronostici, validazione referral/lega)
  vive **lato Cloud Functions**, mai fidandosi del client.

## Roadmap

- [x] Phase 1 — Project setup, architettura, tema, routing
- [ ] Phase 2 — Authentication (email/password, Google Sign-In, profilo)
- [ ] Phase 3 — Competizioni, squadre, giornate, partite (mock football API)
- [ ] Phase 4 — Motore pronostici, UI, persistenza, lock a kickoff
- [ ] Phase 5 — Scoring engine, risultati, classifiche
- [ ] Phase 6 — Leghe private, invite code, membri
- [ ] Phase 7 — Referral, pagamenti (architettura), premi
- [ ] Phase 8 — Notifiche push, analytics
- [ ] Phase 9 — Firestore Security Rules, Cloud Functions, validazione
- [ ] Phase 10 — Test, bug fixing, performance, rifinitura UX

## Note di sicurezza

- Nessuna credenziale, API key privata o secret è versionata nel repository
  (vedi `.gitignore`).
- `lib/firebase_options.dart` è generato localmente da ciascun sviluppatore
  via `flutterfire configure` e non viene committato.
- Le Cloud Functions (cartella `functions/`, Phase 9) useranno
  `functions/.env` (gitignored) per eventuali secret (es. provider di
  pagamento), mai valori hardcoded nel codice.
