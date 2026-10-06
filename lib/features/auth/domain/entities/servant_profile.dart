class ServantProfile {
  const ServantProfile({
    required this.id,
    required this.authUserId,
    required this.serviceId,
    required this.name,
    required this.role,
    required this.accountStatus,
    this.phone,
    this.birthDate,
    this.workStudy,
    this.stageId,
    this.classId,
    this.mustChangePassword = false,
  });

  final String id;
  final String authUserId;
  final String serviceId;
  final String name;
  final String role;
  final String accountStatus;
  final String? phone;
  final DateTime? birthDate;
  final String? workStudy;
  final String? stageId;
  final String? classId;
  final bool mustChangePassword;

  bool get isActive => accountStatus == 'active';
  bool get isPending => accountStatus == 'pending';
  bool get isInactive => accountStatus == 'inactive';
}
