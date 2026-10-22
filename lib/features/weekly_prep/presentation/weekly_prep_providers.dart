import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_client_provider.dart';
import '../data/weekly_lesson_repository.dart';
import '../domain/weekly_lesson.dart';

final weeklyLessonRepositoryProvider = Provider<WeeklyLessonRepository>(
  (ref) => WeeklyLessonRepository(ref.watch(supabaseClientProvider)),
);

final weeklyLessonsProvider =
    FutureProvider.family<List<WeeklyLesson>, String>((ref, serviceId) {
  return ref.watch(weeklyLessonRepositoryProvider).list(serviceId);
});
