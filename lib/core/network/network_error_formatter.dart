import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Formats backend, network, and validation errors into user-friendly Arabic
/// messages consistent with the application's localization conventions.
///
/// Prevents leaking sensitive technical internals, raw tokens, or stack traces.
class NetworkErrorFormatter {
  const NetworkErrorFormatter._();

  static String format(Object? error) {
    if (error == null) return 'حدث خطأ غير متوقع.';

    if (error is SocketException ||
        error.runtimeType.toString() == 'ClientException' ||
        error.toString().contains('ClientException') ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('NetworkRequestFailed') ||
        error.toString().contains('Connection refused')) {
      return 'لا يوجد اتصال بالإنترنت. تتطلب هذه العملية اتصالاً نشطاً بالإنترنت.';
    }

    if (error is TimeoutException ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('timed out')) {
      return 'تعذر الاتصال بالخادم (انتهت مهلة الطلب). يرجى التحقق من الاتصال والمحاولة لاحقًا.';
    }

    if (error is AuthException ||
        error.toString().contains('JWTExpired') ||
        error.toString().contains('Invalid token')) {
      return 'انتهت صلاحية الجلسة أو غير مصرح لك. يرجى إعادة تسجيل الدخول.';
    }

    if (error is PostgrestException) {
      // Permission / RLS rejection
      if (error.code == '42501') {
        return 'ليس لديك الصلاحية الكافية لتنفيذ هذا الإجراء على الخادم.';
      }
      // Unique constraint
      if (error.code == '23505') {
        return 'البيانات المدخلة مسجلة بالفعل في النظام.';
      }
      // Foreign key constraint
      if (error.code == '23503') {
        return 'تعذر إتمام العملية بسبب عدم تطابق البيانات المرتبطة.';
      }
      // Validation / Check constraint
      if (error.code == '23514') {
        return 'البيانات المدخلة غير صالحة ولا تطابق شروط النظام.';
      }
      final status = int.tryParse(error.code ?? '');
      if (status != null && status >= 500) {
        return 'الخادم غير متاح حاليًا. يرجى المحاولة لاحقًا.';
      }
      return error.message.isNotEmpty
          ? error.message
          : 'حدث خطأ أثناء معالجة الطلب على الخادم.';
    }

    if (error is FormatException) {
      return 'صيغة البيانات المدخلة غير صالحة.';
    }

    final message = error.toString();
    if (message.contains('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }
}
