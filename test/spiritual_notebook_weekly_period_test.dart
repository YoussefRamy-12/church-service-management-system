import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/features/spiritual_notebook/domain/weekly_period.dart';

void main() {
  group('Friday-to-Thursday period', () {
    test('Friday begins a new period', () {
      final p = WeeklyPeriod.containing(DateTime(2026, 11, 6, 23, 59));
      expect(p.start, DateTime(2026, 11, 6));
      expect(p.end, DateTime(2026, 11, 12));
      expect(p.id, '2026-11-06_2026-11-12');
    });

    test('Thursday remains in the prior period and Friday advances', () {
      expect(
        WeeklyPeriod.containing(DateTime(2026, 11, 12)).start,
        DateTime(2026, 11, 6),
      );
      expect(
        WeeklyPeriod.containing(DateTime(2026, 11, 13)).start,
        DateTime(2026, 11, 13),
      );
    });

    test('handles month and year boundaries', () {
      final december = WeeklyPeriod.containing(DateTime(2026, 12, 31));
      expect(december.start, DateTime(2026, 12, 25));
      expect(december.end, DateTime(2026, 12, 31));
      final january = december.shift(1);
      expect(january.start, DateTime(2027, 1, 1));
      expect(january.end, DateTime(2027, 1, 7));
    });

    test('offset supports previous and future reporting weeks', () {
      final base = DateTime(2026, 11, 7);
      expect(WeeklyPeriod.offset(base, -1).start, DateTime(2026, 10, 30));
      expect(WeeklyPeriod.offset(base, 2).start, DateTime(2026, 11, 20));
    });

    test('same calendar day has the same period regardless of time', () {
      expect(
        WeeklyPeriod.containing(DateTime(2026, 11, 6, 0)).id,
        WeeklyPeriod.containing(DateTime(2026, 11, 6, 23, 59)).id,
      );
    });
  });
}
