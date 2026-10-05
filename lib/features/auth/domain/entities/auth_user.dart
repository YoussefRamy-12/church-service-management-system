class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.phone,
  });

  final String id;
  final String? email;
  final String? phone;
}
