import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/config/config_provider.dart';
import '../../../core/network/network_error_formatter.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../service/domain/entities/service_class.dart';
import '../../service/domain/entities/stage.dart';
import '../../service/presentation/service_providers.dart';
import '../domain/entities/sensitive_student_data.dart';
import 'student_details_page.dart';
import 'student_providers.dart';

class AddStudentPage extends ConsumerStatefulWidget {
  const AddStudentPage({
    super.key,
    required this.serviceId,
    this.initialStageId,
    this.initialClassId,
    this.className,
  });

  final String serviceId;
  final String? initialStageId;
  final String? initialClassId;
  final String? className;

  @override
  ConsumerState<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends ConsumerState<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();

  // Section 1: بيانات الطالب الأساسية
  final _name = TextEditingController();
  DateTime? _birthDate;
  final _studentPhone = TextEditingController();
  final _school = TextEditingController();
  bool _isDeacon = false;

  // Section 2: العنوان
  final _addressNumber = TextEditingController(); // رقم
  final _street = TextEditingController(); // شارع
  final _floor = TextEditingController(); // دور
  final _apartment = TextEditingController(); // شقة

  // Section 3: بيانات الأسرة
  final _fatherJob = TextEditingController(); // وظيفة الأب
  final _fatherPhone = TextEditingController(); // تليفون الأب
  final _motherName = TextEditingController(); // اسم الأم
  final _motherJob = TextEditingController(); // وظيفة الأم
  final _motherPhone = TextEditingController(); // تليفون الأم
  final _familySize = TextEditingController(); // عدد أفراد الأسرة
  final _birthOrder = TextEditingController(); // ترتيب الطالب بين إخوته

  // Section 4: بيانات الدراسة والخدمة
  String? _selectedStudyYear;
  String? _selectedStageId;
  String? _selectedClassId;
  final _confessor = TextEditingController(); // أب الاعتراف
  List<Stage> _stages = [];
  Map<String, List<ServiceClass>> _stageClasses = {};
  List<String> _studyYears = [];
  bool _loadingStructure = true;
  bool _isClassLocked = false;
  String? _lockedClassLabel;

  // Section 5: البيانات الصحية والحساسة
  final _medicalNotes = TextEditingController(); // ملاحظات صحية أو حساسية
  String? _financialStatus; // الحالة المادية للأسرة

  // Section 6: ملاحظات
  final _generalNotes = TextEditingController(); // ملاحظات عامة

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadStructure();
  }

  @override
  void dispose() {
    _name.dispose();
    _studentPhone.dispose();
    _school.dispose();
    _addressNumber.dispose();
    _street.dispose();
    _floor.dispose();
    _apartment.dispose();
    _fatherJob.dispose();
    _fatherPhone.dispose();
    _motherName.dispose();
    _motherJob.dispose();
    _motherPhone.dispose();
    _familySize.dispose();
    _birthOrder.dispose();
    _confessor.dispose();
    _medicalNotes.dispose();
    _generalNotes.dispose();
    super.dispose();
  }

  Future<void> _loadStructure() async {
    setState(() => _loadingStructure = true);
    final serviceRepo = ref.read(serviceRepositoryProvider);

    try {
      await serviceRepo.refreshStages(widget.serviceId);
      await serviceRepo.refreshReportingPeriods(widget.serviceId);
    } catch (_) {}

    final stages = await serviceRepo.getStages(widget.serviceId);
    final Map<String, List<ServiceClass>> stageClasses = {};
    for (final s in stages) {
      try {
        await serviceRepo.refreshClasses(s.id);
      } catch (_) {}
      stageClasses[s.id] = await serviceRepo.getClasses(s.id);
    }

    final periods = await serviceRepo.getReportingPeriods(widget.serviceId);
    final List<String> years = periods.map((p) => p.name).toList();
    if (years.isEmpty) {
      final now = DateTime.now();
      years.add('سنة الخدمة ${now.year} - ${now.year + 1}');
    }

    final profile = await ref.read(currentServantProfileProvider.future);
    final isScoped =
        (profile?.role == 'class_servant' || profile?.role == 'class_leader') &&
        profile?.classId != null;

    String? preselectedStageId = widget.initialStageId;
    String? preselectedClassId =
        widget.initialClassId ?? (isScoped ? profile?.classId : null);
    String? lockedLabel = widget.className;

    if (preselectedClassId != null) {
      for (final s in stages) {
        final classes = stageClasses[s.id] ?? [];
        for (final c in classes) {
          if (c.id == preselectedClassId) {
            preselectedStageId = s.id;
            lockedLabel ??= '${s.name} • ${c.name}';
            break;
          }
        }
      }
    } else if (stages.isNotEmpty) {
      preselectedStageId = stages.first.id;
      final firstClasses = stageClasses[preselectedStageId] ?? [];
      if (firstClasses.isNotEmpty) {
        preselectedClassId = firstClasses.first.id;
      }
    }

    if (mounted) {
      setState(() {
        _stages = stages;
        _stageClasses = stageClasses;
        _studyYears = years;
        _selectedStudyYear = years.first;
        _selectedStageId = preselectedStageId;
        _selectedClassId = preselectedClassId;
        _isClassLocked = isScoped;
        _lockedClassLabel = lockedLabel;
        _loadingStructure = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تصحيح الحقول المطلوبة قبل المتابعة.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    // Family size & birth order validation
    final famSize = int.tryParse(_familySize.text.trim());
    final bOrder = int.tryParse(_birthOrder.text.trim());
    final familyError = SensitiveStudentData.validateFamilyAndFinance(
      familySize: famSize,
      birthOrder: bOrder,
      financialStatus: _financialStatus,
    );

    if (familyError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(familyError),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد الفصل الدراسي للتلميذ.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final sensitiveData = <String, dynamic>{
        'father_job': _fatherJob.text.trim(),
        'father_phone': _fatherPhone.text.trim(),
        'mother_name': _motherName.text.trim(),
        'mother_job': _motherJob.text.trim(),
        'mother_phone': _motherPhone.text.trim(),
        'family_size': famSize,
        'birth_order': bOrder,
        'confessor': _confessor.text.trim(),
        'medical_notes': _medicalNotes.text.trim(),
        'financial_status': _financialStatus,
        'address_building': _addressNumber.text.trim(),
        'address_street': _street.text.trim(),
        'address_floor': _floor.text.trim(),
        'address_apartment': _apartment.text.trim(),
        'study_year': _selectedStudyYear,
      };

      final created = await ref
          .read(studentRegistrationProvider)
          .registerPending(
            serviceId: widget.serviceId,
            proposedClassId: _selectedClassId!,
            name: _name.text.trim(),
            birthDate: _birthDate,
            phone: _studentPhone.text.trim().isEmpty
                ? null
                : _studentPhone.text.trim(),
            school: _school.text.trim().isEmpty ? null : _school.text.trim(),
            isDeacon: _isDeacon,
            notes: _generalNotes.text.trim().isEmpty
                ? null
                : _generalNotes.text.trim(),
            sensitiveData: sensitiveData,
          );

      if (!mounted) return;

      final isOfflineSync = ref.read(offlineSyncEnabledProvider);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isOfflineSync
                ? 'تم تسجيل التلميذ بنجاح وحفظه محليًا للمزامنة والاعتماد.'
                : 'تم تسجيل التلميذ بنجاح وبانتظار الاعتماد.',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StudentDetailsPage(student: created)),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تسجيل التلميذ: ${NetworkErrorFormatter.format(error)}'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentStageClasses = _selectedStageId != null
        ? (_stageClasses[_selectedStageId] ?? [])
        : <ServiceClass>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة طالب جديد',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: AmbientBackground(
        intensity: 0.4,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: _loadingStructure
                ? const LoadingView(message: 'جاري تحميل الهيكل والفصول...')
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      children: [
                        // Header Intro Card
                        GlassContainer(
                          padding: const EdgeInsets.all(18),
                          borderRadius: 20,
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00236F,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_add_rounded,
                                  color: Color(0xFF00236F),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'استمارة تسجيل تلميذ متكاملة',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'أسرة تلاميذ المسيح — خدمة 5 و6 ابتدائي بنين — كنيسة السيدة العذراء بعياد بك',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // Section 1: بيانات الطالب الأساسية
                        // ==========================================
                        _buildSectionHeader(
                          '1. بيانات الطالب الأساسية',
                          Icons.person_outline_rounded,
                        ),
                        SolidCard(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              TextFormField(
                                key: const Key('add_student_name'),
                                controller: _name,
                                decoration: const InputDecoration(
                                  labelText: 'الاسم الكامل للطالب *',
                                  hintText: 'مثال: كيرلس أمير عزيز خليل',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'الاسم بالكامل إلزامي';
                                  }
                                  final words = value.trim().split(
                                    RegExp(r'\s+'),
                                  );
                                  if (words.length < 2) {
                                    return 'يجب إدخال اسم ثنائي أو ثلاثي على الأقل';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 500;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    children: [
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: _datePickerTile(
                                          title: 'تاريخ الميلاد',
                                          value: _birthDate,
                                          icon: Icons.cake_outlined,
                                          onPick: () async {
                                            final now = DateTime.now();
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate:
                                                  _birthDate ??
                                                  DateTime(now.year - 11),
                                              firstDate: DateTime(
                                                now.year - 30,
                                              ),
                                              lastDate: now,
                                              helpText:
                                                  'اختر تاريخ ميلاد الطالب',
                                            );
                                            if (picked != null) {
                                              setState(
                                                () => _birthDate = picked,
                                              );
                                            }
                                          },
                                          onClear: () =>
                                              setState(() => _birthDate = null),
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 12),
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _studentPhone,
                                          decoration: const InputDecoration(
                                            labelText: 'تليفون الطالب',
                                            hintText: '01xxxxxxxxx',
                                            prefixIcon: Icon(
                                              Icons.phone_iphone_outlined,
                                            ),
                                          ),
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 500;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    children: [
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _school,
                                          decoration: const InputDecoration(
                                            labelText: 'المدرسة',
                                            prefixIcon: Icon(
                                              Icons.school_outlined,
                                            ),
                                          ),
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 12),
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF334155)
                                                  : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.church_outlined,
                                                color: Color(0xFF00236F),
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Text(
                                                  'شماس',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              Switch(
                                                key: const Key(
                                                  'add_student_is_deacon',
                                                ),
                                                value: _isDeacon,
                                                onChanged: (val) => setState(
                                                  () => _isDeacon = val,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // Section 2: العنوان
                        // ==========================================
                        _buildSectionHeader(
                          '2. العنوان',
                          Icons.location_on_outlined,
                        ),
                        SolidCard(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 500;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    children: [
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _addressNumber,
                                          decoration: const InputDecoration(
                                            labelText: 'رقم (العقار)',
                                            hintText: 'مثال: 14',
                                            prefixIcon: Icon(
                                              Icons.numbers_outlined,
                                            ),
                                          ),
                                          keyboardType: TextInputType.text,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 14),
                                      Expanded(
                                        flex: isWide ? 2 : 0,
                                        child: TextFormField(
                                          controller: _street,
                                          decoration: const InputDecoration(
                                            labelText: 'شارع',
                                            hintText: 'مثال: شارع عياد بك',
                                            prefixIcon: Icon(
                                              Icons.add_road_outlined,
                                            ),
                                          ),
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 500;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    children: [
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _floor,
                                          decoration: const InputDecoration(
                                            labelText: 'دور',
                                            hintText: 'مثال: 3',
                                            prefixIcon: Icon(
                                              Icons.stairs_outlined,
                                            ),
                                          ),
                                          keyboardType: TextInputType.text,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 14),
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _apartment,
                                          decoration: const InputDecoration(
                                            labelText: 'شقة',
                                            hintText: 'مثال: 6',
                                            prefixIcon: Icon(
                                              Icons.door_front_door_outlined,
                                            ),
                                          ),
                                          keyboardType: TextInputType.text,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // Section 3: بيانات الأسرة
                        // ==========================================
                        _buildSectionHeader(
                          '3. بيانات الأسرة',
                          Icons.family_restroom_outlined,
                        ),
                        SolidCard(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 500;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    children: [
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _fatherJob,
                                          decoration: const InputDecoration(
                                            labelText: 'وظيفة الأب',
                                            hintText: 'مثال: محاسب',
                                            prefixIcon: Icon(
                                              Icons.work_outline_rounded,
                                            ),
                                          ),
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 14),
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _fatherPhone,
                                          decoration: const InputDecoration(
                                            labelText: 'تليفون الأب',
                                            hintText: '01xxxxxxxxx',
                                            prefixIcon: Icon(
                                              Icons.phone_outlined,
                                            ),
                                          ),
                                          keyboardType: TextInputType.phone,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 500;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    children: [
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _motherName,
                                          decoration: const InputDecoration(
                                            labelText: 'اسم الأم',
                                            hintText: 'مثال: مريم نبيل',
                                            prefixIcon: Icon(
                                              Icons.face_3_outlined,
                                            ),
                                          ),
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 14),
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _motherJob,
                                          decoration: const InputDecoration(
                                            labelText: 'وظيفة الأم',
                                            hintText: 'مثال: ربة منزل / معلمة',
                                            prefixIcon: Icon(
                                              Icons.work_history_outlined,
                                            ),
                                          ),
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _motherPhone,
                                decoration: const InputDecoration(
                                  labelText: 'تليفون الأم',
                                  hintText: '01xxxxxxxxx',
                                  prefixIcon: Icon(
                                    Icons.contact_phone_outlined,
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth > 500;
                                  return Flex(
                                    direction: isWide
                                        ? Axis.horizontal
                                        : Axis.vertical,
                                    children: [
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _familySize,
                                          decoration: const InputDecoration(
                                            labelText: 'عدد أفراد الأسرة',
                                            hintText: 'مثال: 5',
                                            prefixIcon: Icon(
                                              Icons.groups_outlined,
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          validator: (val) {
                                            if (val != null &&
                                                val.trim().isNotEmpty) {
                                              final n = int.tryParse(
                                                val.trim(),
                                              );
                                              if (n == null || n <= 0) {
                                                return 'يجب أن يكون رقمًا موجبًا';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      if (isWide)
                                        const SizedBox(width: 16)
                                      else
                                        const SizedBox(height: 14),
                                      Expanded(
                                        flex: isWide ? 1 : 0,
                                        child: TextFormField(
                                          controller: _birthOrder,
                                          decoration: const InputDecoration(
                                            labelText: 'ترتيب الطالب بين إخوته',
                                            hintText: 'مثال: 2',
                                            prefixIcon: Icon(
                                              Icons
                                                  .format_list_numbered_rounded,
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                          validator: (val) {
                                            if (val != null &&
                                                val.trim().isNotEmpty) {
                                              final n = int.tryParse(
                                                val.trim(),
                                              );
                                              if (n == null || n <= 0) {
                                                return 'يجب أن يكون رقمًا موجبًا';
                                              }
                                              final fam = int.tryParse(
                                                _familySize.text.trim(),
                                              );
                                              if (fam != null && n > fam) {
                                                return 'لا يتجاوز عدد أفراد الأسرة ($fam)';
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // Section 4: بيانات الدراسة والخدمة
                        // ==========================================
                        _buildSectionHeader(
                          '4. بيانات الدراسة والخدمة',
                          Icons.account_tree_outlined,
                        ),
                        SolidCard(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isClassLocked)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF4FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFDCE9FF),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.lock_outline_rounded,
                                        color: Color(0xFF00236F),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'التسكين محدد بفصلك المسند: ${_lockedClassLabel ?? ''}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF00236F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                DropdownButtonFormField<String>(
                                  key: const Key('add_student_year_dropdown'),
                                  initialValue: _selectedStudyYear,
                                  decoration: const InputDecoration(
                                    labelText: 'السنة الدراسية *',
                                    prefixIcon: Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                  ),
                                  items: [
                                    for (final y in _studyYears)
                                      DropdownMenuItem(
                                        value: y,
                                        child: Text(y),
                                      ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _selectedStudyYear = val),
                                ),
                                const SizedBox(height: 16),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 500;
                                    return Flex(
                                      direction: isWide
                                          ? Axis.horizontal
                                          : Axis.vertical,
                                      children: [
                                        Expanded(
                                          flex: isWide ? 1 : 0,
                                          child: DropdownButtonFormField<String>(
                                            key: const Key(
                                              'add_student_stage_dropdown',
                                            ),
                                            initialValue: _selectedStageId,
                                            decoration: const InputDecoration(
                                              labelText: 'المرحلة *',
                                              prefixIcon: Icon(
                                                Icons.layers_outlined,
                                              ),
                                            ),
                                            items: [
                                              for (final s in _stages)
                                                DropdownMenuItem(
                                                  value: s.id,
                                                  child: Text(s.name),
                                                ),
                                            ],
                                            onChanged: (newStageId) {
                                              if (newStageId == null) return;
                                              setState(() {
                                                _selectedStageId = newStageId;
                                                final classes =
                                                    _stageClasses[newStageId] ??
                                                    [];
                                                _selectedClassId =
                                                    classes.isNotEmpty
                                                    ? classes.first.id
                                                    : null;
                                              });
                                            },
                                          ),
                                        ),
                                        if (isWide)
                                          const SizedBox(width: 16)
                                        else
                                          const SizedBox(height: 14),
                                        Expanded(
                                          flex: isWide ? 1 : 0,
                                          child:
                                              DropdownButtonFormField<String>(
                                                key: const Key(
                                                  'add_student_class_dropdown',
                                                ),
                                                initialValue: _selectedClassId,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'الفصل *',
                                                      prefixIcon: Icon(
                                                        Icons.class_outlined,
                                                      ),
                                                    ),
                                                items: [
                                                  for (final c
                                                      in currentStageClasses)
                                                    DropdownMenuItem(
                                                      value: c.id,
                                                      child: Text(c.name),
                                                    ),
                                                ],
                                                validator: (val) => val == null
                                                    ? 'اختر الفصل'
                                                    : null,
                                                onChanged: (newClassId) =>
                                                    setState(
                                                      () => _selectedClassId =
                                                          newClassId,
                                                    ),
                                              ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confessor,
                                decoration: const InputDecoration(
                                  labelText: 'أب الاعتراف',
                                  hintText: 'مثال: أبونا بيشوي',
                                  prefixIcon: Icon(Icons.church_outlined),
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // Section 5: البيانات الصحية والحساسة
                        // ==========================================
                        _buildSectionHeader(
                          '5. البيانات الصحية والحساسة',
                          Icons.health_and_safety_outlined,
                        ),
                        SolidCard(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _medicalNotes,
                                decoration: const InputDecoration(
                                  labelText: 'ملاحظات صحية أو حساسية',
                                  hintText:
                                      'حساسية طعام، أدوية مستمرة، أمراض مزمنة...',
                                  prefixIcon: Icon(
                                    Icons.medical_services_outlined,
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                key: const Key('add_student_financial_status'),
                                initialValue: _financialStatus,
                                decoration: const InputDecoration(
                                  labelText: 'الحالة المادية للأسرة',
                                  prefixIcon: Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text('غير محدد'),
                                  ),
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
                                onChanged: (val) =>
                                    setState(() => _financialStatus = val),
                              ),
                            ],
                          ),
                        ),

                        // ==========================================
                        // Section 6: ملاحظات
                        // ==========================================
                        _buildSectionHeader('6. ملاحظات', Icons.notes_rounded),
                        SolidCard(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 24),
                          child: TextFormField(
                            controller: _generalNotes,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات عامة',
                              hintText: 'أي ملاحظات إضافية عن التلميذ...',
                              prefixIcon: Icon(Icons.comment_outlined),
                            ),
                            minLines: 2,
                            maxLines: 4,
                          ),
                        ),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                ),
                                child: const Text('إلغاء'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                key: const Key('add_student_submit'),
                                onPressed: _saving ? null : _submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  backgroundColor: const Color(0xFF00236F),
                                ),
                                icon: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline_rounded,
                                      ),
                                label: Text(
                                  _saving
                                      ? 'جاري الحفظ والترميز...'
                                      : 'تسجيل التلميذ في الخدمة',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00236F), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF00236F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePickerTile({
    required String title,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final hasVal = value != null;
    final text = hasVal
        ? DateFormat('yyyy-MM-dd').format(value)
        : 'انقر لتحديد التاريخ';

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: Icon(icon),
          suffixIcon: hasVal
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'مسح',
                  onPressed: onClear,
                )
              : const Icon(Icons.calendar_month_outlined, size: 20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: hasVal ? null : Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
