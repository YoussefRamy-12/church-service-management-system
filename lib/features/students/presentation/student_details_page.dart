import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../service/presentation/service_providers.dart';

import '../../auth/presentation/auth_providers.dart';
import '../domain/entities/sensitive_student_data.dart';
import '../domain/entities/student.dart';
import '../domain/student_permissions.dart';
import 'student_providers.dart';
import '../../follow_up/presentation/follow_up_page.dart';
import '../../../app/ui/app_ui.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../attendance/presentation/attendance_providers.dart';
import '../../attendance/presentation/meeting_providers.dart';
import '../../follow_up/presentation/follow_up_providers.dart';

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
          .getSensitiveData(student.id);
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر إنشاء بطاقة الطالب: $e')));
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
          .approvePending(student.id);
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر اعتماد التلميذ: ${NetworkErrorFormatter.format(error)}')));
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر حفظ التعديلات: ${NetworkErrorFormatter.format(error)}')));
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
      await ref.read(studentRepositoryProvider).deleteStudent(student.id);

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
                ? 'تم حذف التلميذ محليًا وستتم مزامنة الحذف.'
                : 'تم حذف التلميذ بنجاح.',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message
          : (error is PostgrestException && error.code == '23503'
              ? 'تعذر حذف التلميذ لوجود سجلات مرتبطة به (مثل الحضور أو الافتقاد).'
              : 'تعذر حذف التلميذ: ${NetworkErrorFormatter.format(error)}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFDC2626),
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
          .assignClass(student.id, selected.$1);
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر تغيير الفصل: ${NetworkErrorFormatter.format(error)}')));
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
            if (canEdit)
              IconButton(
                key: const Key('student_assign_class'),
                tooltip: 'تغيير الفصل',
                onPressed: _isDeleting ? null : _changeClass,
                icon: const Icon(Icons.move_to_inbox_outlined),
              ),
            if (canEdit)
              IconButton(
                key: const Key('student_delete'),
                tooltip: 'حذف التلميذ',
                onPressed: _isDeleting ? null : _delete,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
            if (canEdit)
              IconButton(
                key: const Key('student_edit'),
                icon: const Icon(Icons.edit),
                tooltip: 'تعديل',
                onPressed: _isDeleting ? null : _edit,
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
                  if (student.isPending && canApprove)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.verified_outlined),
                        title: const Text('التلميذ في انتظار الاعتماد'),
                        subtitle: const Text(
                          'سيتم اعتماد الفصل المقترح كالفصل الحالي.',
                        ),
                        trailing: FilledButton(
                          onPressed: _approve,
                          child: const Text('اعتماد'),
                        ),
                      ),
                    ),
                  Center(
                    child: CircleAvatar(
                      radius: 42,
                      child: Text(
                        student.name.characters.first,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  // QR Code Section
                  _section(context, 'رمز QR الخاص بالطالب', [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
                              backgroundColor: const Color(0xFF00236F),
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

                  // 1. Basic Info Section
                  _section(context, 'بيانات الطالب الأساسية', [
                    _row('الاسم الكامل', student.name),
                    _row(
                      'الحالة',
                      student.isPending
                          ? 'Pending — بانتظار الاعتماد'
                          : 'معتمد',
                    ),
                    _row('تاريخ الميلاد', _date(student.birthDate)),
                    _row(
                      'المرحلة',
                      _studentStageName ??
                          (student.currentClassId == null &&
                                  student.proposedClassId != null
                              ? 'مرحلة الفصل المقترح'
                              : 'غير محددة'),
                    ),
                    _row(
                      'الفصل',
                      _studentClassName ??
                          (student.currentClassId == null &&
                                  student.proposedClassId != null
                              ? 'فصل مقترح'
                              : 'غير محدد'),
                    ),
                    _row('الصف الدراسي', student.grade ?? 'غير محدد'),
                    _row('تليفون الطالب', student.phone ?? 'غير محدد'),
                    _row('المدرسة', student.school ?? 'غير محددة'),
                    _row('شماس', student.isDeacon ? 'شماس' : 'غير مرسوم'),
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
                    _row(
                      'وظيفة الأب',
                      _sensitiveData?.fatherJob ?? 'غير محددة',
                    ),
                    _row(
                      'تليفون الأب',
                      _sensitiveData?.effectiveFatherPhone ?? 'غير محدد',
                    ),
                    _row('اسم الأم', _sensitiveData?.motherName ?? 'غير محدد'),
                    _row(
                      'وظيفة الأم',
                      _sensitiveData?.motherJob ?? 'غير محددة',
                    ),
                    _row(
                      'تليفون الأم',
                      _sensitiveData?.effectiveMotherPhone ?? 'غير محدد',
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
                      _sensitiveData?.studyYear ?? 'غير محددة',
                    ),
                    _row(
                      'أب الاعتراف',
                      _sensitiveData?.confessor ?? 'غير محدد',
                    ),
                    _row('تاريخ الالتحاق', _date(student.enrollmentAt)),
                  ]),

                  // 5. Sensitive & Health Section
                  _section(context, 'البيانات الصحية والحساسة', [
                    _row(
                      'ملاحظات صحية أو حساسية',
                      _sensitiveData?.medicalNotes ?? 'لا توجد ملاحظات صحية',
                    ),
                    _row(
                      'الحالة المادية للأسرة',
                      _sensitiveData?.financialStatus ?? 'غير محددة',
                    ),
                  ]),

                  // 6. General Notes
                  _section(context, 'ملاحظات عامة', [
                    _row('ملاحظات', student.notes ?? 'لا توجد ملاحظات عامة'),
                  ]),
                ],
              ),
            ),
            _StudentAttendanceTab(student: student),
            _StudentFollowUpTab(student: student),
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
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StudentAttendanceTab extends ConsumerStatefulWidget {
  const _StudentAttendanceTab({required this.student});
  final Student student;

  @override
  ConsumerState<_StudentAttendanceTab> createState() =>
      _StudentAttendanceTabState();
}

class _StudentAttendanceTabState extends ConsumerState<_StudentAttendanceTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(meetingRepositoryProvider).refresh(widget.student.serviceId);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final attendanceStream = ref
        .watch(attendanceRepositoryProvider)
        .watchForStudent(student.id);
    final meetingsStream = ref
        .watch(meetingRepositoryProvider)
        .watchMeetings(student.serviceId);
    return AppContent(
      maxWidth: 900,
      child: StreamBuilder(
        stream: meetingsStream,
        builder: (context, meetingSnapshot) => StreamBuilder(
          stream: attendanceStream,
          builder: (context, snapshot) {
          if (snapshot.hasError || meetingSnapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'تعذر تحميل سجل الحضور',
            );
          }
          if (!snapshot.hasData || !meetingSnapshot.hasData) {
            return const LoadingView(message: 'جاري تحميل سجل الحضور...');
          }
          final meetingsById = {
            for (final meeting in meetingSnapshot.data!) meeting.id: meeting,
          };
          final rows = [...snapshot.data!]
            ..sort((a, b) {
              final aDate = meetingsById[a.meetingId]?.meetingDate ?? a.checkedInAt;
              final bDate = meetingsById[b.meetingId]?.meetingDate ?? b.checkedInAt;
              return bDate.compareTo(aDate);
            });
          if (rows.isEmpty) {
            return const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'لا يوجد سجل حضور بعد',
              message: 'ستظهر سجلات الاجتماعات التي سُجل فيها التلميذ هنا.',
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              Text(
                'سجل الحضور',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final record in rows)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.check_rounded),
                    ),
                    title: Text(
                      meetingsById[record.meetingId] == null
                          ? 'موعد الاجتماع غير متاح'
                          : '${meetingsById[record.meetingId]!.name} — ${DateFormat('yyyy/MM/dd').format(meetingsById[record.meetingId]!.meetingDate)}',
                    ),
                    subtitle: Text(
                      meetingsById[record.meetingId] == null
                          ? 'تاريخ تسجيل الحضور: ${DateFormat('yyyy/MM/dd HH:mm').format(record.checkedInAt.toLocal())}'
                          : 'وقت تسجيل الحضور: ${DateFormat('HH:mm').format(record.checkedInAt.toLocal())}',
                    ),
                    trailing: Icon(
                      record.syncState == 'synced'
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_upload_outlined,
                      semanticLabel: record.syncState == 'synced'
                          ? 'تمت المزامنة'
                          : 'بانتظار المزامنة',
                    ),
                  ),
                ),
            ],
          );
        },
        ),
      ),
    );
  }
}

class _StudentFollowUpTab extends ConsumerWidget {
  const _StudentFollowUpTab({required this.student});
  final Student student;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref
        .watch(followUpRepositoryProvider)
        .watchForStudent(student.id);
    return AppContent(
      maxWidth: 900,
      child: StreamBuilder(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const EmptyState(
              icon: Icons.error_outline,
              title: 'تعذر تحميل سجل المتابعة',
            );
          }
          if (!snapshot.hasData) {
            return const LoadingView(message: 'جاري تحميل سجل المتابعة...');
          }
          final rows = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'سجل المتابعة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('student_follow_up_add'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowUpPage(student: student),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const EmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'لا توجد متابعات بعد',
                  message: 'سجّل متابعة جديدة لتظهر في هذا السجل.',
                ),
              for (final record in rows)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      record.contactStatus == 'contacted'
                          ? Icons.call_made_rounded
                          : Icons.phone_missed_rounded,
                    ),
                    title: Text(
                      '${record.followUpDate} — ${record.contactStatus == 'contacted' ? 'تم التواصل' : 'لم يتم التواصل'}',
                    ),
                    subtitle: Text(
                      record.notes?.isNotEmpty == true
                          ? record.notes!
                          : (record.actionRequired?.isNotEmpty == true
                                ? record.actionRequired!
                                : 'لا توجد ملاحظات'),
                    ),
                    trailing: record.anotherFollowUpNeeded
                        ? const Tooltip(
                            message: 'متابعة أخرى مطلوبة',
                            child: Icon(Icons.event_repeat_rounded),
                          )
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class StudentEditResult {
  const StudentEditResult({
    required this.name,
    required this.birthDate,
    required this.phone,
    required this.school,
    required this.grade,
    required this.isDeacon,
    required this.enrollmentAt,
    required this.photoPath,
    required this.notes,
    this.sensitiveData,
  });

  final String name;
  final DateTime? birthDate;
  final String? phone;
  final String? school;
  final String? grade;
  final bool isDeacon;
  final DateTime? enrollmentAt;
  final String? photoPath;
  final String? notes;
  final SensitiveStudentData? sensitiveData;
}

class StudentEditDialog extends StatefulWidget {
  const StudentEditDialog({
    super.key,
    required this.student,
    this.sensitiveData,
    this.onDelete,
  });

  final Student student;
  final SensitiveStudentData? sensitiveData;
  final VoidCallback? onDelete;

  @override
  State<StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends State<StudentEditDialog> {
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController school;
  late final TextEditingController notes;
  late bool isDeacon;
  late DateTime? birthDate;

  // Address
  late final TextEditingController addressBuilding;
  late final TextEditingController addressStreet;
  late final TextEditingController addressFloor;
  late final TextEditingController addressApartment;

  // Family
  late final TextEditingController fatherJob;
  late final TextEditingController fatherPhone;
  late final TextEditingController motherName;
  late final TextEditingController motherJob;
  late final TextEditingController motherPhone;
  late final TextEditingController familySize;
  late final TextEditingController birthOrder;

  // Pastoral & Sensitive
  late final TextEditingController confessor;
  late final TextEditingController medicalNotes;
  String? financialStatus;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.student.name);
    phone = TextEditingController(text: widget.student.phone ?? '');
    school = TextEditingController(text: widget.student.school ?? '');
    notes = TextEditingController(text: widget.student.notes ?? '');
    isDeacon = widget.student.isDeacon;
    birthDate = widget.student.birthDate;

    final s = widget.sensitiveData;
    addressBuilding = TextEditingController(text: s?.addressBuilding ?? '');
    addressStreet = TextEditingController(text: s?.addressStreet ?? '');
    addressFloor = TextEditingController(text: s?.addressFloor ?? '');
    addressApartment = TextEditingController(text: s?.addressApartment ?? '');

    fatherJob = TextEditingController(text: s?.fatherJob ?? '');
    fatherPhone = TextEditingController(text: s?.effectiveFatherPhone ?? '');
    motherName = TextEditingController(text: s?.motherName ?? '');
    motherJob = TextEditingController(text: s?.motherJob ?? '');
    motherPhone = TextEditingController(text: s?.effectiveMotherPhone ?? '');
    familySize = TextEditingController(text: s?.familySize?.toString() ?? '');
    birthOrder = TextEditingController(text: s?.birthOrder?.toString() ?? '');

    confessor = TextEditingController(text: s?.confessor ?? '');
    medicalNotes = TextEditingController(text: s?.medicalNotes ?? '');
    financialStatus = s?.financialStatus;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    school.dispose();
    notes.dispose();
    addressBuilding.dispose();
    addressStreet.dispose();
    addressFloor.dispose();
    addressApartment.dispose();
    fatherJob.dispose();
    fatherPhone.dispose();
    motherName.dispose();
    motherJob.dispose();
    motherPhone.dispose();
    familySize.dispose();
    birthOrder.dispose();
    confessor.dispose();
    medicalNotes.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2013),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => birthDate = picked);
    }
  }

  String _date(DateTime? value) =>
      value == null ? 'غير محدد' : value.toLocal().toString().split(' ').first;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'تعديل بيانات التلميذ',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 620),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'البيانات الأساسية',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل للطالب *',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('تاريخ الميلاد: ${_date(birthDate)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: _pickBirthDate,
                ),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'تليفون الطالب'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: school,
                decoration: const InputDecoration(labelText: 'المدرسة'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('شماس'),
                value: isDeacon,
                onChanged: (val) => setState(() => isDeacon = val),
              ),

              const Divider(height: 28),
              const Text(
                'العنوان',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: addressBuilding,
                      decoration: const InputDecoration(
                        labelText: 'رقم العقار',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: addressStreet,
                      decoration: const InputDecoration(labelText: 'شارع'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: addressFloor,
                      decoration: const InputDecoration(labelText: 'دور'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: addressApartment,
                      decoration: const InputDecoration(labelText: 'شقة'),
                    ),
                  ),
                ],
              ),

              const Divider(height: 28),
              const Text(
                'بيانات الأسرة',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fatherJob,
                      decoration: const InputDecoration(
                        labelText: 'وظيفة الأب',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fatherPhone,
                      decoration: const InputDecoration(
                        labelText: 'تليفون الأب',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: motherName,
                      decoration: const InputDecoration(labelText: 'اسم الأم'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: motherJob,
                      decoration: const InputDecoration(
                        labelText: 'وظيفة الأم',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motherPhone,
                decoration: const InputDecoration(labelText: 'تليفون الأم'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: familySize,
                      decoration: const InputDecoration(
                        labelText: 'عدد أفراد الأسرة',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: birthOrder,
                      decoration: const InputDecoration(
                        labelText: 'ترتيب الطالب بين إخوته',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const Divider(height: 28),
              const Text(
                'بيانات الخدمة والرعاية',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confessor,
                decoration: const InputDecoration(labelText: 'أب الاعتراف'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: medicalNotes,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات صحية أو حساسية',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: financialStatus,
                decoration: const InputDecoration(
                  labelText: 'الحالة المادية للأسرة',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('غير محدد')),
                  DropdownMenuItem(
                    value: FinancialStatus.natural,
                    child: Text(FinancialStatus.natural),
                  ),
                  DropdownMenuItem(
                    value: FinancialStatus.brothersOfLord,
                    child: Text(FinancialStatus.brothersOfLord),
                  ),
                  DropdownMenuItem(
                    value: FinancialStatus.hiddenFamily,
                    child: Text(FinancialStatus.hiddenFamily),
                  ),
                ],
                onChanged: (val) => setState(() => financialStatus = val),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظات عامة'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton.icon(
            key: const Key('student_dialog_delete'),
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete!();
            },
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            label: const Text(
              'حذف التلميذ',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty) return;

            final famSize = int.tryParse(familySize.text.trim());
            final bOrder = int.tryParse(birthOrder.text.trim());
            final validationError =
                SensitiveStudentData.validateFamilyAndFinance(
                  familySize: famSize,
                  birthOrder: bOrder,
                  financialStatus: financialStatus,
                );

            if (validationError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(validationError),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
              return;
            }

            final updatedSensitive = SensitiveStudentData(
              studentId: widget.student.id,
              fatherJob: fatherJob.text.trim().isEmpty
                  ? null
                  : fatherJob.text.trim(),
              fatherPhone: fatherPhone.text.trim().isEmpty
                  ? null
                  : fatherPhone.text.trim(),
              motherName: motherName.text.trim().isEmpty
                  ? null
                  : motherName.text.trim(),
              motherJob: motherJob.text.trim().isEmpty
                  ? null
                  : motherJob.text.trim(),
              motherPhone: motherPhone.text.trim().isEmpty
                  ? null
                  : motherPhone.text.trim(),
              familySize: famSize,
              birthOrder: bOrder,
              confessor: confessor.text.trim().isEmpty
                  ? null
                  : confessor.text.trim(),
              medicalNotes: medicalNotes.text.trim().isEmpty
                  ? null
                  : medicalNotes.text.trim(),
              financialStatus: financialStatus,
              addressBuilding: addressBuilding.text.trim().isEmpty
                  ? null
                  : addressBuilding.text.trim(),
              addressStreet: addressStreet.text.trim().isEmpty
                  ? null
                  : addressStreet.text.trim(),
              addressFloor: addressFloor.text.trim().isEmpty
                  ? null
                  : addressFloor.text.trim(),
              addressApartment: addressApartment.text.trim().isEmpty
                  ? null
                  : addressApartment.text.trim(),
              studyYear: widget.sensitiveData?.studyYear,
            );

            Navigator.pop(
              context,
              StudentEditResult(
                name: name.text.trim(),
                birthDate: birthDate,
                phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
                school: school.text.trim().isEmpty ? null : school.text.trim(),
                grade: widget.student.grade,
                isDeacon: isDeacon,
                enrollmentAt: widget.student.enrollmentAt,
                photoPath: widget.student.photoPath,
                notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                sensitiveData: updatedSensitive,
              ),
            );
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
