import '../entities/student.dart';

abstract interface class StudentRepository {
  Stream<List<Student>> watchStudentsForClass(String classId);
}
