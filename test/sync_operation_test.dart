import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:church_service_management_system/core/sync/sync_operation.dart';

void main() {
  test('sync operation preserves a stable operation id and JSON payload', () {
    const operation = SyncOperation(
      operationId: 'operation-1',
      entityType: 'reporting_period',
      operationType: 'insert',
      payloadJson: '{"id":"period-1","service_id":"service-1"}',
    );

    final payload = jsonDecode(operation.payloadJson) as Map<String, dynamic>;

    expect(operation.operationId, 'operation-1');
    expect(operation.entityType, 'reporting_period');
    expect(operation.operationType, 'insert');
    expect(payload['id'], 'period-1');
  });
}
