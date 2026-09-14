import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_role.dart';

part 'app_user.freezed.dart';

/// Profilo utente TotoItaliano, persistito in `users/{uid}`.
///
/// Distinto dal `User` di FirebaseAuth (quello rappresenta solo l'identità
/// autenticata; questo rappresenta il profilo/le statistiche di dominio).
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    String? photoUrl,
    required String referralCode,
    String? referredBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(UserRole.user) UserRole role,
    @Default(0) int totalPoints,
    @Default(0) int predictionsCount,
    @Default(0) int correctPredictions,
    @Default(0) int exactPredictions,
    @Default(0.0) double successRate,
    @Default(true) bool isActive,
    // Quante leghe l'utente ha creato/a cui ha aderito. Serve a far
    // rispettare lato server la regola "serve una lega per pronosticare"
    // (vedi firestore.rules): incrementato solo dalle transazioni di
    // creazione/adesione a una lega, mai scrivibile liberamente dal client.
    @Default(0) int leagueCount,
  }) = _AppUser;

  const AppUser._();

  String get fullName => '$firstName $lastName'.trim();
}
