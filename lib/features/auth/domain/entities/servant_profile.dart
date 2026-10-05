class ServantProfile {
  const ServantProfile({
    required this.id,
    required this.authUserId,
    required this.serviceId,
    required this.name,
    required this.role,
    required this.accountStatus,
    this.stageId,
    this.classId,
  });

  final String id;
  final String authUserId;
  final String serviceId;
  final String name;
  final String role;
  final String accountStatus;
  final String? stageId;
  final String? classId;

  bool get isActive => accountStatus == 'active';
  bool get isPending => accountStatus == 'pending';
}
