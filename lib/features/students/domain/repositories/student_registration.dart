import '../entities/student.dart';

class StudentRegistrationInput {
  const StudentRegistrationInput({
    required this.name,
    this.currentClassId,
    this.proposedClassId,
    this.approvalStatus,
    this.birthDate,
    this.phone,
    this.school,
    this.grade,
    this.isDeacon = false,
    this.enrollmentAt,
    this.photoPath,
    this.notes,
    this.sensitiveData = const {},
  });

  final String name;
  final String? currentClassId;
  final String? proposedClassId;
  final String? approvalStatus;
  final DateTime? birthDate;
  final String? phone;
  final String? school;
  final String? grade;
  final bool isDeacon;
  final DateTime? enrollmentAt;
  final String? photoPath;
  final String? notes;
  final Map<String, dynamic> sensitiveData;
}

abstract interface class StudentRegistration {
  Future<Student> registerPending({
    required String serviceId,
    required String proposedClassId,
    required String name,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
    bool isDeacon = false,
    DateTime? enrollmentAt,
    String? photoPath,
    String? notes,
    Map<String, dynamic> sensitiveData = const {},
  });

  Future<List<Student>> registerBatch({
    required String serviceId,
    String? currentClassId,
    String? proposedClassId,
    required List<StudentRegistrationInput> inputs,
  });
}
