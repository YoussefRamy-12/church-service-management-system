part of '../spiritual_notebook_page.dart';

class SpiritualNotebookStudentPage extends ConsumerStatefulWidget {
  const SpiritualNotebookStudentPage({
    super.key,
    required this.serviceId,
    required this.membershipId,
  });
  final String serviceId, membershipId;

  @override
  ConsumerState<SpiritualNotebookStudentPage> createState() =>
      _SpiritualNotebookStudentPageState();
}

class _SpiritualNotebookStudentPageState
    extends ConsumerState<SpiritualNotebookStudentPage> {
  late Future<_StudentFormData> data;
  final selected = <String>{};
  final bonus = TextEditingController();
  final reason = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    data = _load();
  }



  @override
  void dispose() {
    bonus.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentServantProfileProvider).value?.role;
    final period = WeeklyPeriod.containing(DateTime.now());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<_StudentFormData>(
      future: data,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'تعذر فتح دفتر التلميذ',
                message: '${snap.error}',
                action: FilledButton(
                  onPressed: () => setState(() => data = _load()),
                  child: const Text('إعادة المحاولة'),
                ),
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
              child: LoadingView(message: 'جاري فتح دفتر التلميذ...'),
            ),
          );
        }

        final d = snap.data!;
        final cls = d.student['classes'] as Map<String, dynamic>?;
        final stage = cls?['stages'] as Map<String, dynamic>?;
        final existing = d.existing;
        final bonusAllowed =
            (d.settings?['bonus_roles'] as List<dynamic>? ?? []).contains(role);
        final maxBonus = (d.settings?['max_bonus_points'] as int?) ?? 0;
        final b = int.tryParse(bonus.text) ?? 0;
        final selectedPoints = d.activities
            .where((a) => selected.contains(a['id']))
            .fold<int>(0, (sum, a) => sum + (a['points'] as int));
        final grandTotal = selectedPoints + (bonusAllowed ? b : 0);
        final studentName = d.student['name'] as String? ?? 'التلميذ';
        final avatarBg = _avatarColor(studentName);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'رجوع',
              onPressed: () => context.pop(),
            ),
            title: const Text('دفتر التلميذ الروحي'),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: GlassBadge(
                    label: period.label,
                    color: appPrimary,
                    icon: Icons.calendar_month_rounded,
                    showDot: false,
                  ),
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              return AppContent(
                maxWidth: 760,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: 12,
                ),
                child: ListView(
                  children: [
                    // Student Profile Header Card
                    SolidCard(
                      padding: EdgeInsets.all(isMobile ? 14 : 20),
                      borderRadius: 14,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: isMobile ? 24 : 30,
                            backgroundColor: avatarBg.withValues(
                              alpha: isDark ? 0.25 : 0.12,
                            ),
                            foregroundColor: avatarBg,
                            child: Text(
                              studentName.trim().isNotEmpty
                                  ? studentName.trim().characters.first
                                  : 'ت',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isMobile ? 20 : 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: isMobile ? 16 : 18,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${cls?['name'] ?? 'بدون فصل'} • ${stage?['name'] ?? 'بدون مرحلة'}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isMobile ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (existing != null)
                            const GlassBadge(
                              label: 'معتمد',
                              color: appSuccess,
                              icon: Icons.check_circle_rounded,
                            )
                          else
                            const GlassBadge(
                              label: 'بانتظار التسجيل',
                              color: appWarning,
                              icon: Icons.access_time_rounded,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (existing != null) ...[
                      const StatusBanner(
                        icon: Icons.lock_rounded,
                        tone: StatusTone.success,
                        title: 'تم اعتماد النوتة الروحية لهذا الأسبوع',
                        message:
                            'تم رصد واعتماد درجات التلميذ لهذا الأسبوع بنجاح. لا يمكن تعديل السجل بعد الاعتماد.',
                      ),
                      const SizedBox(height: 14),
                      SolidCard(
                        padding: const EdgeInsets.all(16),
                        borderRadius: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ملخص درجات الأسبوع المسجلة',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: appSuccess.withValues(
                                        alpha: isDark ? 0.15 : 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: appSuccess.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'إجمالي النقاط المعتمدة',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: appSuccess,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${existing['total_points']} نقطة',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: appSuccess,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if ((existing['bonus_points'] as int? ?? 0) >
                                    0) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: appPrimary.withValues(
                                          alpha: isDark ? 0.15 : 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: appPrimary.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'نقاط تشجيعية',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: appPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '+${existing['bonus_points']} ن',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: appPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (existing['submitted_at'] != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                'تاريخ ووقت الحفظ: ${existing['submitted_at']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else ...[
                      ModernSectionHeader(
                        title: 'الأنشطة الروحية',
                        subtitle:
                            'حدد الأنشطة التي التزم بها التلميذ هذا الأسبوع',
                        badge: GlassBadge(
                          label: '$selectedPoints نقطة',
                          color: appPrimary,
                          showDot: false,
                        ),
                      ),
                      const SizedBox(height: 6),

                      if (d.activities.isEmpty)
                        const SolidCard(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'لا توجد أنشطة روحية مفعلة حالياً في النظام.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                      for (final a in d.activities) ...[
                        Builder(
                          builder: (context) {
                            final isChecked = selected.contains(a['id']);
                            return SolidCard(
                              margin: const EdgeInsets.only(bottom: 8),
                              borderRadius: 12,
                              padding: EdgeInsets.zero,
                              color: isChecked
                                  ? appPrimary.withValues(
                                      alpha: isDark ? 0.12 : 0.05,
                                    )
                                  : null,
                              border: isChecked
                                  ? Border.all(color: appPrimary, width: 1.5)
                                  : null,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    if (isChecked) {
                                      selected.remove(a['id'] as String);
                                    } else {
                                      selected.add(a['id'] as String);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: isChecked,
                                        onChanged: (v) {
                                          setState(() {
                                            if (v == true) {
                                              selected.add(a['id'] as String);
                                            } else {
                                              selected.remove(
                                                a['id'] as String,
                                              );
                                            }
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a['name'] as String,
                                              style: TextStyle(
                                                fontWeight: isChecked
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (a['description'] != null &&
                                                (a['description'] as String)
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 1),
                                              Text(
                                                a['description'].toString(),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isChecked
                                              ? appPrimary
                                              : appPrimary.withValues(
                                                  alpha: 0.08,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '+${a['points']} ن',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: isChecked
                                                ? Colors.white
                                                : appPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      if (bonusAllowed) ...[
                        const SizedBox(height: 14),
                        SolidCard(
                          borderRadius: 14,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ModernSectionHeader(
                                title: 'نقاط تشجيعية إضافية',
                                subtitle:
                                    'يمكنك إضافة نقاط إضافية مع ذكر السبب',
                              ),
                              const SizedBox(height: 10),
                              if (isMobile) ...[
                                TextField(
                                  controller: bonus,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'النقاط (أقصى $maxBonus)',
                                    prefixIcon: const Icon(
                                      Icons.star_outline_rounded,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: reason,
                                  decoration: const InputDecoration(
                                    labelText:
                                        'سبب الإضافة (مطلوب إذا وضعت نقاط)',
                                    prefixIcon: Icon(Icons.comment_outlined),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: TextField(
                                        controller: bonus,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'النقاط (أقصى $maxBonus)',
                                          prefixIcon: const Icon(
                                            Icons.star_outline_rounded,
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: reason,
                                        decoration: const InputDecoration(
                                          labelText:
                                              'سبب الإضافة (مطلوب إذا وضعت نقاط)',
                                          prefixIcon: Icon(
                                            Icons.comment_outlined,
                                          ),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Bottom Action Summary Card (Responsive for thumb reach)
                      SolidCard(
                        borderRadius: 14,
                        padding: const EdgeInsets.all(16),
                        color: isDark ? AppDesignColors.darkSurfaceSubtle : appSoftBlue,
                        border: Border.all(
                          color: appPrimary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'مجموع نقاط الأسبوع:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: appMutedInk,
                                        ),
                                      ),
                                      Text(
                                        '$grandTotal نقطة',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                          color: appPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: appPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: saving ? null : _submitRecord,
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                    ),
                                    label: Text(
                                      saving
                                          ? 'جارٍ الاعتماد...'
                                          : 'اعتماد وحفظ السجل',
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'مجموع نقاط الأسبوع',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: appMutedInk,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$grandTotal نقطة',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 24,
                                            color: appPrimary,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: appPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: saving ? null : _submitRecord,
                                    icon: const Icon(
                                      Icons.check_circle_rounded,
                                    ),
                                    label: Text(
                                      saving
                                          ? 'جارٍ الاعتماد...'
                                          : 'اعتماد وحفظ السجل',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }


}

class _StudentFormData {
  const _StudentFormData(
    this.student,
    this.activities,
    this.existing,
    this.settings,
  );
  final Map<String, dynamic> student;
  final List<Map<String, dynamic>> activities;
  final Map<String, dynamic>? existing, settings;
}
