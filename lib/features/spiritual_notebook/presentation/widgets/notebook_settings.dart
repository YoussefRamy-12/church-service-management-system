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
                          ? AppDesignColors.darkSurfaceSubtle
                          : AppDesignColors.lightSurface,
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
                            ? AppDesignColors.darkSurfaceSubtle
                            : AppDesignColors.lightSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppDesignColors.darkBorder
                              : AppDesignColors.lightBorderSubtle,
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
                                      fontSize: 12,
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
                        style: const TextStyle(fontSize: 12),
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
                        ? AppDesignColors.darkSurfaceSubtle
                        : AppDesignColors.lightSurfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppDesignColors.darkBorder
                          : AppDesignColors.lightBorderSubtle,
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
                            fontSize: 12,
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








}
