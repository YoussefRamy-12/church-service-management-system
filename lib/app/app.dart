import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/supabase_initializer.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/session_gate.dart';
import '../features/service/presentation/service_dashboard_page.dart';
import '../features/servants/presentation/servant_management_page.dart';
import '../features/reports/presentation/reports_page.dart';
import '../features/export/presentation/export_page.dart';
import '../features/attendance/presentation/attendance_session_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';

class ChurchServiceApp extends ConsumerStatefulWidget {
  const ChurchServiceApp({super.key});

  @override
  ConsumerState<ChurchServiceApp> createState() => _ChurchServiceAppState();
}

class _ChurchServiceAppState extends ConsumerState<ChurchServiceApp> {
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = initializeSupabase();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _StartupScreen(),
          );
        }

        return MaterialApp.router(
          title: 'أسرة تلاميذ المسيح',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          routerConfig: _router,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }

  GoRouter get _router => GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: '/session',
            builder: (context, state) => const SessionGate(),
          ),
          GoRoute(
            path: '/service/:serviceId',
            builder: (context, state) => ServiceDashboardPage(
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
          GoRoute(
            path: '/export/:serviceId',
            builder: (context, state) => ExportPage(
              serviceId: state.pathParameters['serviceId']!,
              classId: state.uri.queryParameters['classId'],
            ),
          ),
          GoRoute(
            path: '/reports/:serviceId',
            builder: (context, state) => ReportsPage(
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
          GoRoute(
            path: '/servants/:serviceId',
            builder: (context, state) => ServantManagementPage(
              serviceId: state.pathParameters['serviceId']!,
            ),
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

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
