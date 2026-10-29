import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Compact WhatsApp and dialer actions for an existing phone number.
/// The call action opens the system dialer; it never places a call directly.
class PhoneContactActions extends StatelessWidget {
  const PhoneContactActions({
    super.key,
    required this.phone,
    this.compact = false,
  });

  final String phone;
  final bool compact;

  String get _digits => phone.replaceAll(RegExp(r'[^0-9]'), '');

  String get _internationalDigits {
    var value = _digits;
    if (value.startsWith('00')) value = value.substring(2);
    // Egyptian local mobile/landline numbers are commonly stored with a
    // leading zero; convert them to Egypt's country code for WhatsApp links.
    if (value.startsWith('0')) value = '20${value.substring(1)}';
    return value;
  }

  Future<void> _launch(BuildContext context, Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('No application could handle the request.');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق الاتصال أو WhatsApp لهذا الرقم.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_digits.isEmpty) return const SizedBox.shrink();
    final iconSize = compact ? 19.0 : 21.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'إرسال رسالة عبر WhatsApp',
          visualDensity: VisualDensity.compact,
          iconSize: iconSize,
          onPressed: _internationalDigits.isEmpty
              ? null
              : () => _launch(context, Uri.https('wa.me', '/$_internationalDigits')),
          icon: const Icon(Icons.chat_rounded, color: Color(0xFF16A34A)),
        ),
        IconButton(
          tooltip: 'فتح الرقم في تطبيق الاتصال',
          visualDensity: VisualDensity.compact,
          iconSize: iconSize,
          onPressed: () => _launch(context, Uri(scheme: 'tel', path: phone.trim())),
          icon: const Icon(Icons.call_rounded),
        ),
      ],
    );
  }
}
