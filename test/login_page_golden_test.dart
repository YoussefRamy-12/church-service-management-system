import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:church_service_management_system/app/theme.dart';
import 'package:church_service_management_system/features/auth/presentation/login_page.dart';

void main() {
  final cases = <({String name, Size size, ThemeData theme, String file})>[
    (name: 'mobile light', size: const Size(390, 844), theme: buildAppTheme(), file: 'login_mobile_light.png'),
    (name: 'mobile dark', size: const Size(390, 844), theme: buildAppDarkTheme(), file: 'login_mobile_dark.png'),
    (name: 'desktop light', size: const Size(1280, 900), theme: buildAppTheme(), file: 'login_desktop_light.png'),
    (name: 'desktop dark', size: const Size(1280, 900), theme: buildAppDarkTheme(), file: 'login_desktop_dark.png'),
  ];

  for (final golden in cases) {
    testWidgets('login ${golden.name} golden', (tester) async {
      tester.view.physicalSize = golden.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            theme: golden.theme,
            home: const LoginPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byKey(const Key('login_page')),
        matchesGoldenFile('goldens/${golden.file}'),
      );
    });
  }
}