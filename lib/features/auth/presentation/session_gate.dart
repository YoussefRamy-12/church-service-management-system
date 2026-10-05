import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import '../domain/entities/session_identity.dart';

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionIdentityProvider);

    return session.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذر تحميل صلاحيات الحساب.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (identity) {
        if (identity == null) {
          return const _SessionError(
            message: 'الحساب غير مرتبط بدور نشط في الخدمة.',
          );
        }

        return switch (identity) {
          SuperAdminIdentity() => const _SessionHome(
              title: 'لوحة مسؤول النظام',
              subtitle: 'Super Admin',
            ),
          ServantIdentity(:final profile) => _SessionHome(
              title: 'مرحبًا ${profile.name}',
              subtitle: _roleLabel(profile.role),
            ),
        };
      },
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'overall_leader':
        return 'القائد العام';
      case 'overall_helper':
        return 'المساعد العام';
      case 'stage_leader':
        return 'قائد المرحلة';
      case 'class_leader':
        return 'قائد الفصل';
      case 'class_servant':
        return 'خادم الفصل';
      default:
        return role;
    }
  }
}

class _SessionHome extends StatelessWidget {
  const _SessionHome({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}

class _SessionError extends StatelessWidget {
  const _SessionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}
