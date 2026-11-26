@Tags(['golden'])
library;

import 'dart:convert';

import 'package:church_service_management_system/core/network/supabase_client_provider.dart';
import 'package:church_service_management_system/features/attendance/presentation/attendance_class_picker_page.dart';
import 'package:church_service_management_system/features/attendance/presentation/attendance_page.dart';
import 'package:church_service_management_system/features/attendance/presentation/attendance_providers.dart';
import 'package:church_service_management_system/features/attendance/presentation/meeting_list_page.dart';
import 'package:church_service_management_system/features/attendance/presentation/meeting_picker_page.dart';
import 'package:church_service_management_system/features/attendance/presentation/meeting_providers.dart';
import 'package:church_service_management_system/features/attendance/presentation/meeting_schedules_page.dart';
import 'package:church_service_management_system/features/auth/domain/entities/session_identity.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/service/presentation/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'golden_test_helper.dart';

void main() {
  setUpAll(ensureGoldenTestSetup);

  final attendanceOverrides = [
    serviceRepositoryProvider.overrideWithValue(GoldenFakeServiceRepository()),
    meetingRepositoryProvider.overrideWithValue(GoldenFakeMeetingRepository()),
    attendanceRepositoryProvider.overrideWithValue(
      GoldenFakeAttendanceRepository(),
    ),
    currentServantProfileProvider.overrideWith(
      (_) async => goldenLeaderProfile,
    ),
    currentSessionIdentityProvider.overrideWith(
      (_) async => ServantIdentity(goldenLeaderProfile),
    ),
    isSuperAdminProvider.overrideWithValue(false),
  ];

  final screens = <({String name, Widget widget})>[
    (
      name: 'attendance_meeting_list',
      widget: const MeetingListPage(serviceId: goldenServiceId),
    ),
    (
      name: 'attendance_class_picker',
      widget: const AttendanceClassPickerPage(
        serviceId: goldenServiceId,
        meetingId: goldenMeetingId,
      ),
    ),
    (
      name: 'attendance_meeting_picker',
      widget: const MeetingPickerPage(
        serviceId: goldenServiceId,
        classId: goldenClassId,
      ),
    ),
    (
      name: 'attendance_entry',
      widget: const AttendancePage(
        meetingId: goldenMeetingId,
        classId: goldenClassId,
        recordedBy: 'servant-1',
        students: [
          (
            id: 'student-1',
            name: 'مينا فايز',
            serviceId: goldenServiceId,
            serviceStudentId: 'ss-1',
          ),
          (
            id: 'student-2',
            name: 'كيرلس يوسف',
            serviceId: goldenServiceId,
            serviceStudentId: 'ss-2',
          ),
        ],
      ),
    ),
  ];

  for (final screen in screens) {
    for (final variant in standardGoldenVariants) {
      testWidgets('${screen.name} — ${variant.suffix}', (tester) async {
        await pumpGoldenWidget(
          tester,
          home: screen.widget,
          variant: variant,
          overrides: attendanceOverrides,
        );
        await expectGoldenImage(
          tester,
          '${screen.name}_${variant.suffix}.png',
        );
      });
    }
  }

  for (final variant in standardGoldenVariants) {
    testWidgets('attendance meeting schedules — ${variant.suffix}', (
      tester,
    ) async {
      final client = SupabaseClient(
        'http://localhost:54321',
        'golden-test-key',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode([
              {
                'id': 'schedule-1',
                'name': 'اجتماع مدارس الأحد',
                'frequency': 'weekly',
                'weekday': 5,
                'month_day': 1,
                'start_time': '18:00:00',
                'is_active': true,
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);

      await pumpGoldenWidget(
        tester,
        home: const MeetingSchedulesPage(serviceId: goldenServiceId),
        variant: variant,
        overrides: [
          ...attendanceOverrides,
          supabaseClientProvider.overrideWithValue(client),
        ],
      );
      await tester.pump(const Duration(milliseconds: 100));
      await expectGoldenImage(
        tester,
        'attendance_meeting_schedules_${variant.suffix}.png',
      );
    });
  }
}
