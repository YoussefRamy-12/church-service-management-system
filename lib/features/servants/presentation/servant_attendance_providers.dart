import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../data/servant_attendance_repository.dart';

final servantAttendanceRepositoryProvider =
    Provider<ServantAttendanceRepository>(
  (ref) => ServantAttendanceRepository(ref.watch(supabaseClientProvider)),
);
