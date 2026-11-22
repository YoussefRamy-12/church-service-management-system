import '../entities/sensitive_student_data.dart';
import '../entities/student.dart';

abstract interface class StudentRepository {
  Stream<List<Student>> watchStudentsForClass(String classId);
  Stream<List<Student>> watchStudentsForService(String serviceId);
  Future<void> refreshStudents(String classId);
  Future<void> refreshStudentsForService(String serviceId);
  Future<Student> updateStudent({
    required String studentId,
    required String name,
    String? membershipId,
    DateTime? birthDate,
    String? phone,
    String? school,
    String? grade,
    bool? isDeacon,
    DateTime? enrollmentAt,
    String? photoPath,
    String? notes,
    SensitiveStudentData? sensitiveData,
  });
  Future<Student> approvePending(String studentId, {String? membershipId});
  Future<void> deleteStudent(String studentId, {String? membershipId});
  Future<Student> assignClass(String studentId, String classId, {String? membershipId});
  Future<SensitiveStudentData?> getSensitiveData(String studentId);
}
