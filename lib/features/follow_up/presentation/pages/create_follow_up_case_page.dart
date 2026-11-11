import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/ui/app_ui.dart';
import '../../../auth/domain/entities/servant_profile.dart';
import '../../../auth/domain/entities/session_identity.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../servants/presentation/servant_providers.dart';
import '../../../students/domain/entities/student.dart';
import '../../domain/entities/case_priority.dart';
import '../follow_up_case_providers.dart';
import 'follow_up_case_details_page.dart';

class CreateFollowUpCasePage extends ConsumerStatefulWidget {
  const CreateFollowUpCasePage({
    super.key,
    required this.serviceId,
    this.preselectedStudent,
    this.classId,
  });

  final String serviceId;
  final Student? preselectedStudent;
  final String? classId;

  @override
  ConsumerState<CreateFollowUpCasePage> createState() =>
      _CreateFollowUpCasePageState();
}

class _CreateFollowUpCasePageState
    extends ConsumerState<CreateFollowUpCasePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Student? _selectedStudent;
  String? _selectedClassId;
  CasePriority _priority = CasePriority.medium;
  final Set<String> _selectedServantIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.preselectedStudent;
    _selectedClassId = widget.classId ?? widget.preselectedStudent?.currentClassId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentServantProfileProvider);
    final servantsStream =
        ref.watch(servantRepositoryProvider).watchForService(widget.serviceId);

    final profile = profileAsync.hasValue ? profileAsync.value : null;
    final isLeader = profile?.role == 'overall_leader' ||
        profile?.role == 'overall_helper' ||
        profile?.role == 'stage_leader' ||
        profile?.role == 'class_leader';

    return Scaffold(
      appBar: AppBar(
        title: const Text('فتح حالة متابعة جديدة'),
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
                  // 1. Student Info Display or Selector
                  Text(
                    'التلميذ المعني بالمتابعة',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedStudent != null) ...[
                    GlassCard(
                      borderRadius: 12,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedStudent!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (_selectedStudent!.phone != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedStudent!.phone!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.preselectedStudent == null)
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 18),
                              onPressed: () =>
                                  setState(() => _selectedStudent = null),
                            ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Student Selector from authorized scope
                    ref.watch(followUpStudentItemsProvider(widget.serviceId)).when(
                          data: (items) {
                            return DropdownButtonFormField<Student>(
                              decoration: InputDecoration(
                                hintText: 'اختر التلميذ من النطاق المصرح به...',
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.35),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: items.map((item) {
                                return DropdownMenuItem<Student>(
                                  value: item.student,
                                  child: Text('${item.student.name} (${item.className})'),
                                );
                              }).toList(),
                              onChanged: (student) {
                                setState(() {
                                  _selectedStudent = student;
                                  _selectedClassId = student?.currentClassId;
                                });
                              },
                              validator: (val) {
                                if (val == null) return 'يرجى اختيار التلميذ';
                                return null;
                              },
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (err, _) => Text('خطأ في تحميل الطلاب: $err'),
                        ),
                  ],
                  const SizedBox(height: 20),

                  // 2. Case Title
                  Text(
                    'عنوان حالة المتابعة',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'مثال: غياب متكرر 3 أسابيع، ظرف عائلي، سفر...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى إدخال عنوان الحالة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. Priority Selection
                  Text(
                    'أولوية المتابعة',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: CasePriority.values.map((p) {
                      final isSelected = _priority == p;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              p.icon,
                              size: 14,
                              color: isSelected ? Colors.white : p.color,
                            ),
                            const SizedBox(width: 5),
                            Text(p.arabicLabel),
                          ],
                        ),
                        selectedColor: p.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _priority = p);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 4. Description
                  Text(
                    'تفاصيل الحالة (اختياري)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'أي تفاصيل أو ملاحظات توضيحية للخدام المكلفين...',
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Initial Servant Assignment (Leaders only)
                  if (isLeader) ...[
                    Text(
                      'تكليف خدام للمتابعة (اختياري)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يمكنك تكليف خادم واحد أو أكثر لمتابعة هذه الحالة معاً',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<ServantProfile>>(
                      stream: servantsStream,
                      builder: (context, snapshot) {
                        final allServants = snapshot.data ?? const [];
                        final classId = _selectedClassId;
                        final eligibleServants = allServants.where((s) {
                          if (!s.isActive) return false;
                          if (classId != null &&
                              s.classId != null &&
                              s.classId != classId) {
                            return false;
                          }
                          return true;
                        }).toList();

                        if (eligibleServants.isEmpty) {
                          return const Text(
                            'لا يوجد خدام متاحين في نطاق هذا الفصل.',
                            style: TextStyle(fontSize: 12),
                          );
                        }

                        return Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: eligibleServants.map((s) {
                            final isSelected = _selectedServantIds.contains(s.id);
                            return FilterChip(
                              selected: isSelected,
                              label: Text('${s.name} (${formatRoleLabel(s.role)})'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedServantIds.add(s.id);
                                  } else {
                                    _selectedServantIds.remove(s.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 6. Submit Button
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
                      label: Text(_saving ? 'جاري الفتح...' : 'إنشاء حالة المتابعة'),
                      onPressed: _saving ? null : _createCase,
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

  Future<void> _createCase() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار التلميذ أولاً')),
      );
      return;
    }

    final classId = _selectedClassId ?? _selectedStudent?.currentClassId;
    if (classId == null || classId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('التلميذ غير منسوب لفصل محدد')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = await ref.read(currentServantProfileProvider.future);
      final identity = await ref.read(currentSessionIdentityProvider.future);
      final actorId = profile?.id ??
          (identity is SuperAdminIdentity ? identity.profile.id : null);

      if (actorId == null) {
        throw Exception('لم يتم التعرف على حساب الخادم المسجل');
      }

      final newCase = await ref.read(followUpCaseRepositoryProvider).createCase(
            serviceId: widget.serviceId,
            studentId: _selectedStudent!.id,
            classId: classId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
            priority: _priority,
            createdBy: actorId,
            initialServantIds: _selectedServantIds.toList(),
          );

      invalidateFollowUpCaseData(
        ref,
        serviceId: widget.serviceId,
        studentId: _selectedStudent!.id,
        caseId: newCase.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم فتح حالة المتابعة بنجاح')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FollowUpCaseDetailsPage(
              serviceId: widget.serviceId,
              caseId: newCase.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الحالة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
