import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/weekly_lesson.dart';

class WeeklyLessonRepository {
  WeeklyLessonRepository(this._client);
  static const bucket = 'weekly-lessons';
  final SupabaseClient _client;

  Future<List<WeeklyLesson>> list(String serviceId) async {
    final rows = await _client
        .from('weekly_lessons')
        .select()
        .eq('service_id', serviceId)
        .order('week_start', ascending: false);
    return (rows as List)
        .map((row) => WeeklyLesson.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> save({
    required String serviceId,
    required String stageId,
    required DateTime weekStart,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final normalizedStart = DateTime.utc(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );
    final week = _date(normalizedStart);
    final previous = await _client
        .from('weekly_lessons')
        .select('id,storage_path')
        .eq('stage_id', stageId)
        .eq('week_start', week)
        .maybeSingle();
    final path = '$serviceId/$stageId/$week/${const Uuid().v4()}.pdf';
    await _client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'application/pdf',
        cacheControl: '3600',
        upsert: false,
      ),
    );
    try {
      final payload = {
        'service_id': serviceId,
        'stage_id': stageId,
        'week_start': week,
        'storage_path': path,
        'file_name': fileName,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      if (previous == null) {
        await _client.from('weekly_lessons').insert(payload);
      } else {
        await _client
            .from('weekly_lessons')
            .update(payload)
            .eq('id', previous['id']);
      }
    } catch (_) {
      await _client.storage.from(bucket).remove([path]);
      rethrow;
    }
    final oldPath = previous?['storage_path'] as String?;
    if (oldPath != null && oldPath != path) {
      try {
        await _client.storage.from(bucket).remove([oldPath]);
      } catch (_) {
        // The metadata points at the new upload; an orphan can be cleaned up later.
      }
    }
  }

  Future<void> delete(WeeklyLesson lesson) async {
    await _client.from('weekly_lessons').delete().eq('id', lesson.id);
    await _client.storage.from(bucket).remove([lesson.storagePath]);
  }

  Future<Uri> signedUrl(WeeklyLesson lesson, {required bool download}) async {
    final url = await _client.storage.from(bucket).createSignedUrl(
      lesson.storagePath,
      300,
      download: download ? DownloadBehavior.withOriginalName : null,
    );
    return Uri.parse(url);
  }

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
