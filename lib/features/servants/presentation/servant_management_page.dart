import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/design/app_colors.dart';

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
  String roleFilter = 'all';
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
              final matchesRole =
                  roleFilter == 'all' || servant.role == roleFilter;
              return matchesSearch && matchesStatus && matchesRole;
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
                  ResponsiveMetricGrid(
                    spacing: 10,
                    children: [
                      ModernMetricCard(
                        label: 'إجمالي الخدام',
                        value: '${all.length}',
                        icon: Icons.people_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      ModernMetricCard(
                        label: 'نشط',
                        value: '$activeCount',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.of(context).present.foreground,
                      ),
                      ModernMetricCard(
                        label: 'معلق',
                        value: '$pendingCount',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.of(context).pending.foreground,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: 'بحث بالاسم أو الهاتف',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: search.isNotEmpty
                                ? IconButton(
                                    tooltip: 'مسح البحث',
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () =>
                                        setState(() => search = ''),
                                  )
                                : null,
                          ),
                          onChanged: (value) => setState(() => search = value),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'الدور',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final option in const [
                              ('all', 'كل الأدوار'),
                              ('overall_leader', 'أمين الخدمة'),
                              ('overall_helper', 'أمين مساعد'),
                              ('stage_leader', 'أمين المرحلة'),
                              ('class_leader', 'أمين الفصل'),
                              ('class_servant', 'خادم الفصل'),
                            ])
                              ChoiceChip(
                                label: Text(option.$2),
                                selected: roleFilter == option.$1,
                                onSelected: (_) => setState(
                                  () => roleFilter = option.$1,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'حالة الحساب',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final option in const [
                              ('all', 'الكل'),
                              ('active', 'نشط'),
                              ('pending', 'معلق'),
                              ('inactive', 'غير نشط'),
                            ])
                              ChoiceChip(
                                label: Text(option.$2),
                                selected: statusFilter == option.$1,
                                onSelected: (_) => setState(
                                  () => statusFilter = option.$1,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'لا توجد خدام مطابقة',
                      message: 'جرّب تغيير البحث أو عوامل التصفية.',
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 768) {
                          return AppCard(
                            padding: const EdgeInsets.all(8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columnSpacing: 28,
                                headingRowHeight: 48,
                                dataRowMinHeight: 56,
                                dataRowMaxHeight: 64,
                                columns: const [
                                  DataColumn(label: Text('الخادم')),
                                  DataColumn(label: Text('الدور')),
                                  DataColumn(label: Text('النطاق')),
                                  DataColumn(label: Text('الحالة')),
                                  DataColumn(label: Text('إجراءات')),
                                ],
                                rows: [
                                  for (final servant in filtered)
                                    DataRow(
                                      onSelectChanged: (_) =>
                                          _openEditor(servant),
                                      cells: [
                                        DataCell(Text(servant.name)),
                                        DataCell(Text(_roleLabel(servant.role))),
                                        DataCell(Text(_assignmentLabel(servant))),
                                        DataCell(_statusBadge(context, servant)),
                                        DataCell(
                                          _servantActionsMenu(
                                            servant,
                                            isSuperAdmin,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final servant in filtered)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildMobileServantCard(
                                  context,
                                  servant,
                                  isSuperAdmin,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileServantCard(
    BuildContext context,
    ServantProfile servant,
    bool isSuperAdmin,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: () => _openEditor(servant),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(
              servant.name.isEmpty ? '؟' : servant.name.characters.first,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servant.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _roleBadge(context, servant),
                    _statusBadge(context, servant),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _assignmentLabel(servant),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (servant.phone != null && servant.phone!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          servant.phone!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      PhoneContactActions(
                        phone: servant.phone!,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          _servantActionsMenu(servant, isSuperAdmin),
        ],
      ),
    );
  }

  Widget _roleBadge(BuildContext context, ServantProfile servant) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(Icons.badge_outlined, size: 16, color: scheme.primary),
      label: Text(_roleLabel(servant.role)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _statusBadge(BuildContext context, ServantProfile servant) {
    final semantic = AppColors.of(context);
    final pair = switch (servant.accountStatus) {
      'active' => semantic.present,
      'pending' => semantic.pending,
      _ => semantic.absent,
    };
    final icon = switch (servant.accountStatus) {
      'active' => Icons.check_circle_outline_rounded,
      'pending' => Icons.hourglass_top_rounded,
      _ => Icons.block_outlined,
    };
    return Chip(
      avatar: Icon(icon, size: 16, color: pair.foreground),
      label: Text(
        _statusLabel(servant.accountStatus),
        style: TextStyle(color: pair.foreground),
      ),
      backgroundColor: pair.background,
      side: BorderSide(color: pair.foreground.withValues(alpha: 0.25)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _servantActionsMenu(
    ServantProfile servant,
    bool isSuperAdmin,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'إجراءات الخادم',
      onSelected: (action) {
        if (action == 'edit') _openEditor(servant);
        if (action == 'delete') _deleteServant(servant);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.edit_outlined),
            title: Text('تعديل البيانات'),
          ),
        ),
        if (isSuperAdmin)
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.delete_outline_rounded),
              title: Text('حذف ملف الخادم'),
            ),
          ),
      ],
    );
  }

  String _assignmentLabel(ServantProfile servant) {
    if (servant.classId != null) {
      for (final item in classes) {
        if (item.id == servant.classId) return item.name;
      }
    }
    if (servant.stageId != null) {
      for (final item in stages) {
        if (item.id == servant.stageId) return item.name;
      }
    }
    return 'نطاق الخدمة بالكامل';
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
