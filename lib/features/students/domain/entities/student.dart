import 'package:flutter/foundation.dart';

@immutable
class Student {
  const Student({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.approvalStatus,
    this.membershipId,
    this.identityServiceId,
    this.membershipStatus = 'active',
    this.currentClassId,
    this.proposedClassId,
    this.birthDate,
    this.phone,
    this.school,
    this.grade,
    this.isDeacon = false,
    this.enrollmentAt,
    this.photoPath,
    this.notes,
  });

  final String id;
  final String serviceId;
  final String name;
  final String approvalStatus;
  final String? membershipId;
  final String? identityServiceId;
  final String membershipStatus;
  final String? currentClassId;
  final String? proposedClassId;
  final DateTime? birthDate;
  final String? phone;
  final String? school;
  final String? grade;
  final bool isDeacon;
  final DateTime? enrollmentAt;
  final String? photoPath;
  final String? notes;

  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';

  static const Object _unset = Object();

  Student copyWith({
    String? id,
    String? serviceId,
    String? name,
    String? approvalStatus,
    Object? membershipId = _unset,
    Object? identityServiceId = _unset,
    String? membershipStatus,
    Object? currentClassId = _unset,
    Object? proposedClassId = _unset,
    Object? birthDate = _unset,
    Object? phone = _unset,
    Object? school = _unset,
    Object? grade = _unset,
    bool? isDeacon,
    Object? enrollmentAt = _unset,
    Object? photoPath = _unset,
    Object? notes = _unset,
  }) {
    return Student(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      membershipId: identical(membershipId, _unset)
          ? this.membershipId
          : membershipId as String?,
      identityServiceId: identical(identityServiceId, _unset)
          ? this.identityServiceId
          : identityServiceId as String?,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      currentClassId: identical(currentClassId, _unset)
          ? this.currentClassId
          : currentClassId as String?,
      proposedClassId: identical(proposedClassId, _unset)
          ? this.proposedClassId
          : proposedClassId as String?,
      birthDate: identical(birthDate, _unset)
          ? this.birthDate
          : birthDate as DateTime?,
      phone: identical(phone, _unset) ? this.phone : phone as String?,
      school: identical(school, _unset) ? this.school : school as String?,
      grade: identical(grade, _unset) ? this.grade : grade as String?,
      isDeacon: isDeacon ?? this.isDeacon,
      enrollmentAt: identical(enrollmentAt, _unset)
          ? this.enrollmentAt
          : enrollmentAt as DateTime?,
      photoPath: identical(photoPath, _unset)
          ? this.photoPath
          : photoPath as String?,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serviceId == other.serviceId;

  @override
  int get hashCode => id.hashCode ^ serviceId.hashCode;
}
