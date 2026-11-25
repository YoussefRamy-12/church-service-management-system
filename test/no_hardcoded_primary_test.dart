import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy navy tokens are confined to app design and theme files', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final forbiddenPatterns = <RegExp>[
      RegExp(r'\bappPrimary\b'),
      RegExp(r'0x[fF]{2}00236[fF]'),
      RegExp(r'AppDesignColors\.primary\b'),
    ];

    final violations = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalizedPath = entity.path.replaceAll('\\', '/');
      if (normalizedPath.startsWith('lib/app/design/') ||
          normalizedPath == 'lib/app/theme.dart') {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final pattern in forbiddenPatterns) {
          if (pattern.hasMatch(line)) {
            violations.add('$normalizedPath:${i + 1}: ${line.trim()}');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Keep legacy navy tokens in lib/app/design/ or lib/app/theme.dart only:\n${violations.join('\n')}',
    );
  });
}

