import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/network/supabase_client_provider.dart';
import 'auth_providers.dart';
import '../domain/entities/session_identity.dart';

class SystemAdminHomePage extends ConsumerStatefulWidget {
  const SystemAdminHomePage({super.key});
  @override
  ConsumerState<SystemAdminHomePage> createState() => _SystemAdminHomePageState();
}

class _SystemAdminHomePageState extends ConsumerState<SystemAdminHomePage> {
  late Future<List<Map<String, dynamic>>> _services;

  @override
  void initState() {
    super.initState();
    _services = _loadServices();
  }

  Future<List<Map<String, dynamic>>> _loadServices() async => await ref.read(supabaseClientProvider)
      .from('services')
      .select('id, name, church_name, meeting_start_time')
      .order('name');

  void _reloadServices() {
    final services = _loadServices();
    setState(() {
      _services = services;
    });
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(currentSessionIdentityProvider);
    if (mounted) context.go('/login');
  }

  Future<void> _createService() async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _CreateServiceDialog(),
    );
    if (result == null || !mounted) return;
    try {
      final id = const Uuid().v4();
      await ref.read(supabaseClientProvider).from('services').insert({
        'id': id, 'name': result.$1, 'church_name': result.$2, 'meeting_start_time': '15:00:00',
      });
      if (!mounted) return;
      _reloadServices();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الخدمة. أضف الآن المرحلة والفصول من الإعدادات.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء الخدمة: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(currentSessionIdentityProvider);
    if (identity.isLoading) return const Scaffold(body: LoadingView(message: 'جاري التحقق من صلاحية مسؤول النظام...'));
    if (identity.hasError) return Scaffold(body: EmptyState(icon: Icons.error_outline, title: 'تعذر التحقق من الحساب', message: '${identity.error}', action: FilledButton(onPressed: () => context.go('/login'), child: const Text('العودة لتسجيل الدخول'))));
    if (identity.value is! SuperAdminIdentity) return Scaffold(body: EmptyState(icon: Icons.lock_outline_rounded, title: 'هذه الصفحة لمسؤول النظام فقط', message: 'سجّل الدخول بحساب مسؤول النظام للوصول إلى الخدمات.', action: FilledButton(onPressed: () => context.go('/login'), child: const Text('تسجيل الدخول'))));
    return Scaffold(
    appBar: AppBar(
      title: const Text('لوحة مسؤول النظام'),
      actions: [
        IconButton(key: const Key('admin_add_service'), tooltip: 'إضافة خدمة', onPressed: _createService, icon: const Icon(Icons.add_business_rounded)),
        IconButton(key: const Key('admin_logout'), tooltip: 'تسجيل الخروج', onPressed: _signOut, icon: const Icon(Icons.logout_rounded)),
      ],
    ),
    body: AppContent(maxWidth: 1100, child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _services,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingView(message: 'جاري تحميل الخدمات...');
        if (snapshot.hasError) return EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'تعذر تحميل الخدمات',
          message: 'تحقق من إعداد الاتصال أو صلاحية مسؤول النظام للوصول إلى الخدمات.',
          action: OutlinedButton.icon(onPressed: _reloadServices, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
        );
        final services = snapshot.data ?? const [];
        return ListView(padding: const EdgeInsets.symmetric(vertical: 20), children: [
          Text('إدارة النظام', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('اختر خدمة لفتح لوحة العمل وتجربة إدارة الفصول والتلاميذ والحضور والتقارير.'),
          const SizedBox(height: 24),
          Row(children: [
            _AdminSummary(icon: Icons.church_outlined, label: 'الخدمات المتاحة', value: '${services.length}'),
            const SizedBox(width: 12),
            const _AdminSummary(icon: Icons.admin_panel_settings_outlined, label: 'نوع الحساب', value: 'مسؤول النظام'),
          ]),
          const SizedBox(height: 24),
          Text('الخدمات', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (services.isEmpty) const EmptyState(icon: Icons.church_outlined, title: 'لا توجد خدمات متاحة', message: 'أضف خدمة إلى النظام أولًا لتتمكن من استكشاف بقية الشاشات.'),
          for (final service in services) Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
            key: Key('admin_service_${service['id']}'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            leading: const CircleAvatar(child: Icon(Icons.church_rounded)),
            title: Text(service['name']?.toString() ?? 'خدمة بدون اسم', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${service['church_name'] ?? 'كنيسة غير محددة'}  •  الاجتماع ${service['meeting_start_time'] ?? 'غير محدد'}'),
            trailing: const Icon(Icons.arrow_forward_rounded),
            onTap: () => context.go('/service/${service['id']}/dashboard'),
          )),
        ]);
      },
    )),
  );
  }
}

class _CreateServiceDialog extends StatefulWidget {
  const _CreateServiceDialog();
  @override
  State<_CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<_CreateServiceDialog> {
  final _name = TextEditingController();
  final _church = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _church.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('إضافة خدمة'),
    content: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'اسم الخدمة *'), validator: (value) => value == null || value.trim().isEmpty ? 'أدخل اسم الخدمة' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _church, decoration: const InputDecoration(labelText: 'اسم الكنيسة *'), validator: (value) => value == null || value.trim().isEmpty ? 'أدخل اسم الكنيسة' : null),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
      FilledButton(onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context, (_name.text.trim(), _church.text.trim())); }, child: const Text('إنشاء')),
    ],
  );
}

class _AdminSummary extends StatelessWidget {
  const _AdminSummary({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    Icon(icon, color: Theme.of(context).colorScheme.primary),
    const SizedBox(width: 12),
    Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)])),
  ]))));
}
