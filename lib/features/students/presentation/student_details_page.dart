import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../service/presentation/service_providers.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/entities/sensitive_student_data.dart';
import '../domain/entities/student.dart';
import '../domain/student_permissions.dart';
import 'student_providers.dart';
import '../../../app/ui/app_ui.dart';
import '../../../app/design/app_colors.dart';
import '../../../app/ui/components/status_chip.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../../core/ui/phone_contact_actions.dart';
import 'widgets/student_attendance_tab.dart';
import 'widgets/student_edit_dialog.dart';
import 'widgets/student_follow_up_tab.dart';

export 'widgets/student_edit_dialog.dart';

enum _StudentAction { assignClass, archive }

class StudentDetailsPage extends ConsumerStatefulWidget {
  const StudentDetailsPage({super.key, required this.student});

  final Student student;

  @override
  ConsumerState<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends ConsumerState<StudentDetailsPage> {
  late Student student;
  SensitiveStudentData? _sensitiveData;
  String? _studentClassName;
  String? _studentStageName;
  bool _downloadingPdf = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    student = widget.student;
    _loadSensitiveData();
    _loadClassDetails();
  }

  Future<void> _loadClassDetails() async {
    final classId = student.currentClassId ?? student.proposedClassId;
    if (classId == null) return;
    try {
      final serviceRepository = ref.read(serviceRepositoryProvider);
      final stages = await serviceRepository.getStages(student.serviceId);
      for (final stage in stages) {
        final classes = await serviceRepository.getClasses(stage.id);
        for (final item in classes) {
          if (item.id == classId && mounted) {
            setState(() {
              _studentStageName = stage.name;
              _studentClassName = item.name;
            });
            return;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSensitiveData() async {
    try {
      final data = await ref
          .read(studentRepositoryProvider)
          .getSensitiveData(
            student.id,
            serviceId: student.serviceId,
            identityServiceId: student.identityServiceId,
          );
      if (mounted && data != null) {
        setState(() => _sensitiveData = data);
      }
    } catch (_) {}
  }

  Future<void> _downloadStudentCardPdf() async {
    setState(() => _downloadingPdf = true);
    try {
      final pdfService = ref.read(studentQrPdfServiceProvider);
      final serviceRepo = ref.read(serviceRepositoryProvider);

      String? serviceName;
      String? className;

      try {
        final stages = await serviceRepo.getStages(student.serviceId);
        for (final stage in stages) {
          final classes = await serviceRepo.getClasses(stage.id);
          for (final c in classes) {
            if (c.id == (student.currentClassId ?? student.proposedClassId)) {
              className = '${stage.name} • ${c.name}';
              break;
            }
          }
          if (className != null) break;
        }
      } catch (_) {}

      final pdfBytes = await pdfService.generateSingleStudentCardPdf(
        student: student,
        serviceName: serviceName,
        className: className,
      );

      pdfService.downloadPdf(
        bytes: pdfBytes,
        filename: 'student_card_${student.id.substring(0, 8)}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تنزيل بطاقة الطالب بنجاح.')),
        );
      }
    } catch (e) {
      debugPrint('Presentation operation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر إتمام العملية. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingPdf = false);
    }
  }

  bool _canApprove(String role) =>
      role == 'overall_leader' || role == 'overall_helper';

  String _date(DateTime? value) =>
      value == null ? 'غير محدد' : value.toLocal().toString().split(' ').first;

  Future<void> _approve() async {
    final isOffline = ref.read(offlineSyncEnabledProvider);
    try {
      final updated = await ref
          .read(studentRepositoryProvider)
          .approvePending(student.id, membershipId: student.membershipId);
      if (!mounted) return;
      setState(() => student = updated);
      _loadClassDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'تم اعتماد التلميذ محليًا وسيتم مزامنته.'
                : 'تم اعتماد التلميذ بنجاح.',
          ),
        ),
      );
    } catch (error) {
      debugPrint('Presentation operation failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر اعتماد التلميذ: ${NetworkErrorFormatter.format(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _edit() async {
    final result = await showDialog<StudentEditResult>(
      context: context,
      builder: (_) => StudentEditDialog(
        student: student,
        sensitiveData: _sensitiveData,
        onDelete: _delete,
      ),
    );
    if (result == null) return;

    final isOffline = ref.read(offlineSyncEnabledProvider);
    try {
      final updated = await ref
          .read(studentRepositoryProvider)
          .updateStudent(
            studentId: student.id,
            membershipId: student.membershipId,
            name: result.name,
            birthDate: result.birthDate,
            phone: result.phone,
            school: result.school,
            grade: result.grade,
            isDeacon: result.isDeacon,
            enrollmentAt: result.enrollmentAt,
            photoPath: result.photoPath,
            notes: result.notes,
            sensitiveData: result.sensitiveData,
          );
      if (!mounted) return;
      setState(() {
        student = updated;
        if (result.sensitiveData != null) {
          _sensitiveData = result.sensitiveData;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'تم حفظ التعديلات محليًا وسيتم مزامنتها.'
                : 'تم حفظ التعديلات بنجاح.',
          ),
        ),
      );
    } catch (error) {
      debugPrint('Presentation operation failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر حفظ التعديلات: ${NetworkErrorFormatter.format(error)}',
          ),
        ),
      );
    }
  }

  Future<void> _delete() async {
    if (_isDeleting) return;

    final isOffline = ref.read(offlineSyncEnabledProvider);
    final confirmed = await showDeleteStudentConfirmationDialog(
      context: context,
      studentName: student.name,
      isOffline: isOffline,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref
          .read(studentRepositoryProvider)
          .deleteStudent(student.id, membershipId: student.membershipId);

      // Refresh list caches
      if (student.currentClassId != null) {
        try {
          await ref
              .read(studentRepositoryProvider)
              .refreshStudents(student.currentClassId!);
        } catch (_) {}
      }
      try {
        await ref
            .read(studentRepositoryProvider)
            .refreshStudentsForService(student.serviceId);
      } catch (_) {}

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'تمت أرشفة عضوية التلميذ محليًا وستتم مزامنتها.'
                : 'تمت أرشفة عضوية التلميذ بنجاح.',
          ),
          backgroundColor: AppColors.of(context).present.foreground,
        ),
      );
    } catch (error) {
      debugPrint('Presentation operation failed: $error');
      if (!mounted) return;
      final message = error is StateError
          ? error.message
          : (error is PostgrestException && error.code == '23503'
                ? 'تعذر أرشفة عضوية التلميذ بسبب وجود تعارض في السجلات المرتبطة.'
                : 'تعذر أرشفة العضوية: ${NetworkErrorFormatter.format(error)}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppDesignColors.lightError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _changeClass() async {
    final services = ref.read(serviceRepositoryProvider);
    try {
      await services.refreshStages(student.serviceId);
    } catch (_) {}
    if (!mounted) return;
    final stages = await services.getStages(student.serviceId);
    final choices = <(String, String)>[];
    for (final stage in stages) {
      try {
        await services.refreshClasses(stage.id);
      } catch (_) {}
      for (final item in await services.getClasses(stage.id)) {
        choices.add((item.id, '${stage.name} • ${item.name}'));
      }
    }
    if (!mounted || choices.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أضف مرحلة وفصلًا قبل نقل التلميذ.')),
        );
      }
      return;
    }
    final selected = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('تعيين فصل للتلميذ'),
        children: [
          for (final item in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, item),
              child: Text(item.$2),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final isOffline = ref.read(offlineSyncEnabledProvider);
    try {
      final updated = await ref
          .read(studentRepositoryProvider)
          .assignClass(
            student.id,
            selected.$1,
            membershipId: student.membershipId,
          );
      if (!mounted) return;
      setState(() => student = updated);
      _loadClassDetails();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'تم تحديث الفصل محليًا وستتم مزامنته.'
                : 'تم تحديث الفصل بنجاح.',
          ),
        ),
      );
    } catch (error) {
      debugPrint('Presentation operation failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر تغيير الفصل: ${NetworkErrorFormatter.format(error)}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentServantProfileProvider);
    final profile = profileState.hasValue ? profileState.value : null;
    final isSuperAdmin = ref.watch(isSuperAdminProvider);
    final canApprove =
        isSuperAdmin || (profile != null && _canApprove(profile.role));
    final canEdit = canEditOrDeleteStudent(
      student: student,
      profile: profile,
      isSuperAdmin: isSuperAdmin,
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        key: const Key('student_details'),
        appBar: AppBar(
          title: Text(student.name),
          bottom: const TabBar(
            tabs: [
              Tab(
                key: Key('student_tab_profile'),
                icon: Icon(Icons.person_outline),
                text: 'الملف',
              ),
              Tab(
                key: Key('student_tab_attendance'),
                icon: Icon(Icons.fact_check_outlined),
                text: 'الحضور',
              ),
              Tab(
                key: Key('student_tab_follow_up'),
                icon: Icon(Icons.history_rounded),
                text: 'المتابعة',
              ),
            ],
          ),
          actions: [
            // Single contextual primary: approve OR edit, never both
            if (student.isPending && canApprove)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: FilledButton.icon(
                  key: const Key('student_approve'),
                  onPressed: _isDeleting ? null : _approve,
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: const Text('اعتماد'),
                ),
              )
            else if (canEdit)
              IconButton(
                key: const Key('student_edit'),
                icon: const Icon(Icons.edit),
                tooltip: 'تعديل',
                onPressed: _isDeleting ? null : _edit,
              ),
            // Destructive & secondary in overflow
            if (canEdit)
              PopupMenuButton<_StudentAction>(
                key: const Key('student_overflow_menu'),
                tooltip: 'المزيد',
                onSelected: (action) {
                  if (action == _StudentAction.assignClass) _changeClass();
                  if (action == _StudentAction.archive) _delete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _StudentAction.assignClass,
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.move_to_inbox_outlined),
                      title: Text('تغيير الفصل'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: _StudentAction.archive,
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.archive_outlined,
                        color: AppDesignColors.lightError,
                      ),
                      title: Text(
                        'أرشفة عضوية التلميذ',
                        style: TextStyle(color: AppDesignColors.lightError),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: TabBarView(
          children: [
            AppContent(
              maxWidth: 900,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 32),
                children: [
                  _StudentProfileHeader(
                    student: student,
                    stageName: _studentStageName,
                    className: _studentClassName,
                  ),
                  const SizedBox(height: 8),
                  // 1. Basic Info Section
                  _section(context, 'بيانات الطالب الأساسية', [
                    _row('الاسم الكامل', student.name),
                    _row('تاريخ الميلاد', _date(student.birthDate)),
                    _row(
                      'المرحلة',
                      _studentStageName ??
                          (student.currentClassId == null &&
                                  student.proposedClassId != null
                              ? 'مرحلة الفصل المقترح'
                              : 'غير مسجل'),
                    ),
                    _row(
                      'الفصل',
                      _studentClassName ??
                          (student.currentClassId == null &&
                                  student.proposedClassId != null
                              ? 'فصل مقترح'
                              : 'غير مسجل'),
                    ),
                    _row('الصف الدراسي', student.grade ?? 'غير مسجل'),
                    _phoneRow('تليفون الطالب', student.phone),
                    _row('المدرسة', student.school ?? 'غير مسجل'),
                    _row('شماس', student.isDeacon ? 'شماس' : 'غير مرسوم'),
                  ]),

                  // QR Code Section (below basic data)
                  _section(context, 'رمز QR الخاص بالطالب', [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: QrImageView(
                              data: student.id,
                              version: QrVersions.auto,
                              size: 160.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            student.id,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            key: const Key('download_student_qr_pdf'),
                            onPressed: _downloadingPdf
                                ? null
                                : _downloadStudentCardPdf,
                            icon: _downloadingPdf
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 20,
                                  ),
                            label: Text(
                              _downloadingPdf
                                  ? 'جاري إنشاء البطاقة...'
                                  : 'تحميل بطاقة الطالب PDF',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),

                  // 2. Address Section
                  _section(context, 'العنوان', [
                    _row(
                      'العنوان الكامل',
                      _sensitiveData?.fullAddress.isNotEmpty == true
                          ? _sensitiveData!.fullAddress
                          : 'غير محدد',
                    ),
                    if (_sensitiveData?.addressBuilding != null)
                      _row('رقم العقار', _sensitiveData!.addressBuilding!),
                    if (_sensitiveData?.addressStreet != null)
                      _row('الشارع', _sensitiveData!.addressStreet!),
                    if (_sensitiveData?.addressFloor != null)
                      _row('الدور', _sensitiveData!.addressFloor!),
                    if (_sensitiveData?.addressApartment != null)
                      _row('الشقة', _sensitiveData!.addressApartment!),
                  ]),

                  // 3. Family Info Section
                  _section(context, 'بيانات الأسرة', [
                    _row('وظيفة الأب', _sensitiveData?.fatherJob ?? 'غير مسجل'),
                    _phoneRow(
                      'تليفون الأب',
                      _sensitiveData?.effectiveFatherPhone,
                    ),
                    _row('اسم الأم', _sensitiveData?.motherName ?? 'غير مسجل'),
                    _row('وظيفة الأم', _sensitiveData?.motherJob ?? 'غير مسجل'),
                    _phoneRow(
                      'تليفون الأم',
                      _sensitiveData?.effectiveMotherPhone,
                    ),
                    _row(
                      'عدد أفراد الأسرة',
                      _sensitiveData?.familySize != null
                          ? '${_sensitiveData!.familySize} أفراد'
                          : 'غير محدد',
                    ),
                    _row(
                      'ترتيب الطالب بين إخوته',
                      _sensitiveData?.birthOrder != null
                          ? '${_sensitiveData!.birthOrder}'
                          : 'غير محدد',
                    ),
                  ]),

                  // 4. Study & Pastoral Section
                  _section(context, 'بيانات الدراسة والخدمة', [
                    _row(
                      'السنة الدراسية',
                      _sensitiveData?.studyYear ?? 'غير مسجل',
                    ),
                    _row(
                      'أب الاعتراف',
                      _sensitiveData?.confessor ?? 'غير مسجل',
                    ),
                    _row('تاريخ الالتحاق', _date(student.enrollmentAt)),
                  ]),

                  // 5. Sensitive & Health Section
                  _section(context, 'البيانات الصحية والحساسة', [
                    _row(
                      'ملاحظات صحية أو حساسية',
                      _sensitiveData?.medicalNotes ?? 'غير مسجل',
                    ),
                    _row(
                      'الحالة المادية للأسرة',
                      _sensitiveData?.financialStatus ?? 'غير مسجل',
                    ),
                  ]),

                  // 6. General Notes
                  _section(context, 'ملاحظات عامة', [
                    _row('ملاحظات', student.notes ?? 'غير مسجل'),
                  ]),
                ],
              ),
            ),
            StudentAttendanceTab(student: student),
            StudentFollowUpTab(student: student),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _phoneRow(String label, String? phone) {
    final value = phone?.trim() ?? '';
    if (value.isEmpty) return _row(label, 'غير محدد');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
          PhoneContactActions(phone: value, compact: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StudentProfileHeader extends StatelessWidget {
  const _StudentProfileHeader({
    required this.student,
    this.stageName,
    this.className,
  });

  final Student student;
  final String? stageName;
  final String? className;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      if (stageName != null && stageName!.isNotEmpty) stageName!,
      if (className != null && className!.isNotEmpty) className!,
    ].join(' • ');

    final statusStatus = student.isPending
        ? AppStatus.pending
        : AppStatus.present;
    final quickPhone = student.phone != null && student.phone!.trim().isNotEmpty
        ? student.phone!.trim()
        : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    student.name.isEmpty ? '؟' : student.name.characters.first,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StatusChip(
                        status: statusStatus,
                        label: student.isPending ? 'بانتظار الاعتماد' : 'معتمد',
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (quickPhone != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'تواصل سريع:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  PhoneContactActions(phone: quickPhone, compact: false),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
