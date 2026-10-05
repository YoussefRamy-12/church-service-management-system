class SystemAdminProfile {
  const SystemAdminProfile({
    required this.id,
    required this.authUserId,
    required this.status,
  });

  final String id;
  final String authUserId;
  final String status;

  bool get isActive => status == 'active';
}
