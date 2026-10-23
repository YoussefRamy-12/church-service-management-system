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
  ConsumerState<SystemAdminHomePage> createState() =>
      _SystemAdminHomePageState();
}

class _SystemAdminHomePageState extends ConsumerState<SystemAdminHomePage> {
  late Future<List<Map<String, dynamic>>> _services;
  late Future<int> _pendingServantCount;

  @override
  void initState() {
    super.initState();
    _services = _loadServices();
    _pendingServantCount = _loadPendingServantCount();
  }

  Future<List<Map<String, dynamic>>> _loadServices() async => await ref
      .read(supabaseClientProvider)
      .from('services')
      .select('id, name, church_name, meeting_start_time')
      .order('name');

  Future<int> _loadPendingServantCount() async {
    final rows = await ref
        .read(supabaseClientProvider)
        .from('servant_registration_requests')
        .select('auth_user_id')
        .eq('status', 'pending');
    return rows.length;
  }

  void _reloadServices() {
    final services = _loadServices();
    final pendingServants = _loadPendingServantCount();
    setState(() {
      _services = services;
      _pendingServantCount = pendingServants;
    });
  }

  Future<void> _signOut() async {
    await signOutAndGoToLogin(ref, context);
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
        'id': id,
        'name': result.$1,
        'church_name': result.$2,
        'meeting_start_time': '15:00:00',
      });
      if (!mounted) return;
      _reloadServices();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إنشاء الخدمة. أضف الآن المرحلة والفصول من الإعدادات.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر إنشاء الخدمة: $error')));
      }
    }
  }

  Future<void> _editService(Map<String, dynamic> service) async {
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _CreateServiceDialog(
        initialName: service['name']?.toString() ?? '',
        initialChurch: service['church_name']?.toString() ?? '',
        editing: true,
      ),
    );
    if (result == null || !mounted) return;
    try {
      await ref
          .read(supabaseClientProvider)
          .from('services')
          .update({'name': result.$1, 'church_name': result.$2})
          .eq('id', service['id']);
      if (!mounted) return;
      _reloadServices();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم تعديل الخدمة.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تعديل الخدمة: $error')));
      }
    }
  }

  Future<void> _deleteService(Map<String, dynamic> service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الخدمة؟'),
        content: Text(
          'سيتم حذف "${service['name']}". لا يمكن التراجع عن ذلك، وقد تمنع السجلات المرتبطة الحذف.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(supabaseClientProvider)
          .from('services')
          .delete()
          .eq('id', service['id']);
      if (!mounted) return;
      _reloadServices();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف الخدمة.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر حذف الخدمة. قد تحتوي على مراحل أو سجلات مرتبطة. $error',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = ref.watch(currentSessionIdentityProvider);
    if (identity.isLoading) {
      return const Scaffold(
        body: LoadingView(message: 'جاري التحقق من صلاحية مسؤول النظام...'),
      );
    }
    if (identity.hasError) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'تعذر التحقق من الحساب',
          message: '${identity.error}',
          action: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('العودة لتسجيل الدخول'),
          ),
        ),
      );
    }
    if (identity.value is! SuperAdminIdentity) {
      return Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'هذه الصفحة لمسؤول النظام فقط',
          message: 'سجّل الدخول بحساب مسؤول النظام للوصول إلى الخدمات.',
          action: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('تسجيل الدخول'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة مسؤول النظام'),
        actions: [
          IconButton(
            key: const Key('admin_servant_registrations'),
            tooltip: 'طلبات تسجيل الخدام',
            onPressed: () => context.go('/admin/servant-registrations'),
            icon: const Icon(Icons.person_search_rounded),
          ),
          IconButton(
            key: const Key('admin_add_service'),
            tooltip: 'إضافة خدمة',
            onPressed: _createService,
            icon: const Icon(Icons.add_business_rounded),
          ),
          IconButton(
            key: const Key('admin_logout'),
            tooltip: 'تسجيل الخروج',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AmbientBackground(
        intensity: 0.5,
        child: AppContent(
          maxWidth: 1100,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _services,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView(message: 'جاري تحميل الخدمات...');
              }
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'تعذر تحميل الخدمات',
                  message:
                      'تحقق من إعداد الاتصال أو صلاحية مسؤول النظام للوصول إلى الخدمات.',
                  action: OutlinedButton.icon(
                    onPressed: _reloadServices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                );
              }
              final services = snapshot.data ?? const [];
              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                children: [
                  Text(
                    'لوحة مسؤول النظام',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'إدارة جميع الخدمات والخدام في المنظومة بكل سهولة.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _AdminSummary(
                        icon: Icons.church_rounded,
                        label: 'الخدمات المتاحة',
                        value: '${services.length}',
                        color: const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 14),
                      const _AdminSummary(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'نوع الحساب',
                        value: 'مسؤول النظام',
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Servant Registrations Hero Card
                  FutureBuilder<int>(
                    future: _pendingServantCount,
                    builder: (context, countSnapshot) {
                      final count = countSnapshot.data;
                      final hasPending = count != null && count > 0;
                      return GlassCard(
                        key: const Key('admin_servant_registration_panel'),
                        borderRadius: 22,
                        padding: const EdgeInsets.all(20),
                        onTap: () => context.go('/admin/servant-registrations'),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: hasPending
                                      ? [
                                          const Color(0xFFF59E0B),
                                          const Color(0xFFF97316),
                                        ]
                                      : [
                                          const Color(0xFF4F46E5),
                                          const Color(0xFF7C3AED),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (hasPending
                                                ? const Color(0xFFF59E0B)
                                                : const Color(0xFF4F46E5))
                                            .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_search_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'طلبات تسجيل الخدام',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (hasPending) ...[
                                        const SizedBox(width: 8),
                                        GlassBadge(
                                          label: '$count بانتظار المراجعة',
                                          color: const Color(0xFFF59E0B),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    countSnapshot.hasError
                                        ? 'تعذر تحميل عدد الطلبات. افتح القائمة لمراجعتها.'
                                        : count == null
                                        ? 'جاري تحميل طلبات التسجيل...'
                                        : count == 0
                                        ? 'لا توجد طلبات معلقة حاليًا.'
                                        : 'توجد طلبات جديدة تحتاج إلى موافقة وربط بالخدمات.',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  context.go('/admin/servant-registrations'),
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              label: const Text('مراجعة الطلبات'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'قائمة الخدمات المسجلة',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GlassBadge(
                        label: '${services.length} خدمة',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('admin_add_service_btn'),
                        onPressed: _createService,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('خدمة جديدة'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (services.isEmpty)
                    const EmptyState(
                      icon: Icons.church_outlined,
                      title: 'لا توجد خدمات متاحة',
                      message:
                          'أضف خدمة إلى النظام أولًا لتتمكن من استكشاف بقية الشاشات.',
                    ),
                  for (final service in services)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        key: Key('admin_service_${service['id']}'),
                        borderRadius: 20,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        onTap: () =>
                            context.go('/service/${service['id']}/dashboard'),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4F46E5),
                                    Color(0xFF7C3AED),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.church_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['name']?.toString() ??
                                        'خدمة بدون اسم',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        service['church_name'] ??
                                            'كنيسة غير محددة',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (service['meeting_start_time'] !=
                                          null) ...[
                                        const SizedBox(width: 10),
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 14,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${service['meeting_start_time']}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: Key('admin_service_edit_${service['id']}'),
                              tooltip: 'تعديل الخدمة',
                              onPressed: () => _editService(service),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              key: Key('admin_service_delete_${service['id']}'),
                              tooltip: 'حذف الخدمة',
                              onPressed: () => _deleteService(service),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_left_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CreateServiceDialog extends StatefulWidget {
  const _CreateServiceDialog({
    this.initialName = '',
    this.initialChurch = '',
    this.editing = false,
  });
  final String initialName;
  final String initialChurch;
  final bool editing;
  @override
  State<_CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<_CreateServiceDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _church = TextEditingController(text: widget.initialChurch);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _church.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.editing ? 'تعديل الخدمة' : 'إضافة خدمة'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'اسم الخدمة *'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'أدخل اسم الخدمة'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _church,
            decoration: const InputDecoration(labelText: 'اسم الكنيسة *'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'أدخل اسم الكنيسة'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إلغاء'),
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.pop(context, (_name.text.trim(), _church.text.trim()));
          }
        },
        child: Text(widget.editing ? 'حفظ' : 'إنشاء'),
      ),
    ],
  );
}

class _AdminSummary extends StatelessWidget {
  const _AdminSummary({
    required this.icon,
    required this.label,
    required this.value,
    this.color = const Color(0xFF4F46E5),
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.22),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
