import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import 'package:church_service_management_system/core/network/supabase_client_provider.dart';

import 'package:church_service_management_system/features/auth/presentation/auth_providers.dart';
import 'package:church_service_management_system/features/auth/presentation/session_gate.dart';
import 'package:church_service_management_system/features/auth/domain/entities/session_identity.dart';
import 'package:church_service_management_system/features/auth/domain/entities/servant_profile.dart';

void main() {
  testWidgets('session gate rejects an account without an active identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionIdentityProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: SessionGate()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('الحساب غير مرتبط بدور نشط في الخدمة.'), findsOneWidget);
  });
  testWidgets('service picker shows a clear empty state when no services are assigned', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionIdentityProvider.overrideWith(
            (ref) async => const MultiServiceServantIdentity([]),
          ),
        ],
        child: const MaterialApp(home: SessionGate()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('لا توجد خدمات مرتبطة'), findsOneWidget);
    expect(find.text('تواصل مع مسؤول النظام لربط حسابك بخدمة.'), findsOneWidget);
  });
  testWidgets('service picker shows an error state with retry action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentSessionIdentityProvider.overrideWith((ref) async {
            throw Exception('profile lookup failed');
          }),
        ],
        child: const MaterialApp(home: SessionGate()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('تعذر تحميل صلاحيات الحساب. تحقق من الاتصال ثم حاول مرة أخرى.'),
      findsOneWidget,
    );
    expect(find.text('إعادة المحاولة'), findsOneWidget);
  });
}
