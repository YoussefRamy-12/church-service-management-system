import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/design/app_colors.dart';
import '../../../app/design/app_radii.dart';
import '../../../app/design/app_spacing.dart';
import '../../students/domain/entities/student.dart';

/// Full-screen mobile-optimized QR Scanner adhering to the Warm Navy design system.
///
/// Ergonomics:
/// - Full-screen camera canvas with safe viewfinder reticles
/// - Immediate feedback with differentiated haptics (success / already present / not found)
/// - Clear result panel for each scanning state
/// - One-handed manual search fallback
/// - Zero hardcoded arbitrary colors; uses design tokens
class QrScanPage extends StatefulWidget {
  const QrScanPage({
    super.key,
    required this.students,
    required this.presentStudentIds,
    required this.onCheckIn,
    @visibleForTesting this.initialCameraError,
    @visibleForTesting this.initialScannedStudent,
  });

  final List<Student> students;
  final Set<String> presentStudentIds;
  final Future<bool> Function(Student) onCheckIn;
  final String? initialCameraError;
  final Student? initialScannedStudent;

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  late final AnimationController _laserAnimController;
  late final Animation<double> _laserPosition;

  Student? _scannedStudent;
  Student? _checkedInStudent;
  late final Set<String> _presentStudentIds;
  int _sessionCheckInCount = 0;
  bool _isSubmittingCheckIn = false;
  String? _checkInError;
  bool _unknownCode = false;
  bool _handlingResult = false;
  bool _closing = false;
  bool _allowPop = false;
  bool _controllerDisposed = false;
  String? _cameraError;
  Future<void>? _startOperation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraError = widget.initialCameraError;
    _scannedStudent = widget.initialScannedStudent;
    _presentStudentIds = {...widget.presentStudentIds};

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserPosition = CurvedAnimation(
      parent: _laserAnimController,
      curve: Curves.easeInOutSine,
    );

    if (_cameraError == null && _scannedStudent == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_closing || _controllerDisposed || _scannedStudent != null) return;
    if (state == AppLifecycleState.resumed) {
      _startCamera();
    } else {
      _pauseCamera();
    }
  }

  Future<void> _startCamera() {
    if (!mounted ||
        _closing ||
        _controllerDisposed ||
        _scannedStudent != null) {
      return Future<void>.value();
    }
    final inFlight = _startOperation;
    if (inFlight != null) return inFlight;

    final operation = _startCameraInternal();
    _startOperation = operation;
    return operation.whenComplete(() {
      if (identical(_startOperation, operation)) _startOperation = null;
    });
  }

  Future<void> _startCameraInternal() async {
    if (_closing || _controllerDisposed || !mounted) return;
    try {
      await _controller.start();
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      if (_closing ||
          _controllerDisposed ||
          !mounted ||
          _scannedStudent != null ||
          (lifecycleState != null &&
              lifecycleState != AppLifecycleState.resumed)) {
        await _stopCamera();
        return;
      }
      if (mounted) setState(() => _cameraError = null);
    } catch (error) {
      debugPrint('Presentation operation failed: $error');
      if (mounted && !_closing) {
        setState(() => _cameraError = _localizeCameraError(error));
      }
    }
  }

  String _localizeCameraError(Object error) {
    final raw = error.toString().toLowerCase();
    if (error is MobileScannerException &&
            error.errorCode == MobileScannerErrorCode.permissionDenied ||
        raw.contains('permission')) {
      return 'يلزم السماح بالوصول إلى الكاميرا لمسح رمز الحضور.';
    }
    if (error is MobileScannerException &&
            error.errorCode == MobileScannerErrorCode.unsupported ||
        raw.contains('unsupported') ||
        raw.contains('not available')) {
      return 'الكاميرا غير مدعومة على هذا الجهاز. يمكنك استخدام الإدخال اليدوي.';
    }
    return 'تعذر تشغيل الكاميرا حاليًا. يمكنك المحاولة مرة أخرى أو استخدام الإدخال اليدوي.';
  }

  Future<void> _requestCameraPermissionOrRetry() async {
    try {
      final settingsUri = Uri.parse('app-settings:');
      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri);
        return;
      }
    } catch (_) {}
    await _startCamera();
  }

  Future<void> _pauseCamera() async {
    final inFlight = _startOperation;
    if (inFlight != null) {
      try {
        await inFlight.timeout(const Duration(milliseconds: 150));
      } catch (_) {}
    }
    await _stopCamera();
  }

  Future<void> _stopCamera() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingResult || _closing || _controllerDisposed) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (value.isEmpty) return;

    _handlingResult = true;
    _laserAnimController.stop();
    await _stopCamera();
    if (!mounted || _closing) return;

    Student? student;
    for (final candidate in widget.students) {
      if (candidate.id == value) {
        student = candidate;
        break;
      }
    }

    if (student != null) {
      final alreadyPresent = _presentStudentIds.contains(student.id);
      if (alreadyPresent) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.mediumImpact();
      }
    } else {
      HapticFeedback.heavyImpact();
    }

    setState(() {
      _scannedStudent = student;
      _unknownCode = student == null;
    });
  }

  Future<void> _resumeScanning() async {
    if (_closing || _controllerDisposed) return;
    _laserAnimController.repeat(reverse: true);
    setState(() {
      _scannedStudent = null;
      _unknownCode = false;
      _handlingResult = false;
      _cameraError = null;
      _checkedInStudent = null;
      _checkInError = null;
      _isSubmittingCheckIn = false;
    });
    await _startCamera();
  }

  Future<void> _confirmCheckIn(Student student) async {
    if (_isSubmittingCheckIn || _presentStudentIds.contains(student.id)) {
      return;
    }
    setState(() {
      _isSubmittingCheckIn = true;
      _checkInError = null;
    });

    var succeeded = false;
    try {
      succeeded = await widget.onCheckIn(student);
    } catch (error) {
      debugPrint('QR check-in callback failed: $error');
    }

    if (!mounted || _closing) return;
    if (!succeeded) {
      setState(() {
        _isSubmittingCheckIn = false;
        _checkInError = 'تعذر تسجيل الحضور. حاول مرة أخرى.';
      });
      return;
    }

    setState(() {
      _isSubmittingCheckIn = false;
      _presentStudentIds.add(student.id);
      _checkedInStudent = student;
      _sessionCheckInCount++;
    });
    HapticFeedback.lightImpact();

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _closing || _checkedInStudent != student) return;
    await _resumeScanning();
  }

  Future<void> _closeScanner() async {
    if (_closing && _allowPop) return;
    _closing = true;
    if (mounted) setState(() {});

    _laserAnimController.stop();

    final inFlight = _startOperation;
    if (inFlight != null) {
      try {
        await inFlight;
      } catch (_) {}
    }

    try {
      await _controller.stop();
    } catch (_) {}

    if (!_controllerDisposed) {
      _controllerDisposed = true;
      try {
        await _controller.dispose();
      } catch (_) {}
    }

    if (mounted) {
      _allowPop = true;
      Navigator.of(context).pop();
    }
  }

  void _openManualSearch() async {
    _laserAnimController.stop();
    await _pauseCamera();
    if (!mounted || _closing) return;

    final selected = await showModalBottomSheet<Student>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualStudentSearchSheet(
        students: widget.students,
        presentIds: _presentStudentIds,
      ),
    );

    if (!mounted || _closing) return;

    if (selected != null) {
      final alreadyPresent = _presentStudentIds.contains(selected.id);
      if (alreadyPresent) {
        HapticFeedback.selectionClick();
      } else {
        HapticFeedback.mediumImpact();
      }
      setState(() {
        _scannedStudent = selected;
        _unknownCode = false;
        _handlingResult = true;
      });
    } else {
      _laserAnimController.repeat(reverse: true);
      await _startCamera();
    }
  }

  @override
  void dispose() {
    _closing = true;
    _laserAnimController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (!_controllerDisposed) {
      _controllerDisposed = true;
      _controller.stop();
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final student = _scannedStudent;
    final alreadyPresent =
        student != null && _presentStudentIds.contains(student.id);

    return PopScope<void>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeScanner();
      },
      child: Scaffold(
        backgroundColor: AppDesignColors.darkCanvas,
        body: Stack(
          children: [
            // 1. Full-screen Camera Canvas
            Positioned.fill(
              child: !_closing && !_controllerDisposed && _cameraError == null
                  ? Directionality(
                      textDirection: TextDirection.ltr,
                      child: MobileScanner(
                        controller: _controller,
                        onDetect: _onDetect,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error) => Container(
                          color: AppDesignColors.darkCanvas,
                          child: Center(
                            child: Icon(
                              Icons.videocam_off_rounded,
                              color: colors.conflict.foreground
                                  .withValues(alpha: 0.6),
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppDesignColors.darkCanvas,
                      child: Center(
                        child: Icon(
                          _cameraError != null
                              ? Icons.videocam_off_rounded
                              : Icons.qr_code_scanner_rounded,
                          color: _cameraError != null
                              ? colors.conflict.foreground.withValues(alpha: 0.6)
                              : AppDesignColors.darkBorder,
                          size: 64,
                        ),
                      ),
                    ),
            ),

            // 2. Viewfinder Reticles & Overlay
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildViewfinder(
                                size: 250.0,
                                student: student,
                                colors: colors,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildInstructionBadge(
                                student: student,
                                colors: colors,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildBottomSection(
                      student: student,
                      alreadyPresent: alreadyPresent,
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppDesignColors.darkSurface,
        border: Border(
          bottom: BorderSide(color: AppDesignColors.darkBorderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Large Close button (minimum 44x44 tap target)
          TextButton.icon(
            key: const Key('qr_finish'),
            onPressed: _closing ? null : _closeScanner,
            icon: const Icon(Icons.close_rounded),
            label: const Text('إنهاء'),
            style: TextButton.styleFrom(
              foregroundColor: AppDesignColors.darkInk,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Title & active context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تسجيل الحضور بالرمز',
                  style: TextStyle(
                    color: AppDesignColors.darkInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'المسجلين: ${_presentStudentIds.length} من ${widget.students.length}',
                  style: const TextStyle(
                    color: AppDesignColors.darkMutedInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Flashlight/Torch Toggle
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final isTorchOn = state.torchState == TorchState.on;
              final hasTorch = state.torchState != TorchState.unavailable;
              if (!hasTorch) return const SizedBox.shrink();

              return IconButton(
                onPressed: _closing || _controllerDisposed
                    ? null
                    : () => _controller.toggleTorch(),
                icon: Icon(
                  isTorchOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: isTorchOn ? AppDesignColors.darkGold : AppDesignColors.darkMutedInk,
                ),
                tooltip: isTorchOn ? 'إطفاء الكشاف' : 'تشغيل الكشاف',
                style: IconButton.styleFrom(
                  backgroundColor: AppDesignColors.darkSurfaceSubtle,
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),

          // Camera Direction Switch (Front/Back)
          IconButton(
            onPressed: _closing || _controllerDisposed
                ? null
                : () => _controller.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios_rounded, color: AppDesignColors.darkMutedInk),
            tooltip: 'تبديل الكاميرا',
            style: IconButton.styleFrom(
              backgroundColor: AppDesignColors.darkSurfaceSubtle,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.all(AppSpacing.xs),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder({
    required double size,
    required Student? student,
    required AppColors colors,
  }) {
    final hasError = _cameraError != null;
    final isSuccess = student != null;

    final borderColor = isSuccess
        ? colors.present.foreground
        : hasError
            ? colors.conflict.foreground
            : AppDesignColors.primaryContainer;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Reticle boundary container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),

          // Animated Laser Sweep Line (Only active while scanning)
          if (!isSuccess && !hasError && !_closing)
            AnimatedBuilder(
              animation: _laserPosition,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(0, (_laserPosition.value * 2.0) - 1.0),
                  child: Container(
                    height: 2.5,
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppDesignColors.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: AppDesignColors.primaryContainer.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Precision Corner Reticles
          CustomPaint(
            painter: _ScannerReticlePainter(
              color: borderColor,
              borderRadius: AppRadii.card,
              strokeWidth: 3.5,
              reticleLength: 28.0,
            ),
          ),

          // Success Overlay Animation
          if (isSuccess)
            Container(
              decoration: BoxDecoration(
                color: colors.present.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: colors.present.foreground, width: 2),
              ),
              child: Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: colors.present.foreground,
                  size: 68,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionBadge({
    required Student? student,
    required AppColors colors,
  }) {
    if (_cameraError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.conflict.background,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: colors.conflict.foreground, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: colors.conflict.foreground, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'تعذر قراءة الكاميرا — استخدم البحث اليدوي أدناه',
                style: TextStyle(color: colors.conflict.foreground, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (student != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: colors.present.background,
          borderRadius: BorderRadius.circular(AppRadii.chip),
          border: Border.all(color: colors.present.foreground, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: colors.present.foreground, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'تم التعرف على الطالب بنجاح',
                style: TextStyle(
                  color: colors.present.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppDesignColors.darkSurfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: AppDesignColors.darkBorder, width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.crop_free_rounded, color: AppDesignColors.darkMutedInk, size: 16),
          SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'ضع رمز الاستجابة السريعة (QR) داخل الإطار',
              style: TextStyle(color: AppDesignColors.darkInk, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection({
    required Student? student,
    required bool alreadyPresent,
    required AppColors colors,
  }) {
    if (_checkedInStudent != null) {
      return _CheckInSuccessPanel(
        student: _checkedInStudent!,
        sessionCount: _sessionCheckInCount,
      );
    }

    if (_cameraError != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppDesignColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.bottomSheet)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _cameraError!,
              style: const TextStyle(color: AppDesignColors.darkMutedInk, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('qr_allow_camera_button'),
                    onPressed: _requestCameraPermissionOrRetry,
                    icon: const Icon(Icons.videocam_rounded),
                    label: const Text('السماح بالكاميرا'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppDesignColors.darkInk,
                      side: const BorderSide(color: AppDesignColors.darkBorder),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('qr_manual_entry_button'),
                    onPressed: _openManualSearch,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('إدخال يدوي'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppDesignColors.darkPrimary,
                      foregroundColor: AppDesignColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_unknownCode) {
      return Container(
        key: const Key('qr_unknown_panel'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppDesignColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.bottomSheet)),
          border: Border(top: BorderSide(color: AppDesignColors.darkBorderSubtle)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded, color: colors.warning.foreground, size: 36),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'الرمز غير مسجل في هذه القائمة',
              style: TextStyle(
                color: AppDesignColors.darkInk,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'تأكد من أن الكود يخص تلميذًا في خدمة هذا الاجتماع.',
              style: TextStyle(color: AppDesignColors.darkMutedInk, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resumeScanning,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppDesignColors.darkInk,
                      side: const BorderSide(color: AppDesignColors.darkBorder),
                    ),
                    child: const Text('مسح رمز آخر'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openManualSearch,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('بحث بالاسم'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (student != null) {
      return _StudentReviewPanel(
        student: student,
        alreadyPresent: alreadyPresent,
        colors: colors,
        onCancel: _resumeScanning,
        onConfirm: alreadyPresent ? null : () => _confirmCheckIn(student),
        isSubmitting: _isSubmittingCheckIn,
        errorMessage: _checkInError,
      );
    }

    // Default Bottom Actions while scanning
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppDesignColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppDesignColors.darkBorderSubtle, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: OutlinedButton.icon(
              key: const Key('qr_manual_search_btn'),
              onPressed: _openManualSearch,
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text('بحث يدوي عن تلميذ بالاسم'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppDesignColors.darkInk,
                side: const BorderSide(color: AppDesignColors.darkBorder),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Precision 4-Corner Reticle Painter for the Viewfinder
class _ScannerReticlePainter extends CustomPainter {
  const _ScannerReticlePainter({
    required this.color,
    required this.borderRadius,
    required this.strokeWidth,
    required this.reticleLength,
  });

  final Color color;
  final double borderRadius;
  final double strokeWidth;
  final double reticleLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final r = borderRadius;
    final w = size.width;
    final h = size.height;
    final l = reticleLength;

    // Top-Left
    final pathTL = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(l, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, l);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: Radius.circular(r))
      ..lineTo(l, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r))
      ..lineTo(w, h - l);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerReticlePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.reticleLength != reticleLength;
}

class _CheckInSuccessPanel extends StatelessWidget {
  const _CheckInSuccessPanel({
    required this.student,
    required this.sessionCount,
  });

  final Student student;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final present = AppColors.of(context).present;
    return Container(
      key: const ValueKey('qr_checkin_success_panel'),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppDesignColors.darkSurface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.bottomSheet),
        ),
        border: Border(
          top: BorderSide(color: AppDesignColors.primaryContainer, width: 1.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: present.foreground, size: 30),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'تم تسجيل ${student.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppDesignColors.darkInk,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'تم تسجيل $sessionCount',
            style: TextStyle(
              color: present.foreground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Student Review Card in QR Scan
class _StudentReviewPanel extends StatelessWidget {
  const _StudentReviewPanel({
    required this.student,
    required this.alreadyPresent,
    required this.colors,
    required this.onCancel,
    required this.onConfirm,
    required this.isSubmitting,
    required this.errorMessage,
  });

  final Student student;
  final bool alreadyPresent;
  final AppColors colors;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final bool isSubmitting;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(alreadyPresent ? 'qr_already_present_panel' : 'qr_success_panel'),
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 330),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppDesignColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.bottomSheet)),
        border: Border(
          top: BorderSide(color: AppDesignColors.primaryContainer, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Profile Row
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppDesignColors.primaryContainer,
                  child: Text(
                    student.name.isEmpty ? '؟' : student.name.characters.first,
                    style: const TextStyle(
                      color: AppDesignColors.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          color: AppDesignColors.darkInk,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (student.isDeacon) ...[
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.excused.background,
                            borderRadius: BorderRadius.circular(AppRadii.chip),
                          ),
                          child: Text(
                            'شماس',
                            style: TextStyle(
                              color: colors.excused.foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  alreadyPresent
                      ? Icons.check_circle_rounded
                      : Icons.how_to_reg_rounded,
                  color: alreadyPresent
                      ? colors.present.foreground
                      : AppDesignColors.primaryContainer,
                  size: 30,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            // Metadata Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (student.grade?.isNotEmpty == true)
                  _ReviewChip(
                    icon: Icons.menu_book_outlined,
                    label: student.grade!,
                  ),
                if (student.school?.isNotEmpty == true)
                  _ReviewChip(
                    icon: Icons.school_outlined,
                    label: student.school!,
                  ),
                if (student.phone?.isNotEmpty == true)
                  _ReviewChip(
                    icon: Icons.phone_outlined,
                    label: student.phone!,
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            if (errorMessage != null) ...[
              Text(
                errorMessage!,
                style: TextStyle(
                  color: colors.absent.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Actions & Status
            if (alreadyPresent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: colors.present.background,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(
                    color: colors.present.foreground.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.done_all_rounded, color: colors.present.foreground, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'تم تسجيل حضور هذا التلميذ مسبقًا في هذا الاجتماع',
                      style: TextStyle(
                        color: colors.present.foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppDesignColors.darkInk,
                      side: const BorderSide(color: AppDesignColors.darkBorder),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                    ),
                    child: Text(alreadyPresent ? 'مسح تلميذ آخر' : 'إلغاء ومتابعة'),
                  ),
                ),
                if (!alreadyPresent) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isSubmitting ? null : onConfirm,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        isSubmitting ? 'جارٍ التسجيل...' : 'تسجيل الحضور',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.present.foreground,
                        foregroundColor: AppDesignColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.control),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppDesignColors.darkSurfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        border: Border.all(color: AppDesignColors.darkBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppDesignColors.darkMutedInk),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppDesignColors.darkInk, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Modal Sheet allowing manual search by name or code
class _ManualStudentSearchSheet extends StatefulWidget {
  const _ManualStudentSearchSheet({
    required this.students,
    required this.presentIds,
  });

  final List<Student> students;
  final Set<String> presentIds;

  @override
  State<_ManualStudentSearchSheet> createState() =>
      _ManualStudentSearchSheetState();
}

class _ManualStudentSearchSheetState extends State<_ManualStudentSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final filtered = widget.students.where((s) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final nameMatches = s.name.toLowerCase().contains(q);
      final phoneMatches = s.phone?.contains(q) ?? false;
      final idMatches = s.id.toLowerCase().contains(q);
      return nameMatches || phoneMatches || idMatches;
    }).toList();

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.75,
      decoration: const BoxDecoration(
        color: AppDesignColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.bottomSheet)),
        border: Border(
          top: BorderSide(color: AppDesignColors.primaryContainer, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppDesignColors.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'بحث وتحديد تلميذ يدويًا',
                    style: TextStyle(
                      color: AppDesignColors.darkInk,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'إغلاق',
                  icon: const Icon(Icons.close_rounded, color: AppDesignColors.darkMutedInk),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: AppDesignColors.darkInk),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppDesignColors.darkCanvas,
                hintText: 'ابحث بالاسم، رقم الهاتف، أو كود التلميذ...',
                hintStyle: const TextStyle(color: AppDesignColors.darkMutedInk),
                prefixIcon: const Icon(Icons.search_rounded, color: AppDesignColors.darkMutedInk),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  borderSide: const BorderSide(color: AppDesignColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  borderSide: const BorderSide(color: AppDesignColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  borderSide: const BorderSide(color: AppDesignColors.primaryContainer, width: 1.5),
                ),
              ),
              onChanged: (val) => setState(() => _query = val.trim()),
            ),
          ),

          const SizedBox(height: 10),

          // Result List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد نتائج مطابقة للبحث',
                      style: TextStyle(color: AppDesignColors.darkMutedInk),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: AppDesignColors.darkBorderSubtle, height: 1),
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      final isPresent = widget.presentIds.contains(student.id);

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          onTap: () => Navigator.pop(context, student),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppDesignColors.darkSurfaceSubtle,
                            child: Text(
                              student.name.isEmpty
                                  ? '؟'
                                  : student.name.characters.first,
                              style: const TextStyle(
                                color: AppDesignColors.darkInk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: const TextStyle(
                              color: AppDesignColors.darkInk,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (student.grade?.isNotEmpty == true) student.grade!,
                              if (student.school?.isNotEmpty == true) student.school!,
                              if (student.phone?.isNotEmpty == true) student.phone!,
                            ].join(' • '),
                            style: const TextStyle(
                              color: AppDesignColors.darkMutedInk,
                              fontSize: 13,
                            ),
                          ),
                          trailing: isPresent
                              ? Chip(
                                  label: const Text('مسجل', style: TextStyle(fontSize: 13)),
                                  backgroundColor: colors.present.background,
                                  labelStyle: TextStyle(color: colors.present.foreground),
                                  visualDensity: VisualDensity.compact,
                                )
                              : const Icon(
                                  Icons.chevron_left_rounded,
                                  color: AppDesignColors.darkMutedInk,
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
