// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/sync/sync_conflict_page.dart';
import '../core/sync/sync_center_page.dart';
import '../features/attendance/presentation/attendance_session_page.dart';
import '../features/attendance/presentation/attendance_class_picker_page.dart';
import '../features/attendance/presentation/meeting_list_page.dart';
import '../features/attendance/presentation/meeting_schedules_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/session_gate.dart';
import '../features/export/presentation/export_page.dart';
import '../features/follow_up/presentation/follow_up_hub_page.dart';
import '../features/reports/presentation/reports_page.dart';
import '../features/weekly_prep/presentation/weekly_prep_page.dart';
import '../features/servants/presentation/servant_management_page.dart';
import '../features/service/presentation/service_dashboard_page.dart';
import '../features/service/presentation/stage_dashboard_page.dart';
import '../features/service/presentation/structure_settings_page.dart';
import '../features/service/presentation/system_settings_page.dart';
import '../features/auth/presentation/system_admin_home_page.dart';
import '../features/auth/presentation/servant_sign_up_page.dart';
import '../features/auth/presentation/servant_registration_requests_page.dart';
import '../features/auth/presentation/password_recovery_pages.dart';
import '../features/service/presentation/service_settings_page.dart';
import '../features/students/presentation/students_page.dart';
import 'app_shell.dart';
import 'theme.dart';

class ChurchServiceApp extends ConsumerStatefulWidget {
  const ChurchServiceApp({super.key});
  @override
  ConsumerState<ChurchServiceApp> createState() => _ChurchServiceAppState();
}

class _ChurchServiceAppState extends ConsumerState<ChurchServiceApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.listen(authUserProvider, (previous, next) => _router.refresh());
    return MaterialApp.router(
      title: 'أسرة تلاميذ المسيح',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: themeMode,
      routerConfig: _router,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  GoRouter _createRouter() => GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      const publicPaths = {
        '/login',
        '/signup',
        '/forgot-password',
        '/reset-password',
        '/auth/callback',
      };
      final isAuthenticated =
          ref.read(authRepositoryProvider).currentUser != null;
      final path = state.uri.path;
      if (!isAuthenticated && !publicPaths.contains(path)) return '/login';
      if (isAuthenticated && path == '/login') return '/session';
      return null;
    },
    routes: [
      GoRoute(path: '/app', redirect: (context, state) => '/session'),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const SystemAdminHomePage(),
      ),
      GoRoute(
        path: '/admin/servant-registrations',
        builder: (context, state) => const ServantRegistrationRequestsPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const ServantSignUpPage(),
      ),
      GoRoute(
        path: '/session',
        builder: (context, state) => const SessionGate(),
      ),
      GoRoute(
        path: '/sync/conflicts',
        builder: (context, state) => const SyncConflictPage(),
      ),
      GoRoute(
        path: '/sync',
        builder: (context, state) => const SyncCenterPage(),
      ),
      GoRoute(
        path: '/service/:serviceId',
        redirect: (context, state) {
          final servicePath = '/service/${state.pathParameters['serviceId']}';
          return state.uri.path == servicePath
              ? '$servicePath/dashboard'
              : null;
        },
        routes: [
          ShellRoute(
            builder: (context, state, child) => AppShell(
              serviceId: state.pathParameters['serviceId']!,
              child: child,
            ),
            routes: [
              GoRoute(
                path: 'dashboard',
                builder: (context, state) => ServiceDashboardPage(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
              GoRoute(
                path: 'stage/:stageId',
                builder: (context, state) => StageDashboardPage(
                  serviceId: state.pathParameters['serviceId']!,
                  stageId: state.pathParameters['stageId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'class/:classId',
                    builder: (context, state) => ClassDashboardPage(
                      serviceId: state.pathParameters['serviceId']!,
                      stageId: state.pathParameters['stageId']!,
                      classId: state.pathParameters['classId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'students',
                builder: (context, state) =>
                    StudentsPage(serviceId: state.pathParameters['serviceId']!),
              ),
              GoRoute(
                path: 'attendance',
                builder: (context, state) => MeetingListPage(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
              GoRoute(
                path: 'settings/meetings',
                builder: (context, state) => MeetingSchedulesPage(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
              GoRoute(
                path: 'attendance/class-picker/:meetingId',
                builder: (context, state) => AttendanceClassPickerPage(
                  serviceId: state.pathParameters['serviceId']!,
                  meetingId: state.pathParameters['meetingId']!,
                ),
              ),
              GoRoute(
                path: 'follow-up',
                builder: (context, state) => FollowUpHubPage(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
              GoRoute(
                path: 'reports',
                builder: (context, state) =>
                    ReportsPage(serviceId: state.pathParameters['serviceId']!),
              ),
              GoRoute(
                path: 'prep',
                builder: (context, state) => WeeklyPrepPage(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
              GoRoute(
                path: 'servants',
                builder: (context, state) => ServantManagementPage(
                  serviceId: state.pathParameters['serviceId']!,
                  openAddOnLoad: state.uri.queryParameters['add'] == 'true',
                ),
              ),
              GoRoute(
                path: 'export',
                builder: (context, state) => ExportPage(
                  serviceId: state.pathParameters['serviceId']!,
                  classId: state.uri.queryParameters['classId'],
                ),
              ),
              GoRoute(
                path: 'graduation',
                builder: (context, state) => ExportPage(
                  serviceId: state.pathParameters['serviceId']!,
                  graduationOnly: true,
                ),
              ),
              GoRoute(
                path: 'settings',
                builder: (context, state) => ServiceSettingsPage(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
              GoRoute(
                path: 'settings/structure',
                builder: (context, state) => StructureSettingsPage(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
              GoRoute(
                path: 'settings/system',
                builder: (context, state) => SystemSettingsPage(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
              GoRoute(
                path: 'attendance/session/:meetingId/:classId',
                builder: (context, state) => AttendanceSessionPage(
                  serviceId: state.pathParameters['serviceId']!,
                  meetingId: state.pathParameters['meetingId']!,
                  classId: state.pathParameters['classId']!,
                  recordedBy: state.uri.queryParameters['recordedBy']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/attendance/:meetingId/:classId',
        builder: (context, state) => AttendanceSessionPage(
          serviceId: state.uri.queryParameters['serviceId']!,
          meetingId: state.pathParameters['meetingId']!,
          classId: state.pathParameters['classId']!,
          recordedBy: state.uri.queryParameters['recordedBy']!,
        ),
      ),
    ],
  );
}
