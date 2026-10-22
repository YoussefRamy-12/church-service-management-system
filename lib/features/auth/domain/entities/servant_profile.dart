import 'package:flutter/foundation.dart';

@immutable
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

  ServantProfile copyWith({
    String? id,
    String? authUserId,
    String? serviceId,
    String? name,
    String? role,
    String? accountStatus,
    String? phone,
    DateTime? birthDate,
    String? workStudy,
    String? stageId,
    String? classId,
    bool? mustChangePassword,
  }) {
    return ServantProfile(
      id: id ?? this.id,
      authUserId: authUserId ?? this.authUserId,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      role: role ?? this.role,
      accountStatus: accountStatus ?? this.accountStatus,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      workStudy: workStudy ?? this.workStudy,
      stageId: stageId ?? this.stageId,
      classId: classId ?? this.classId,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServantProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serviceId == other.serviceId;

  @override
  int get hashCode => id.hashCode ^ serviceId.hashCode;
}
