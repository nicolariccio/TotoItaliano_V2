import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/user_firestore_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

final Provider<FirebaseAuthDatasource> firebaseAuthDatasourceProvider =
    Provider<FirebaseAuthDatasource>(
  (ref) => FirebaseAuthDatasource(ref.watch(firebaseAuthProvider)),
);

final Provider<UserFirestoreDatasource> userFirestoreDatasourceProvider =
    Provider<UserFirestoreDatasource>(
  (ref) => UserFirestoreDatasource(FirebaseFirestore.instance),
);

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(firebaseAuthDatasourceProvider),
    ref.watch(userFirestoreDatasourceProvider),
  ),
);
