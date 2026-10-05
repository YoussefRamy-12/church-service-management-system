import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../data/servant_profile_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/entities/auth_user.dart';
import '../domain/entities/servant_profile.dart';
import '../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final servantProfileRepositoryProvider =
    Provider<ServantProfileRepository>((ref) {
  return ServantProfileRepository(ref.watch(supabaseClientProvider));
});

final authUserProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentAuthUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

final currentServantProfileProvider =
    FutureProvider<ServantProfile?>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return null;

  return ref
      .watch(servantProfileRepositoryProvider)
      .getCurrentProfile(user.id);
});
