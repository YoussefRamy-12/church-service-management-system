import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  AuthUser? _map(User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email,
      phone: user.phone,
    );
  }

  @override
  AuthUser? get currentUser => _map(_client.auth.currentUser);

  @override
  Stream<AuthUser?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => _map(event.session?.user));

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthException('تعذر تسجيل الدخول.');
    }

    return _map(user)!;
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}
