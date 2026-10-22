import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../students/domain/entities/student.dart';

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

class _QrScanPageState extends State<QrScanPage> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

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
    try {
      await _controller.start();
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      if (_closing ||
          _scannedStudent != null ||
          (lifecycleState != null &&
              lifecycleState != AppLifecycleState.resumed)) {
        await _stopCamera();
        return;
      }
      if (mounted) setState(() => _cameraError = null);
    } catch (error) {
      if (mounted) setState(() => _cameraError = error.toString());
    }
  }

  Future<void> _pauseCamera() async {
    final inFlight = _startOperation;
    if (inFlight != null) await inFlight;
    await _stopCamera();
  }

  Future<void> _stopCamera() async {
    if (_controllerDisposed) return;
    try {
      await _controller.stop();
    } catch (_) {
      // The controller may already have stopped while the app was backgrounded.
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handlingResult || _closing) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (value.isEmpty) return;

    _handlingResult = true;
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
    if (_closing) return;
    setState(() {
      _scannedStudent = null;
      _unknownCode = false;
      _handlingResult = false;
      _cameraError = null;
    });
    await _startCamera();
  }

  Future<void> _closeScanner([String? studentId]) async {
    if (_closing) return;
    setState(() => _closing = true);
    final inFlight = _startOperation;
    if (inFlight != null) await inFlight;
    await _stopCamera();
    if (!mounted) return;

    // Remove the camera preview before disposing its controller.
    await WidgetsBinding.instance.endOfFrame;
    if (!_controllerDisposed) {
      _controllerDisposed = true;
      _controller.dispose();
    }
    if (!mounted) return;

    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(studentId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_controllerDisposed) {
      _controllerDisposed = true;
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final student = _scannedStudent;
    final alreadyPresent =
        student != null && widget.presentStudentIds.contains(student.id);

    return PopScope<String>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeScanner();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF09111B),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (!_closing)
              MobileScanner(controller: _controller, onDetect: _onDetect)
            else
              const ColoredBox(color: Color(0xFF09111B)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0xCC07111D), Colors.transparent],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        IconButton.filledTonal(
                          onPressed: _closing ? null : _closeScanner,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'إغلاق الكاميرا',
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تسجيل الحضور',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'وجّه الكاميرا إلى رمز الطالب',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        _LiveBadge(
                          paused:
                              student != null ||
                              _unknownCode ||
                              _cameraError != null,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(34),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colors.primary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: .3),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.qr_code_2_rounded,
                                color: Colors.white24,
                                size: 76,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_cameraError != null)
                    _InfoPanel(
                      icon: Icons.no_photography_outlined,
                      title: 'تعذر تشغيل الكاميرا',
                      message: _cameraError!,
                      actionLabel: 'إعادة المحاولة',
                      onAction: _startCamera,
                    )
                  else if (_unknownCode)
                    _InfoPanel(
                      icon: Icons.person_search_rounded,
                      title: 'لم يتم العثور على الطالب',
                      message: 'تأكد من أن الرمز يخص طالبًا في هذه القائمة.',
                      actionLabel: 'مسح رمز آخر',
                      onAction: _resumeScanning,
                    )
                  else if (student != null)
                    _StudentReviewPanel(
                      student: student,
                      alreadyPresent: alreadyPresent,
                      onNo: _resumeScanning,
                      onYes: alreadyPresent
                          ? null
                          : () => _closeScanner(student.id),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 0, 24, 30),
                      child: Text(
                        'سيتم إيقاف المسح تلقائيًا عند العثور على الطالب لمراجعة بياناته.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, height: 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentReviewPanel extends StatelessWidget {
  const _StudentReviewPanel({
    required this.student,
    required this.alreadyPresent,
    required this.onNo,
    required this.onYes,
  });

  final Student student;
  final bool alreadyPresent;
  final VoidCallback onNo;
  final VoidCallback? onYes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    student.name.isEmpty ? '?' : student.name.characters.first,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        student.isPending ? 'بانتظار الاعتماد' : 'طالب معتمد',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(
                  alreadyPresent
                      ? Icons.check_circle_rounded
                      : Icons.qr_code_scanner_rounded,
                  color: alreadyPresent
                      ? Colors.green.shade700
                      : colors.primary,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (student.school?.isNotEmpty == true)
                  _DetailChip(
                    icon: Icons.school_outlined,
                    text: student.school!,
                  ),
                if (student.grade?.isNotEmpty == true)
                  _DetailChip(
                    icon: Icons.menu_book_outlined,
                    text: student.grade!,
                  ),
                if (student.phone?.isNotEmpty == true)
                  _DetailChip(icon: Icons.phone_outlined, text: student.phone!),
                if (student.birthDate != null)
                  _DetailChip(
                    icon: Icons.cake_outlined,
                    text: student.birthDate!
                        .toLocal()
                        .toString()
                        .split(' ')
                        .first,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (alreadyPresent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'تم تسجيل حضور هذا الطالب في الاجتماع الحالي.',
                  textAlign: TextAlign.center,
                ),
              ),
            if (alreadyPresent) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onNo,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('مسح الطالب التالي'),
                ),
              ),
            ] else ...[
              const Text(
                'هل تريد تسجيل حضوره؟',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onNo,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('لا، التالي'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onYes,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('نعم، حاضر'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 17),
    label: Text(text),
    visualDensity: VisualDensity.compact,
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
    decoration: const BoxDecoration(
      color: Color(0xFFF8FAFC),
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.paused});

  final bool paused;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.black38,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.circle,
          color: paused ? const Color(0xFFFFC857) : const Color(0xFF63E6BE),
          size: 9,
        ),
        const SizedBox(width: 6),
        Text(
          paused ? 'متوقف مؤقتًا' : 'مسح مباشر',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}
