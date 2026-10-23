import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;

  Future<AuthUser> signIn({required String email, required String password});

  Future<AuthUser> signUpServant({
    required String name,
    required String email,
    required String phone,
    required DateTime birthDate,
    required String workStudy,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> updatePassword(String password);

  Future<void> signOut();
}
