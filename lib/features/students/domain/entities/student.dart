import 'package:flutter/foundation.dart';

@immutable
class Student {
  const Student({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.approvalStatus,
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

  Student copyWith({
    String? id,
    String? serviceId,
    String? name,
    String? approvalStatus,
    String? currentClassId,
    String? proposedClassId,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
    bool? isDeacon,
    DateTime? enrollmentAt,
    String? photoPath,
    String? notes,
  }) {
    return Student(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      currentClassId: currentClassId ?? this.currentClassId,
      proposedClassId: proposedClassId ?? this.proposedClassId,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      isDeacon: isDeacon ?? this.isDeacon,
      enrollmentAt: enrollmentAt ?? this.enrollmentAt,
      photoPath: photoPath ?? this.photoPath,
      notes: notes ?? this.notes,
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
