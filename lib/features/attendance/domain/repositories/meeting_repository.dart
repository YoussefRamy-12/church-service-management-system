import '../../../service/domain/entities/service.dart';
import '../entities/meeting.dart';

abstract interface class MeetingRepository {
  Stream<List<Meeting>> watchMeetings(String serviceId);
  Future<void> refresh(String serviceId);
  Future<Meeting> create({
    required String serviceId,
    required DateTime date,
    required String startTime,
    String name = 'اجتماع الخدمة',
    String? scheduleId,
    String? id,
  });
  Future<void> ensureConfiguredSchedule(Service service);
}
