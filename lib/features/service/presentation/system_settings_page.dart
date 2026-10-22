import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/ui/app_ui.dart';
import '../../auth/domain/entities/session_identity.dart';
import '../../auth/presentation/auth_providers.dart';

class SystemSettingsPage extends ConsumerWidget {
  const SystemSettingsPage({super.key, required this.serviceId});
  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(currentSessionIdentityProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات النظام')),
      body: AppContent(
        maxWidth: 850,
        child: identity.when(
          loading: () =>
              const LoadingView(message: 'جاري تحميل بيانات الحساب...'),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'تعذر تحميل بيانات الحساب',
            message: '$error',
          ),
          data: (value) {
            if (value == null) {
              return const EmptyState(
                icon: Icons.lock_outline,
                title: 'لا توجد صلاحية لحساب نشط',
              );
            }
            final isAdmin = value is SuperAdminIdentity;
            final accountId = switch (value) {
              SuperAdminIdentity(:final profile) => profile.id,
              ServantIdentity(:final profile) => profile.id,
              MultiServiceServantIdentity(:final profiles) => profiles.first.id,
              PendingServantIdentity() => '—',
            };
            final role = switch (value) {
              SuperAdminIdentity() => 'مسؤول النظام',
              ServantIdentity(:final profile) => _roleLabel(profile.role),
              MultiServiceServantIdentity() => 'خادم في عدة خدمات',
              PendingServantIdentity() => 'بانتظار الربط بالخدمة',
            };
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                Text(
                  'النظام يعمل بنمط يحفظ التغييرات محليًا ثم يزامنها عند توفر الاتصال.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('الدور'),
                        subtitle: Text(role),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.fingerprint),
                        title: const Text('معرّف الحساب'),
                        subtitle: SelectableText(accountId),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.church_outlined),
                        title: const Text('معرّف الخدمة الحالية'),
                        subtitle: SelectableText(serviceId),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.sync_rounded),
                        title: const Text('مركز المزامنة'),
                        subtitle: const Text(
                          'الاتصال، التغييرات المعلقة والتعارضات',
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.go('/sync'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.warning_amber_rounded),
                        title: const Text('تعارضات البيانات'),
                        subtitle: const Text(
                          'مراجعة التغييرات التي تحتاج قرارًا',
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.go('/sync/conflicts'),
                      ),
                    ],
                  ),
                ),
                if (isAdmin)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: StatusBanner(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'صلاحيات مسؤول النظام',
                      message:
                          'يمكنك فتح جميع الوحدات الإدارية واختيار أي خدمة من لوحة مسؤول النظام.',
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _roleLabel(String role) => formatRoleLabel(role);
}
