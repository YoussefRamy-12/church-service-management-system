import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../data/servant_profile_repository.dart';
import '../data/session_identity_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/entities/auth_user.dart';
import '../domain/entities/session_identity.dart';
import '../domain/entities/servant_profile.dart';
import '../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final servantProfileRepositoryProvider =
    Provider<ServantProfileRepository>((ref) {
  return ServantProfileRepository(ref.watch(supabaseClientProvider));
});

final sessionIdentityRepositoryProvider =
    Provider<SessionIdentityRepository>((ref) {
  return SessionIdentityRepository(ref.watch(supabaseClientProvider));
});

final authUserProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentAuthUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});

final currentSessionIdentityProvider =
    FutureProvider<SessionIdentity?>((ref) async {
  final user = ref.watch(currentAuthUserProvider);
  if (user == null) return null;

  return ref.watch(sessionIdentityRepositoryProvider).resolve(user.id);
});

final currentServantProfileProvider =
    FutureProvider<ServantProfile?>((ref) async {
  final identity = await ref.watch(currentSessionIdentityProvider.future);
  return switch (identity) {
    ServantIdentity(:final profile) => profile,
    _ => null,
  };
});
