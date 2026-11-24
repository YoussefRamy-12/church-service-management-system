import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../auth/domain/entities/servant_profile.dart';
import '../../service/domain/entities/service_class.dart';
import '../../service/domain/entities/stage.dart';
import '../../service/presentation/service_providers.dart';
import 'servant_providers.dart';
import 'servant_management_dialogs.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/ui/phone_contact_actions.dart';

class ServantManagementPage extends ConsumerStatefulWidget {
  const ServantManagementPage({
    super.key,
    required this.serviceId,
    this.openAddOnLoad = false,
  });

  final String serviceId;
  final bool openAddOnLoad;

  @override
  ConsumerState<ServantManagementPage> createState() =>
      _ServantManagementPageState();
}

class _ServantManagementPageState extends ConsumerState<ServantManagementPage> {
  String search = '';
  String statusFilter = 'all';
  List<Stage> stages = [];
  List<ServiceClass> classes = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadHierarchy();
      if (widget.openAddOnLoad && mounted) _addServant();
    });
  }

  Future<void> _loadHierarchy() async {
    final service = ref.read(serviceRepositoryProvider);
    try {
      await service.refreshStages(widget.serviceId);
      final localStages = await service.getStages(widget.serviceId);
      for (final stage in localStages) {
        await service.refreshClasses(stage.id);
      }
      final localClasses = <ServiceClass>[];
      for (final stage in localStages) {
        localClasses.addAll(await service.getClasses(stage.id));
      }
      if (!mounted) return;
      setState(() {
        stages = localStages;
        classes = localClasses;
      });
    } catch (_) {
      final localStages = await service.getStages(widget.serviceId);
      final localClasses = <ServiceClass>[];
      for (final stage in localStages) {
        localClasses.addAll(await service.getClasses(stage.id));
      }
      if (!mounted) return;
      setState(() {
        stages = localStages;
        classes = localClasses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(servantRepositoryProvider);
    final isSuperAdmin = ref.watch(isSuperAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الخدام'),
        actions: [
          if (isSuperAdmin)
            IconButton(
              key: const Key('servants_add'),
              tooltip: 'إضافة خادم',
              onPressed: _addServant,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: () async {
              await repository.refresh(widget.serviceId);
              await _loadHierarchy();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AmbientBackground(
        intensity: 0.5,
        child: StreamBuilder<List<ServantProfile>>(
          stream: repository.watchForService(widget.serviceId),
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <ServantProfile>[];
            final filtered = all.where((servant) {
              final matchesSearch =
                  search.trim().isEmpty ||
                  servant.name.contains(search.trim()) ||
                  (servant.phone ?? '').contains(search.trim());
              final matchesStatus =
                  statusFilter == 'all' ||
                  servant.accountStatus == statusFilter;
              return matchesSearch && matchesStatus;
            }).toList();

            final activeCount = all
                .where((s) => s.accountStatus == 'active')
                .length;
            final pendingCount = all
                .where((s) => s.accountStatus == 'pending')
                .length;

            return AppContent(
              maxWidth: 900,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  // Metrics Ribbon (Responsive Metric Grid)
                  ResponsiveMetricGrid(
                    spacing: 10,
                    children: [
                      ModernMetricCard(
                        label: 'إجمالي الخدام',
                        value: '${all.length}',
                        icon: Icons.people_outline_rounded,
                        color: const Color(0xFF00236F),
                      ),
                      ModernMetricCard(
                        label: 'نشط',
                        value: '$activeCount',
                        icon: Icons.check_circle_outline_rounded,
                        color: const Color(0xFF10B981),
                      ),
                      ModernMetricCard(
                        label: 'معلق',
                        value: '$pendingCount',
                        icon: Icons.hourglass_top_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search & Filter Card
                  GlassCard(
                    borderRadius: 12,
                    padding: const EdgeInsets.all(12),
                    hoverElevation: false,
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'بحث بالاسم أو الهاتف',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => search = ''),
                                  )
                                : null,
                          ),
                          onChanged: (value) => setState(() => search = value),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'all', label: Text('الكل')),
                            ButtonSegment(value: 'active', label: Text('نشط')),
                            ButtonSegment(
                              value: 'pending',
                              label: Text('معلق'),
                            ),
                            ButtonSegment(
                              value: 'inactive',
                              label: Text('غير نشط'),
                            ),
                          ],
                          selected: {statusFilter},
                          onSelectionChanged: (value) =>
                              setState(() => statusFilter = value.first),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (filtered.isEmpty)
                    GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 40,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد بيانات مطابقة للبحث أو التصفية.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  for (final servant in filtered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        onTap: () => _openEditor(servant),
                        child: Row(
                          children: [
                            // Initial Avatar (Solid surface, no gradient)
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: servant.accountStatus == 'active'
                                    ? const Color(0xFF00236F).withValues(alpha: 0.08)
                                    : servant.accountStatus == 'pending'
                                    ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                    : const Color(0xFF64748B).withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: servant.accountStatus == 'active'
                                      ? const Color(0xFF00236F).withValues(alpha: 0.20)
                                      : servant.accountStatus == 'pending'
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.25)
                                      : const Color(0xFF64748B).withValues(alpha: 0.20),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  servant.name.isEmpty
                                      ? '؟'
                                      : servant.name.characters.first,
                                  style: TextStyle(
                                    color: servant.accountStatus == 'active'
                                        ? const Color(0xFF00236F)
                                        : servant.accountStatus == 'pending'
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF475569),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Servant Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    servant.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      GlassBadge(
                                        label: _roleLabel(servant.role),
                                        color: const Color(0xFF00236F),
                                        showDot: false,
                                      ),
                                      const SizedBox(width: 6),
                                      GlassBadge(
                                        label: _statusLabel(
                                          servant.accountStatus,
                                        ),
                                        color: servant.accountStatus == 'active'
                                            ? const Color(0xFF10B981)
                                            : servant.accountStatus == 'pending'
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                  if (servant.phone != null &&
                                      servant.phone!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: SelectableText(
                                            servant.phone!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        PhoneContactActions(phone: servant.phone!, compact: true),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Actions
                            if (isSuperAdmin)
                              IconButton(
                                key: Key('servant_delete_${servant.id}'),
                                tooltip: 'حذف الخادم',
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444),
                                ),
                                onPressed: () => _deleteServant(servant),
                              )
                            else
                              Icon(
                                Icons.chevron_left_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditor(ServantProfile servant) async {
    final result = await showDialog<ServantEditResult>(
      context: context,
      builder: (_) => ServantEditDialog(
        servant: servant,
        stages: stages,
        classes: classes,
      ),
    );

    if (result == null) return;

    try {
      await ref
          .read(servantRepositoryProvider)
          .updateProfile(
            servantId: servant.id,
            name: result.name,
            phone: result.phone,
            birthDate: result.birthDate,
            workStudy: result.workStudy,
            role: result.role,
            stageId: result.stageId,
            classId: result.classId,
            accountStatus: result.accountStatus,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديل محليًا وسيتم مزامنته.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حفظ التعديل: $error')));
    }
  }

  Future<void> _addServant() async {
    final values = await showDialog<NewServantValues>(
      context: context,
      builder: (_) => NewServantDialog(stages: stages, classes: classes),
    );
    if (values == null || !mounted) return;
    try {
      await ref
          .read(servantRepositoryProvider)
          .createProfile(
            id: const Uuid().v4(),
            serviceId: widget.serviceId,
            authUserId: values.authUserId,
            name: values.name,
            phone: values.phone,
            role: values.role,
            stageId: values.stageId,
            classId: values.classId,
          );
      await ref.read(servantRepositoryProvider).refresh(widget.serviceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الخادم وربط دوره بالخدمة.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذرت إضافة الخادم: $error')));
    }
  }

  Future<void> _deleteServant(ServantProfile servant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف ملف الخادم؟'),
        content: Text(
          'سيُحذف ${servant.name} من هذه الخدمة. لن يتم حذف حساب تسجيل الدخول نفسه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف الملف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(servantRepositoryProvider).deleteProfile(servant.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف ملف الخادم محليًا وستتم مزامنته.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر حذف ملف الخادم: $error')));
      }
    }
  }

  String _roleLabel(String role) => formatRoleLabel(role);
  /*
        'overall_leader' => 'أمين الخدمة',
        'overall_helper' => 'أمين مساعد',
        'stage_leader' => 'أمين المرحلة',
        'class_leader' => 'أمين الفصل',
        'class_servant' => 'خادم الفصل',
        _ => role,
      };*/

  String _statusLabel(String status) => switch (status) {
    'pending' => 'معلق',
    'active' => 'نشط',
    'inactive' => 'غير نشط',
    _ => status,
  };
}
