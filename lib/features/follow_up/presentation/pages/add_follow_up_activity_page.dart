import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/ui/app_ui.dart';
import '../../../auth/domain/entities/session_identity.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../domain/entities/activity_type.dart';
import '../follow_up_case_providers.dart';

class AddFollowUpActivityPage extends ConsumerStatefulWidget {
  const AddFollowUpActivityPage({
    super.key,
    required this.caseId,
    required this.caseTitle,
    required this.studentName,
  });

  final String caseId;
  final String caseTitle;
  final String studentName;

  @override
  ConsumerState<AddFollowUpActivityPage> createState() =>
      _AddFollowUpActivityPageState();
}

class _AddFollowUpActivityPageState
    extends ConsumerState<AddFollowUpActivityPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  ActivityType _selectedType = ActivityType.call;
  DateTime _activityDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل نشاط متابعة'),
      ),
      body: AmbientBackground(
        intensity: 0.3,
        child: AppContent(
          maxWidth: 680,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Case Header Context Banner
                  GlassCard(
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_shared_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.caseTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'التلميذ: ${widget.studentName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Activity Type Selector
                  Text(
                    'نوع المتابعة',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActivityType.call,
                      ActivityType.visit,
                      ActivityType.message,
                      ActivityType.inPerson,
                      ActivityType.note,
                    ].map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type.icon,
                              size: 16,
                              color: isSelected ? Colors.white : type.color,
                            ),
                            const SizedBox(width: 6),
                            Text(type.arabicLabel),
                          ],
                        ),
                        selectedColor: type.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedType = type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 2. Activity Date Picker
                  Text(
                    'تاريخ المتابعة',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            dateFormatter.format(_activityDate),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          const Text(
                            'تغيير التاريخ',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Activity Notes / Description
                  Text(
                    'تفاصيل المتابعة ونتيجتها',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'اكتب ما دار خلال الاتصال أو الزيارة، رد التلميذ أو ولي الأمر، والخطوة القادمة...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى كتابة تفاصيل المتابعة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // 4. Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(_saving ? 'جاري الحفظ...' : 'تسجيل المتابعة'),
                      onPressed: _saving ? null : _saveActivity,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _activityDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _activityDate = picked);
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final profile = await ref.read(currentServantProfileProvider.future);
      final identity = await ref.read(currentSessionIdentityProvider.future);
      final actorId = profile?.id ??
          (identity is SuperAdminIdentity ? identity.profile.id : null);

      if (actorId == null) {
        throw Exception('لم يتم التعرف على حساب الخادم المسجل');
      }

      final dateStr = DateFormat('yyyy-MM-dd').format(_activityDate);

      await ref.read(followUpCaseRepositoryProvider).recordActivity(
            caseId: widget.caseId,
            activityType: _selectedType,
            description: _descriptionController.text.trim(),
            createdBy: actorId,
            activityDate: dateStr,
          );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسجيل نشاط المتابعة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر تسجيل النشاط: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

