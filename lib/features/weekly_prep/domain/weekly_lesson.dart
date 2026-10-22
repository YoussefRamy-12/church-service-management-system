class WeeklyLesson {
  const WeeklyLesson({
    required this.id,
    required this.serviceId,
    required this.stageId,
    required this.weekStart,
    required this.storagePath,
    required this.fileName,
    required this.updatedAt,
  });

  final String id;
  final String serviceId;
  final String stageId;
  final DateTime weekStart;
  final String storagePath;
  final String fileName;
  final DateTime updatedAt;

  factory WeeklyLesson.fromJson(Map<String, dynamic> json) => WeeklyLesson(
    id: json['id'] as String,
    serviceId: json['service_id'] as String,
    stageId: json['stage_id'] as String,
    weekStart: DateTime.parse(json['week_start'] as String),
    storagePath: json['storage_path'] as String,
    fileName: json['file_name'] as String,
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}
