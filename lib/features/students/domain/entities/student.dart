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
  final DateTime? enrollmentAt;
  final String? photoPath;
  final String? notes;

  bool get isApproved => approvalStatus == 'approved';
  bool get isPending => approvalStatus == 'pending';
}
