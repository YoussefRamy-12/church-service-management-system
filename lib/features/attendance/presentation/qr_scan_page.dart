import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../students/domain/entities/student.dart';

/// Redesigned, responsive QR Scanner screen adhering to Diakonia Stewardship design system.
///
/// Implements Impeccable Operate-mode ergonomics:
/// - In-frame camera preview with hardware-accelerated clipping & RTL isolation
/// - Animated laser sweep and glowing precision reticles
/// - Responsive adaptation between narrow phones, tablets, and desktop viewports
/// - Immediate servant feedback with haptics and clear attendance confirmation
/// - Manual search fallback when cameras or QR codes fail
/// - Strict hardware lifecycle teardown on dismissal
class QrScanPage extends StatefulWidget {
  const QrScanPage({
    super.key,
    required this.students,
    required this.presentStudentIds,
  });

  final List<Student> students;
  final Set<String> presentStudentIds;

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

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _laserPosition = CurvedAnimation(
      parent: _laserAnimController,
      curve: Curves.easeInOutSine,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
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
      if (mounted && !_closing) {
        setState(() => _cameraError = error.toString());
      }
    }
  }

  Future<void> _pauseCamera() async {
    final inFlight = _startOperation;
    if (inFlight != null) {
      try {
        await inFlight;
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
    HapticFeedback.mediumImpact();
    await _stopCamera();
    if (!mounted || _closing) return;

    Student? student;
    for (final candidate in widget.students) {
      if (candidate.id == value) {
        student = candidate;
        break;
      }
    }

    setState(() {
      _scannedStudent = student;
      _unknownCode = student == null;
    });
  }

  Future<void> _resumeScanning() async {
    if (_closing || _controllerDisposed) return;
    setState(() {
      _scannedStudent = null;
      _unknownCode = false;
      _handlingResult = false;
      _cameraError = null;
    });
    await _startCamera();
  }

  Future<void> _closeScanner([String? studentId]) async {
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
      Navigator.of(context).pop(studentId);
    }
  }

  void _openManualSearch() async {
    await _pauseCamera();
    if (!mounted || _closing) return;

    final selected = await showModalBottomSheet<Student>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManualStudentSearchSheet(
        students: widget.students,
        presentIds: widget.presentStudentIds,
      ),
    );

    if (!mounted || _closing) return;

    if (selected != null) {
      setState(() {
        _scannedStudent = selected;
        _unknownCode = false;
        _handlingResult = true;
      });
    } else {
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
    final student = _scannedStudent;
    final alreadyPresent =
        student != null && widget.presentStudentIds.contains(student.id);

    return PopScope<String>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeScanner();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Stable fixed viewfinder size (does not fluctuate when resizing the browser window)
              const viewfinderSize = 250.0;

              return Column(
                children: [
                  // Top Navigation & Utility Header
                  _buildHeader(context),

                  // Middle Viewfinder Section
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Viewfinder Container
                            _buildViewfinder(
                              size: viewfinderSize,
                              student: student,
                            ),

                            const SizedBox(height: 16),

                            // Sub-frame instruction badge
                            _buildInstructionBadge(student: student),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Action / Review Section
                  _buildBottomSection(
                    student: student,
                    alreadyPresent: alreadyPresent,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF131D33),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            onPressed: _closing ? null : () => _closeScanner(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'إغلاق الكاميرا',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(width: 14),

          // Title & active context
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تسجيل الحضور بالرمز',
                  style: TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'المسجلين: ${widget.presentStudentIds.length} من ${widget.students.length}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
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
                  color: isTorchOn ? const Color(0xFFFACC15) : Colors.white70,
                ),
                tooltip: isTorchOn ? 'إطفاء الكشاف' : 'تشغيل الكشاف',
                style: IconButton.styleFrom(
                  backgroundColor: isTorchOn
                      ? const Color(0xFF854D0E).withValues(alpha: 0.3)
                      : const Color(0xFF1E293B),
                  padding: const EdgeInsets.all(10),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Camera Direction Switch (Front/Back)
          IconButton(
            onPressed: _closing || _controllerDisposed
                ? null
                : () => _controller.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70),
            tooltip: 'تبديل الكاميرا',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder({
    required double size,
    required Student? student,
  }) {
    final hasError = _cameraError != null;
    final isSuccess = student != null;

    final borderColor = isSuccess
        ? const Color(0xFF10B981)
        : hasError
            ? const Color(0xFFEF4444)
            : const Color(0xFF38BDF8);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Canvas (Strictly clipped & LTR isolated)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: const Color(0xFF0F172A),
              child: !_closing && !_controllerDisposed && !hasError
                  ? Directionality(
                      textDirection: TextDirection.ltr,
                      child: SizedBox.expand(
                        child: MobileScanner(
                          controller: _controller,
                          onDetect: _onDetect,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        hasError
                            ? Icons.videocam_off_rounded
                            : Icons.qr_code_scanner_rounded,
                        color: hasError
                            ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                            : Colors.white24,
                        size: 52,
                      ),
                    ),
            ),
          ),

          // 2. Animated Laser Sweep Line (Only active while scanning)
          if (!isSuccess && !hasError && !_closing)
            AnimatedBuilder(
              animation: _laserPosition,
              builder: (context, child) {
                return Align(
                  alignment: Alignment(0, (_laserPosition.value * 2.0) - 1.0),
                  child: Container(
                    height: 2.5,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF38BDF8).withValues(alpha: 0.0),
                          const Color(0xFF38BDF8),
                          const Color(0xFF38BDF8).withValues(alpha: 0.0),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // 3. Precision Corner Reticles
          CustomPaint(
            painter: _ScannerReticlePainter(
              color: borderColor,
              borderRadius: 20.0,
              strokeWidth: 3.5,
              reticleLength: 28.0,
            ),
          ),

          // 4. Success Overlay Animation
          if (isSuccess)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 68,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructionBadge({required Student? student}) {
    if (_cameraError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: Color(0xFFFCA5A5), size: 16),
            SizedBox(width: 8),
            Text(
              'تعذر قراءة الكاميرا — استخدم البحث اليدوي أدناه',
              style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (student != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF064E3B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF10B981), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, color: Color(0xFF6EE7B7), size: 16),
            SizedBox(width: 8),
            Text(
              'تم التعرف على الطالب بنجاح',
              style: TextStyle(
                color: Color(0xFF6EE7B7),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.crop_free_rounded, color: Color(0xFF38BDF8), size: 16),
          SizedBox(width: 8),
          Text(
            'ضع رمز الاستجابة السريعة (QR) داخل الإطار',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection({
    required Student? student,
    required bool alreadyPresent,
  }) {
    if (_cameraError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF131D33),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _cameraError!,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _startCamera,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة تشغيل الكاميرا'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openManualSearch,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('البحث اليدوي'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
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
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF131D33),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: Color(0xFF1E293B))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_rounded, color: Color(0xFFF59E0B), size: 36),
            const SizedBox(height: 8),
            const Text(
              'الرمز غير مسجل في هذه القائمة',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'تأكد من أن الكود يخص تلميذاً في خدمة هذا الاجتماع.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resumeScanning,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    child: const Text('مسح رمز آخر'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openManualSearch,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('بحث بالاسم'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
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
        onCancel: _resumeScanning,
        onConfirm: alreadyPresent ? null : () => _closeScanner(student.id),
      );
    }

    // Default Bottom Actions while scanning
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF131D33),
        border: Border(
          top: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: _openManualSearch,
            icon: const Icon(Icons.search_rounded, size: 20),
            label: const Text('بحث يدوي عن تلميذ بالاسم'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF94A3B8),
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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

/// High-density, dignified Student Review Card
class _StudentReviewPanel extends StatelessWidget {
  const _StudentReviewPanel({
    required this.student,
    required this.alreadyPresent,
    required this.onCancel,
    required this.onConfirm,
  });

  final Student student;
  final bool alreadyPresent;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 330),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF131D33),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
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
                  backgroundColor: const Color(0xFF1E3A8A),
                  child: Text(
                    student.name.isEmpty ? '؟' : student.name.characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: student.isApproved
                                  ? const Color(0xFF059669).withValues(alpha: 0.2)
                                  : const Color(0xFF904D00).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.isApproved ? 'معتمد' : 'بانتظار الاعتماد',
                              style: TextStyle(
                                color: student.isApproved
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFFBBF24),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (student.isDeacon) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'شماس',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  alreadyPresent
                      ? Icons.check_circle_rounded
                      : Icons.how_to_reg_rounded,
                  color: alreadyPresent
                      ? const Color(0xFF10B981)
                      : const Color(0xFF38BDF8),
                  size: 30,
                ),
              ],
            ),

            const SizedBox(height: 14),

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

            const SizedBox(height: 16),

            // Actions & Status
            if (alreadyPresent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.done_all_rounded, color: Color(0xFF34D399), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'تم تسجيل حضور هذا التلميذ مسبقاً في هذا الاجتماع',
                      style: TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFCBD5E1),
                      side: const BorderSide(color: Color(0xFF334155)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(alreadyPresent ? 'مسح تلميذ آخر' : 'إلغاء ومتابعة'),
                  ),
                ),
                if (!alreadyPresent) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text('تسجيل الحضور'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
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
        color: Color(0xFF131D33),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
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
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'بحث وتحديد تلميذ يدوياً',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0F172A),
                hintText: 'ابحث بالاسم، رقم الهاتف، أو كود التلميذ...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
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
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Color(0xFF1E293B), height: 1),
                    itemBuilder: (context, index) {
                      final student = filtered[index];
                      final isPresent = widget.presentIds.contains(student.id);

                      return ListTile(
                        onTap: () => Navigator.pop(context, student),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF1E293B),
                          child: Text(
                            student.name.isEmpty
                                ? '؟'
                                : student.name.characters.first,
                            style: const TextStyle(
                              color: Color(0xFF38BDF8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          student.name,
                          style: const TextStyle(
                            color: Colors.white,
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
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                        trailing: isPresent
                            ? const Chip(
                                label: Text('مسجل', style: TextStyle(fontSize: 11)),
                                backgroundColor: Color(0xFF064E3B),
                                labelStyle: TextStyle(color: Color(0xFF34D399)),
                                visualDensity: VisualDensity.compact,
                              )
                            : const Icon(
                                Icons.chevron_left_rounded,
                                color: Color(0xFF64748B),
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
