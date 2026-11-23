import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:church_service_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';
import 'package:church_service_management_system/features/auth/domain/entities/session_identity.dart';
import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/settings/data/preferences_settings_repository.dart';
import 'package:church_service_management_system/features/settings/domain/entities/app_settings.dart';
import 'package:church_service_management_system/features/settings/presentation/global_settings_page.dart';
import 'package:church_service_management_system/features/settings/presentation/settings_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesSettingsRepository', () {
    test('loads default settings when shared_preferences is empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefsFuture = SharedPreferences.getInstance();
      final repo = PreferencesSettingsRepository(prefsFuture);

      final settings = await repo.loadSettings();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.fontSize, AppFontSize.normal);
      expect(settings.languageCode, 'ar');
    });

    test('saves and reloads theme mode', () async {
      SharedPreferences.setMockInitialValues({});
      final prefsFuture = SharedPreferences.getInstance();
      final repo = PreferencesSettingsRepository(prefsFuture);

      await repo.saveThemeMode(AppThemeMode.dark);
      final settings = await repo.loadSettings();

      expect(settings.themeMode, AppThemeMode.dark);
    });

    test('saves and reloads font size', () async {
      SharedPreferences.setMockInitialValues({});
      final prefsFuture = SharedPreferences.getInstance();
      final repo = PreferencesSettingsRepository(prefsFuture);

      await repo.saveFontSize(AppFontSize.large);
      final settings = await repo.loadSettings();

      expect(settings.fontSize, AppFontSize.large);
    });
  });

  group('GlobalSettingsPage Widget Tests', () {
    const testProfile = ServantProfile(
      id: 'servant-123',
      authUserId: 'user-123',
      serviceId: 'service-456',
      name: 'مينا كمال',
      role: 'class_servant',
      accountStatus: 'active',
      phone: '01234567890',
    );

    testWidgets('renders all major sections for class_servant role', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              SharedPreferences.getInstance(),
            ),
            currentSessionIdentityProvider.overrideWith(
              (ref) async => const ServantIdentity(testProfile),
            ),
            currentServantProfileProvider.overrideWith(
              (ref) async => testProfile,
            ),
            currentAuthUserProvider.overrideWithValue(
              const AuthUser(id: 'user-123', email: 'mina@example.com'),
            ),
          ],
          child: const MaterialApp(
            home: GlobalSettingsPage(serviceId: 'service-456'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check section titles
      expect(find.text('المظهر'), findsOneWidget);
      expect(find.text('الملف الشخصي'), findsOneWidget);
      expect(find.text('الأمان'), findsOneWidget);
      expect(find.text('عن التطبيق'), findsOneWidget);

      // Check user profile data is displayed
      expect(find.text('مينا كمال'), findsOneWidget);
      expect(find.text('mina@example.com'), findsOneWidget);
      expect(find.text('خادم'), findsOneWidget); // role label for class_servant
      expect(find.text('نشط'), findsOneWidget);

      // Check appearance controls exist
      expect(find.text('فاتح'), findsOneWidget);
      expect(find.text('داكن'), findsOneWidget);
      expect(find.text('تلقائي (حسب النظام)'), findsOneWidget);
    });

    testWidgets('switching theme mode updates state', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              SharedPreferences.getInstance(),
            ),
            currentSessionIdentityProvider.overrideWith(
              (ref) async => const ServantIdentity(testProfile),
            ),
            currentServantProfileProvider.overrideWith(
              (ref) async => testProfile,
            ),
            currentAuthUserProvider.overrideWithValue(
              const AuthUser(id: 'user-123', email: 'mina@example.com'),
            ),
          ],
          child: const MaterialApp(
            home: GlobalSettingsPage(serviceId: 'service-456'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'داكن' (Dark theme chip)
      await tester.tap(find.text('داكن'));
      await tester.pumpAndSettle();

      // Verify SharedPreferences received the update
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_settings_theme_mode'), 'dark');
    });

    testWidgets('switching font size updates state', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              SharedPreferences.getInstance(),
            ),
            currentSessionIdentityProvider.overrideWith(
              (ref) async => const ServantIdentity(testProfile),
            ),
            currentServantProfileProvider.overrideWith(
              (ref) async => testProfile,
            ),
            currentAuthUserProvider.overrideWithValue(
              const AuthUser(id: 'user-123', email: 'mina@example.com'),
            ),
          ],
          child: const MaterialApp(
            home: GlobalSettingsPage(serviceId: 'service-456'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'كبير (115%)'
      await tester.tap(find.text('كبير (115%)'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_settings_font_size'), 'large');
    });

    testWidgets('accessible by every role without exceptions', (tester) async {
      final roles = [
        'overall_leader',
        'overall_helper',
        'stage_leader',
        'class_leader',
        'class_servant',
      ];

      for (final role in roles) {
        SharedPreferences.setMockInitialValues({});
        final profile = testProfile.copyWith(role: role);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(
                SharedPreferences.getInstance(),
              ),
              currentSessionIdentityProvider.overrideWith(
                (ref) async => ServantIdentity(profile),
              ),
              currentServantProfileProvider.overrideWith(
                (ref) async => profile,
              ),
              currentAuthUserProvider.overrideWithValue(
                const AuthUser(id: 'user-123', email: 'mina@example.com'),
              ),
            ],
            child: const MaterialApp(
              home: GlobalSettingsPage(serviceId: 'service-456'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(GlobalSettingsPage), findsOneWidget);
        expect(find.text('المظهر'), findsOneWidget);
        expect(find.text('الملف الشخصي'), findsOneWidget);
      }
    });
  });
}
