import '../entities/follow_up_record.dart';

/// Domain contract for follow-up operations.
abstract interface class FollowUpRepository {
  Stream<List<FollowUpRecord>> watchForStudent(
    String studentId, {
    String? serviceId,
  });
  Future<FollowUpRecord> create({
    required String studentId,
    required String serviceId,
    required String serviceStudentId,
    required String createdBy,
    required String followUpDate,
    required String contactStatus,
    String? contactMethod,
    String? absenceReason,
    String? studentResponse,
    String? parentResponse,
    String? actionRequired,
    String? notes,
    bool anotherFollowUpNeeded = false,
    String? nextFollowUpDate,
  });
}
