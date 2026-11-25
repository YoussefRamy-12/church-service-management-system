// ignore_for_file: invalid_use_of_protected_member

part of '../spiritual_notebook_page.dart';

extension _NotebookSettingsActions on _NotebookSettingsState {

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
                            ? AppDesignColors.darkSurfaceSubtle
                            : AppDesignColors.lightSurfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppDesignColors.darkBorder
                              : AppDesignColors.lightBorder,
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
                                fontSize: 12,
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
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.light.present.background
                                  : AppColors.light.present.foreground,
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
