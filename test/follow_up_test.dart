import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('follow-up payload contains stable client operation id', () {
    final payload = {
      'id': 'follow-up-1',
      'student_id': 'student-1',
      'created_by': 'servant-1',
      'contact_status': 'contacted',
      'client_operation_id': 'operation-1',
    };
    final decoded = jsonDecode(jsonEncode(payload)) as Map<String,dynamic>;
    expect(decoded['client_operation_id'], 'operation-1');
  });

  test('follow-up payload supports recurring follow-up', () {
    final payload = {
      'another_follow_up_needed': true,
      'next_follow_up_date': '2026-10-13',
    };
    expect(payload['another_follow_up_needed'], isTrue);
    expect(payload['next_follow_up_date'], '2026-10-13');
  });
}
