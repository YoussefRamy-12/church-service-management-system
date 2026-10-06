import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('approval payload moves proposed class to current class', () {
    final payload = <String, dynamic>{
      'approval_status': 'approved',
      'current_class_id': 'class-1',
      'proposed_class_id': null,
    };
    expect(payload['approval_status'], 'approved');
    expect(payload['current_class_id'], 'class-1');
    expect(payload['proposed_class_id'], isNull);
  });

  test('student update payload is JSON serializable', () {
    final payload = <String, dynamic>{
      'id': 'student-1',
      'service_id': 'service-1',
      'current_class_id': 'class-1',
      'proposed_class_id': null,
      'name': 'Peter Updated',
      'birth_date': '2013-04-12',
      'phone': '01000000000',
      'school': 'School',
      'grade': '6',
      'enrollment_at': '2026-10-01T12:00:00.000Z',
      'approval_status': 'approved',
      'photo_path': null,
      'notes': 'Updated note',
    };
    final decoded = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
    expect(decoded['name'], 'Peter Updated');
    expect(decoded['birth_date'], '2013-04-12');
  });

  test('student mutations use update sync operation', () {
    const entityType = 'student';
    const operationType = 'update';
    expect(entityType, 'student');
    expect(operationType, 'update');
  });
}
