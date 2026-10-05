import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_config.dart';
import '../core/config/supabase_initializer.dart';
import '../features/auth/presentation/login_page.dart';

class ChurchServiceApp extends StatefulWidget {
  const ChurchServiceApp({super.key});

  @override
  State<ChurchServiceApp> createState() => _ChurchServiceAppState();
}

class _ChurchServiceAppState extends State<ChurchServiceApp> {
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
          localizationsDelegates: const [],
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
