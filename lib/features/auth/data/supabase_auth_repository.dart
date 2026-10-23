import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final supabase.SupabaseClient _client;

  AuthUser? _map(supabase.User? user) {
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email, phone: user.phone);
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
      throw const supabase.AuthException('تعذر تسجيل الدخول.');
    }

    return _map(user)!;
  }

  @override
  Future<AuthUser> signUpServant({
    required String name,
    required String email,
    required String phone,
    required DateTime birthDate,
    required String workStudy,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'signup_type': 'servant',
        'full_name': name.trim(),
        'phone': phone.trim(),
        'birth_date': _formatDate(birthDate),
        'work_study': workStudy.trim(),
      },
      emailRedirectTo: _redirectUri('/auth/callback'),
    );
    final user = response.user;
    if (user == null) {
      throw const supabase.AuthException('تعذر إنشاء الحساب.');
    }
    return _map(user)!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _redirectUri('/reset-password'),
    );
  }

  @override
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(supabase.UserAttributes(password: password));
  }

  String _redirectUri(String path) {
    final origin = Uri.base.origin;
    if (origin == 'null') {
      throw const supabase.AuthException(
        'تعذر تحديد عنوان التطبيق لإرسال رابط آمن.',
      );
    }
    return '$origin$path';
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Future<void> signOut() => _client.auth.signOut();
}
