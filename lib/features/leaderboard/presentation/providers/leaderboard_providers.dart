import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_repository_provider.dart';

final StreamProvider<List<AppUser>> leaderboardProvider = StreamProvider<List<AppUser>>(
  (ref) => ref.watch(userFirestoreDatasourceProvider).watchLeaderboard(),
);
