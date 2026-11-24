part of '../spiritual_notebook_page.dart';

class _NotebookSettings extends ConsumerStatefulWidget {
  const _NotebookSettings({
    required this.serviceId,
    required this.activities,
    required this.settings,
    required this.isMobile,
    required this.onSaved,
  });

  final String serviceId;
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic>? settings;
  final bool isMobile;
  final VoidCallback onSaved;

  @override
  ConsumerState<_NotebookSettings> createState() => _NotebookSettingsState();
}

class _NotebookSettingsState extends ConsumerState<_NotebookSettings> {
  late final TextEditingController nameController;
  late final TextEditingController pointsController;
  late final TextEditingController maxBonusController;
  late final Set<String> roles;
  bool isAddingActivity = false;
  bool isSavingBonusSettings = false;

  static const availableRoles = [
    'overall_leader',
    'overall_helper',
    'stage_leader',
    'class_leader',
    'class_servant',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    pointsController = TextEditingController();
    maxBonusController = TextEditingController(
      text: '${widget.settings?['max_bonus_points'] ?? 0}',
    );
    roles = (widget.settings?['bonus_roles'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
  }

  @override
  void dispose() {
    nameController.dispose();
    pointsController.dispose();
    maxBonusController.dispose();
    super.dispose();
  }

  String _roleLabel(String r) => switch (r) {
    'overall_leader' => 'مسؤول الخدمة',
    'overall_helper' => 'مساعد مسؤول الخدمة',
    'stage_leader' => 'مسؤول المرحلة',
    'class_leader' => 'أمين الفصل',
    _ => 'خادم الفصل',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppContent(
      maxWidth: 820,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isMobile ? 12 : 24,
        vertical: 10,
      ),
      child: ListView(
        children: [
          // Section 1: Activities Management
          SolidCard(
            borderRadius: 14,
            padding: EdgeInsets.all(widget.isMobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernSectionHeader(
                  title: 'الأنشطة الروحية المفعلة',
                  subtitle: 'قائمة الأنشطة المتاحة للتسجيل أسبوعياً',
                  badge: GlassBadge(
                    label: '${widget.activities.length} نشاط',
                    color: appPrimary,
                    showDot: false,
                  ),
                ),
                const SizedBox(height: 12),

                if (widget.activities.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const AppDesignColors.darkSurfaceSubtle
                          : const AppDesignColors.darkInk,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'لم تتم إضافة أنشطة روحية بعد. أضف نشاطاً جديداً بالأسفل.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                else
                  for (final a in widget.activities) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const AppDesignColors.darkSurfaceSubtle
                            : const AppDesignColors.darkInk,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const AppDesignColors.darkBorder
                              : const AppDesignColors.lightBorderSubtle,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: appSuccess,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (a['description'] != null &&
                                    (a['description'] as String).isNotEmpty)
                                  Text(
                                    a['description'].toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: appPrimary.withValues(
                                alpha: isDark ? 0.20 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${a['points']} ن',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: appPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: appPrimary,
                            tooltip: 'تعديل',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => _showEditActivityDialog(a),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            color: appError,
                            tooltip: 'حذف',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => _showDeleteActivityDialog(a),
                          ),
                        ],
                      ),
                    ),
                  ],

                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),

                const Text(
                  'إضافة نشاط روحي جديد',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 8),

                if (widget.isMobile) ...[
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم النشاط (مثلاً: قراءة الإنجيل)',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'النقاط',
                            prefixIcon: Icon(Icons.stars_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: appPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onPressed: isAddingActivity ? null : _addActivity,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(isAddingActivity ? 'جاري...' : 'إضافة'),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'اسم النشاط (مثلاً: صلاة باكر)',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: pointsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'النقاط',
                            prefixIcon: Icon(Icons.stars_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: appPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        onPressed: isAddingActivity ? null : _addActivity,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(isAddingActivity ? 'جاري...' : 'إضافة'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Bonus Rules & Permissions
          SolidCard(
            borderRadius: 14,
            padding: EdgeInsets.all(widget.isMobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ModernSectionHeader(
                  title: 'قواعد النقاط الإضافية والمكافآت',
                  subtitle:
                      'حدد سقف النقاط الإضافية والأدوار المصرح لها بمنحها',
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    SizedBox(
                      width: widget.isMobile ? 150 : 200,
                      child: TextField(
                        controller: maxBonusController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الحد الأقصى',
                          prefixIcon: Icon(Icons.star_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: appPrimary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isSavingBonusSettings
                          ? null
                          : _saveBonusSettings,
                      child: Text(
                        isSavingBonusSettings ? 'حفظ...' : 'حفظ السقف',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'الأدوار المسموح لها بمنح نقاط إضافية:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: availableRoles.map((r) {
                    final isChecked = roles.contains(r);
                    return FilterChip(
                      selected: isChecked,
                      selectedColor: appPrimary.withValues(
                        alpha: isDark ? 0.25 : 0.12,
                      ),
                      label: Text(
                        _roleLabel(r),
                        style: const TextStyle(fontSize: 11),
                      ),
                      onSelected: (v) async {
                        setState(() {
                          if (v) {
                            roles.add(r);
                          } else {
                            roles.remove(r);
                          }
                        });
                        await _saveBonusSettings();
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const AppDesignColors.darkSurfaceSubtle
                        : const AppDesignColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const AppDesignColors.darkBorder
                          : const AppDesignColors.lightBorderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: appPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تعديل القواعد ينطبق على التسجيلات القادمة مع الحفاظ الكامل على درجات الأسابيع السابقة.',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addActivity() async {
    final p = int.tryParse(pointsController.text);
    if (nameController.text.trim().isEmpty || p == null || p < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال اسم النشاط وعدد نقاط صالح (0 أو أكثر)'),
        ),
      );
      return;
    }

    setState(() => isAddingActivity = true);
    try {
      await ref
          .read(spiritualNotebookRepositoryProvider)
          .addActivity(widget.serviceId, nameController.text.trim(), p);
      nameController.clear();
      pointsController.clear();
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة النشاط الروحي بنجاح'),
            backgroundColor: appSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر إضافة النشاط: $e'),
            backgroundColor: appError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isAddingActivity = false);
    }
  }

  Future<void> _saveBonusSettings() async {
    final value = int.tryParse(maxBonusController.text);
    if (value == null || value < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل حداً صحيحاً للنقاط الإضافية')),
      );
      return;
    }

    setState(() => isSavingBonusSettings = true);
    try {
      await ref
          .read(spiritualNotebookRepositoryProvider)
          .upsertSettings(
            widget.serviceId,
            maxBonus: value,
            bonusRoles: roles.toList(),
          );
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ إعدادات النقاط الإضافية بنجاح'),
            backgroundColor: appSuccess,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر حفظ الإعدادات: $e'),
            backgroundColor: appError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSavingBonusSettings = false);
    }
  }

  Future<void> _showEditActivityDialog(Map<String, dynamic> activity) async {
    final editName = TextEditingController(
      text: activity['name'] as String? ?? '',
    );
    final editPoints = TextEditingController(
      text: '${activity['points'] ?? 0}',
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: appPrimary),
              SizedBox(width: 8),
              Text(
                'تعديل النشاط الروحي',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: editName,
                    decoration: const InputDecoration(
                      labelText: 'اسم النشاط الروحي',
                      prefixIcon: Icon(Icons.bookmark_outline_rounded),
                    ),
                    autofocus: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'يرجى إدخال اسم النشاط';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: editPoints,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'النقاط',
                      prefixIcon: Icon(Icons.stars_rounded),
                    ),
                    validator: (v) {
                      final p = int.tryParse(v ?? '');
                      if (p == null || p < 0) {
                        return 'يرجى إدخال عدد نقاط صحيح (0 أو أكثر)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const AppDesignColors.darkSurfaceSubtle
                          : const AppDesignColors.lightSurfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? const AppDesignColors.darkBorder
                            : const AppDesignColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: appPrimary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ملاحظة: تعديل النقاط ينطبق على الأسابيع والتسجيلات القادمة، مع بقاء درجات الأسابيع السابقة المسجلة كما هي.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final p = int.parse(editPoints.text.trim());
      try {
        await ref
            .read(spiritualNotebookRepositoryProvider)
            .updateActivity(
              activityId: activity['id'] as String,
              name: editName.text.trim(),
              points: p,
            );
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث النشاط الروحي بنجاح'),
              backgroundColor: appSuccess,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر تعديل النشاط: $e'),
              backgroundColor: appError,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteActivityDialog(Map<String, dynamic> activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_sweep_rounded, color: appError),
              SizedBox(width: 8),
              Text(
                'حذف النشاط الروحي',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'هل أنت متأكد من حذف النشاط «${activity['name']}»؟',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: appSuccess.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: appSuccess.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: appSuccess,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'حفظ الدرجات السابقة:\nسيتم حذف النشاط من قائمة الأنشطة المتاحة للتسجيل في الأسابيع القادمة، مع الاحتفاظ الكامل بجميع درجات وسجلات الأسابيع السابقة.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF86EFAC)
                                : const Color(0xFF0F5132),
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: appError,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('تأكيد الحذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(spiritualNotebookRepositoryProvider)
            .deleteActivity(activity['id'] as String);
        widget.onSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تم حذف النشاط بنجاح مع الحفاظ على درجات الأسابيع السابقة',
              ),
              backgroundColor: appSuccess,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تعذر حذف النشاط: $e'),
              backgroundColor: appError,
            ),
          );
        }
      }
    }
  }
}
