import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../data/online_attendance_repository.dart';
import '../domain/repositories/attendance_repository.dart';

/// Attendance is read and written directly against Supabase.
final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => OnlineAttendanceRepository(ref.watch(supabaseClientProvider)),
);
