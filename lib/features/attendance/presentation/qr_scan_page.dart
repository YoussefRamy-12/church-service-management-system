import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanPage extends StatelessWidget {
  const QrScanPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('مسح QR')),
    body: MobileScanner(onDetect: (capture) {
      final value = capture.barcodes.firstOrNull?.rawValue;
      if (value != null && value.isNotEmpty) Navigator.of(context).pop(value);
    }),
  );
}
