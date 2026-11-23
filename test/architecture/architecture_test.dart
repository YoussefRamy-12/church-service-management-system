import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/arch_audit_lib.dart';

const _allowlistPath = 'test/architecture/known_violations.txt';

void main() {
  test(
    'live audit violations are all present in the known-violations allowlist',
    () {
      final audit = collectAudit(Directory('lib'));
      final liveViolations = audit.violations.map((item) => item.line).toSet();
      final allowlist = _readAllowlist();
      final unexpected = liveViolations.difference(allowlist);

      expect(
        unexpected,
        isEmpty,
        reason: _allowlistDiffMessage(_contractLines(audit), allowlist),
      );
    },
    timeout: Timeout(Duration(seconds: 60)),
  );

  test(
    'known-violations allowlist contains no stale records',
    () {
      final audit = collectAudit(Directory('lib'));
      final liveRecords = _contractLines(audit);
      final allowlist = _readAllowlist();
      final stale = allowlist.difference(liveRecords);

      expect(
        stale,
        isEmpty,
        reason: _allowlistDiffMessage(liveRecords, allowlist),
      );
    },
    timeout: Timeout(Duration(seconds: 60)),
  );

  test(
    'the strongly connected feature set may only shrink',
    () {
      final audit = collectAudit(Directory('lib'));
      final baselineMembers = _cycleMembers(_readAllowlist());
      final liveMembers = _cycleMembers(_cycleLines(audit));
      final addedMembers = liveMembers.difference(baselineMembers).toList()
        ..sort();

      expect(
        addedMembers,
        isEmpty,
        reason: 'New feature(s) joined the known cycle: '
            '${addedMembers.join(', ')}\n'
            '${_allowlistDiffMessage(_contractLines(audit), _readAllowlist())}',
      );
    },
    timeout: Timeout(Duration(seconds: 60)),
  );

  test(
    'fixture returns the exact expected violations, reciprocal pair, and SCC',
    () {
      final fixtureRoot =
          Directory.systemTemp.createTempSync('architecture_audit_fixture_');
      addTearDown(() {
        if (fixtureRoot.existsSync()) {
          fixtureRoot.deleteSync(recursive: true);
        }
      });

      final libDir = Directory(
        '${fixtureRoot.path}${Platform.pathSeparator}lib',
      )..createSync(recursive: true);

      void writeFixture(String relativePath, String contents) {
        final normalized = relativePath.replaceAll(
          '/',
          Platform.pathSeparator,
        );
        final file = File(
          '${libDir.path}${Platform.pathSeparator}$normalized',
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(contents);
      }

      writeFixture(
        'features/a/data/a.dart',
        "import 'package:church_service_management_system/"
        "features/b/domain/b.dart';\n",
      );
      writeFixture(
        'features/b/domain/b.dart',
        "import 'package:church_service_management_system/"
        "features/a/data/a.dart';\n",
      );
      writeFixture(
        'core/feature_reader.dart',
        "import 'package:church_service_management_system/"
        "features/c/domain/entity.dart';\n",
      );
      writeFixture(
        'core/app_reader.dart',
        "import 'package:church_service_management_system/app/bootstrap.dart';\n",
      );
      writeFixture('app/bootstrap.dart', 'class Bootstrap {}\n');
      writeFixture(
        'features/c/domain/entity.dart',
        "import 'package:flutter/material.dart';\n",
      );
      writeFixture(
        'features/d/presentation/page.dart',
        "import 'package:supabase_flutter/supabase_flutter.dart';\n",
      );

      final audit = collectAudit(libDir);
      const expectedViolations = <String>[
        'VIOLATION|R1|lib/features/a/data/a.dart|'
            'lib/features/b/domain/b.dart',
        'VIOLATION|R1|lib/features/b/domain/b.dart|'
            'lib/features/a/data/a.dart',
        'VIOLATION|R3|lib/core/app_reader.dart|lib/app/bootstrap.dart',
        'VIOLATION|R3|lib/core/feature_reader.dart|'
            'lib/features/c/domain/entity.dart',
        'VIOLATION|R5|lib/features/c/domain/entity.dart|'
            'package:flutter/material.dart',
        'VIOLATION|R10|lib/features/d/presentation/page.dart|'
            'package:supabase_flutter/supabase_flutter.dart',
      ];
      const expectedReciprocalPairs = <String>[
        'RECIPROCAL_PAIR|a|b',
      ];
      const expectedCycles = <String>[
        'CYCLE|a,b',
      ];
      final actualViolations =
          audit.violations.map((item) => item.line).toList()..sort();
      final actualReciprocalPairs =
          audit.reciprocalPairs.map((item) => item.line).toList();
      final actualCycles = audit.cycles
          .map((cycle) {
            final members = cycle.toList()..sort();
            return 'CYCLE|${members.join(',')}';
          })
          .toList();

      final actualRecords = _contractLines(audit);
      final expectedRecords = <String>{
        ...expectedViolations,
        ...expectedReciprocalPairs,
        ...expectedCycles,
      };

      expect(
        actualViolations,
        expectedViolations,
        reason: _allowlistDiffMessage(actualRecords, expectedRecords),
      );
      expect(
        actualReciprocalPairs,
        expectedReciprocalPairs,
        reason: _allowlistDiffMessage(actualRecords, expectedRecords),
      );
      expect(
        actualCycles,
        expectedCycles,
        reason: _allowlistDiffMessage(actualRecords, expectedRecords),
      );
      expect(audit.counts.fileCount, 7);
      expect(audit.counts.cycleCount, 1);
      expect(audit.counts.reciprocalPairCount, 1);
      expect(
        audit.counts.ruleCounts,
        <String, int>{'R1': 2, 'R3': 2, 'R5': 1, 'R10': 1},
      );
    },
    timeout: Timeout(Duration(seconds: 60)),
  );

  test(
    'allowlist loader ignores comment lines and blank lines',
    () {
      const source = '''
# baseline comment

VIOLATION|R1|source.dart|target.dart

  # indented comment
RECIPROCAL_PAIR|alpha|beta

''';
      final actual = _loadAllowlistLines(source);
      const expected = <String>{
        'VIOLATION|R1|source.dart|target.dart',
        'RECIPROCAL_PAIR|alpha|beta',
      };

      expect(
        actual,
        expected,
        reason: _allowlistDiffMessage(actual, expected),
      );
    },
    timeout: Timeout(Duration(seconds: 60)),
  );
}

Set<String> _readAllowlist() {
  return _loadAllowlistLines(File(_allowlistPath).readAsStringSync());
}

Set<String> _loadAllowlistLines(String content) {
  return content
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

Set<String> _contractLines(AuditResult audit) {
  return <String>{
    ...audit.violations.map((item) => item.line),
    ...audit.reciprocalPairs.map((item) => item.line),
    ..._cycleLines(audit),
  };
}

Set<String> _cycleLines(AuditResult audit) {
  return audit.cycles.map((cycle) {
    final members = cycle.toList()..sort();
    return 'CYCLE|${members.join(',')}';
  }).toSet();
}

Set<String> _cycleMembers(Iterable<String> lines) {
  final members = <String>{};
  for (final line in lines.where((item) => item.startsWith('CYCLE|'))) {
    final cycle = line.substring('CYCLE|'.length);
    if (cycle.isNotEmpty) members.addAll(cycle.split(','));
  }
  return members;
}

String _allowlistDiffMessage(
  Set<String> liveLines,
  Set<String> allowlistedLines,
) {
  final additions = liveLines.difference(allowlistedLines).toList()..sort();
  final removals = allowlistedLines.difference(liveLines).toList()..sort();
  final buffer = StringBuffer()
    ..writeln('Allowlist reconciliation:')
    ..writeln('Add these exact lines:');
  if (additions.isEmpty) {
    buffer.writeln('(none)');
  } else {
    for (final line in additions) {
      buffer.writeln('ADD: $line');
    }
  }
  buffer.writeln('Remove these exact lines:');
  if (removals.isEmpty) {
    buffer.writeln('(none)');
  } else {
    for (final line in removals) {
      buffer.writeln('REMOVE: $line');
    }
  }
  return buffer.toString();
}
