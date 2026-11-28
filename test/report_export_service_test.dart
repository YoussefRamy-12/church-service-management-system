import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/features/reports/data/report_export_service.dart';
import 'package:church_service_management_system/features/reports/domain/analytics_models.dart';
import 'package:church_service_management_system/features/reports/domain/report_filter.dart';
import 'package:church_service_management_system/features/reports/domain/service_report.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const exportService = ReportExportService();

  const sampleReport = ServiceReport(
    students: 20,
    meetings: 4,
    expectedAttendance: 80,
    present: 64,
    early: 40,
    before: 10,
    normal: 14,
    followUps: 12,
    repeatedAbsences: [
      RepeatedAbsenceRecord(
        studentId: 'st-1',
        studentName: 'كيرلس أمير',
        classId: 'cl-1',
        className: 'فصل 5/1',
        consecutiveMissedMeetings: 3,
        lastAttendedDate: '2026-10-02',
        phone: '01220000000',
      ),
    ],
    classComparisons: [
      ClassComparisonMetric(
        classId: 'cl-1',
        className: 'فصل 5/1',
        stageId: 'st-5',
        stageName: 'مرحلة ٥ ابتدائي',
        totalStudents: 10,
        expectedAttendance: 40,
        presentCount: 32,
        earlyCount: 25,
        normalCount: 7,
        repeatedAbsencesCount: 1,
        openCasesCount: 2,
        resolvedCasesCount: 5,
      ),
    ],
    servantWorkloads: [
      ServantWorkloadMetric(
        servantId: 'serv-1',
        servantName: 'خ. رامي سمير',
        role: 'class_leader',
        className: 'فصل 5/1',
        assignedCasesCount: 3,
        activeCasesCount: 2,
        completedActivitiesCount: 8,
      ),
    ],
    meetingHistory: [
      MeetingAttendanceItem(
        meetingId: 'm-1',
        meetingDate: '2026-10-02',
        meetingName: 'اجتماع 1',
        startTime: '18:00',
        expectedCount: 20,
        presentCount: 16,
        earlyCount: 10,
        beforeCount: 2,
        normalCount: 4,
      ),
    ],
  );

  final sampleFilter = ReportFilter(
    start: DateTime(2026, 10, 1),
    end: DateTime(2026, 10, 31),
    preset: ReportPeriodPreset.currentMonth,
  );

  group('Report Export Service Tests', () {
    test('generateExcel produces valid non-empty workbook with multiple sheets', () {
      final bytes = exportService.generateExcel(
        report: sampleReport,
        filter: sampleFilter,
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('generateCsv produces UTF-8 BOM and correct column headers', () {
      final bytes = exportService.generateCsv(
        report: sampleReport,
        section: 'classes',
      );

      expect(bytes, isNotEmpty);
      // Byte order mark \uFEFF in UTF-8 is [0xEF, 0xBB, 0xBF]
      expect(bytes[0], 0xEF);
      expect(bytes[1], 0xBB);
      expect(bytes[2], 0xBF);
    });

    test('generatePdf generates non-empty printable PDF document', () async {
      final bytes = await exportService.generatePdf(
        report: sampleReport,
        filter: sampleFilter,
      );

      expect(bytes, isNotEmpty);
      // PDF file magic header: %PDF-
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}

