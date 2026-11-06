/// Converts an attendance timestamp returned by Supabase to the device's
/// local time. Before the UTC serialization fix shipped, this app sent local
/// wall-clock values without an offset, which Postgres interpreted as UTC.
/// Keep those older values as local wall time until they are edited by the
/// fixed client (the update trigger refreshes `updated_at`).
final _utcWriteCutover = DateTime.utc(2026, 11, 6, 12, 40);

DateTime attendanceTimestampFromRow(Map<String, dynamic> row) {
  final stored = DateTime.parse(row['checked_in_at'] as String);
  final lastChangedValue = row['updated_at'] ?? row['created_at'];
  final lastChanged = lastChangedValue == null
      ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
      : DateTime.parse(lastChangedValue as String).toUtc();

  if (lastChanged.isBefore(_utcWriteCutover)) {
    return DateTime(
      stored.year,
      stored.month,
      stored.day,
      stored.hour,
      stored.minute,
      stored.second,
      stored.millisecond,
      stored.microsecond,
    );
  }
  return stored.toLocal();
}
