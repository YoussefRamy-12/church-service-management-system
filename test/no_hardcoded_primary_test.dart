import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/features/** must not reference appPrimary, Color(0xFF00236F), or AppDesignColors.primary', () {
    final featuresDir = Directory('lib/features');
    expect(featuresDir.existsSync(), isTrue);

    final forbiddenPatterns = <RegExp>[
      RegExp(r'\bappPrimary\b'),
      RegExp(r'0x[fF]{2}00236[fF]'),
      RegExp(r'AppDesignColors\.primary\b'),
    ];

    final violations = <String>[];

    for (final entity in featuresDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalizedPath = entity.path.replaceAll('\\', '/');
      if (normalizedPath.endsWith('app_colors.dart') ||
          normalizedPath.endsWith('app_theme.dart')) {
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
          'Use Theme.of(context).colorScheme.primary or design tokens instead of fixed navy:\n${violations.join('\n')}',
    );
  });
}
