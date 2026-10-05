import '../domain/entities/student.dart';
import '../domain/repositories/student_repository.dart';
import 'local_student_repository.dart';
import 'supabase_student_repository.dart';

class OfflineFirstStudentRepository implements StudentRepository {
  OfflineFirstStudentRepository({
    required this.local,
    required this.remote,
  });

  final LocalStudentRepository local;
  final SupabaseStudentRepository remote;

  @override
  Stream<List<Student>> watchStudentsForClass(String classId) =>
      local.watchStudentsForClass(classId);

  Future<void> refreshStudents(String classId) async {
    final values = await remote.fetchStudentsForClass(classId);
    await local.cacheStudents(values);
  }
}
