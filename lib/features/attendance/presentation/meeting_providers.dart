import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../data/online_meeting_repository.dart';
import '../domain/repositories/meeting_repository.dart';

/// Attendance meetings are read and written directly against Supabase.
final meetingRepositoryProvider = Provider<MeetingRepository>(
  (ref) => OnlineMeetingRepository(ref.watch(supabaseClientProvider)),
);
