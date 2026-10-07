// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';
import '../domain/entities/session_identity.dart';
import '../domain/entities/servant_profile.dart';
import '../../../core/sync/sync_engine_provider.dart';

class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentSessionIdentityProvider);
    return session.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('تعذر تحميل صلاحيات الحساب.\n$error', textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (identity) {
        if (identity == null) {
          return const _SessionError(message: 'الحساب غير مرتبط بدور نشط في الخدمة.');
        }
        ref.read(syncEngineProvider).start();
        return switch (identity) {
          SuperAdminIdentity() => const _SessionHome(
              title: 'لوحة مسؤول النظام',
              subtitle: 'Super Admin',
            ),
          ServantIdentity(:final profile) => _ServiceEntry(profile: profile),
        };
      },
    );
  }
}

class _ServiceEntry extends StatefulWidget {
  const _ServiceEntry({required this.profile});
  final ServantProfile profile;

  @override State<_ServiceEntry> createState() => _ServiceEntryState();
}

class _ServiceEntryState extends State<_ServiceEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go('/service/' + widget.profile.serviceId + '/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _SessionHome extends StatelessWidget {
  const _SessionHome({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(subtitle, style: Theme.of(context).textTheme.headlineSmall)),
      );
}

class _SessionError extends StatelessWidget {
  const _SessionError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(message)));
}