import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Set<String> liveContractLines;
  late Set<String> allowlistLines;

  setUpAll(() async {
    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'tool/arch_audit.dart'],
    );
    expect(
      result.exitCode,
      0,
      reason: 'The live architecture audit failed:\n${result.stderr}',
    );
    final output = (result.stdout as String).split('\n');
    liveContractLines = _contractLines(output).toSet();
    allowlistLines = _readAllowlist();
  });

  test('every live violation, reciprocal pair, and cycle is allowlisted', () {
    final unexpected = liveContractLines.difference(allowlistLines);
    expect(
      unexpected,
      isEmpty,
      reason: _allowlistDiffMessage(liveContractLines, allowlistLines),
    );
  });

  test('allowlist contains no fixed violations or stale graph records', () {
    final stale = allowlistLines.difference(liveContractLines);
    expect(
      stale,
      isEmpty,
      reason: _allowlistDiffMessage(liveContractLines, allowlistLines),
    );
  });

  test('the feature cycle may shrink but may not gain new members', () {
    final baselineMembers = _cycleMembers(allowlistLines);
    final liveMembers = _cycleMembers(liveContractLines);
    final addedMembers = liveMembers.difference(baselineMembers).toList()
      ..sort();

    expect(
      addedMembers,
      isEmpty,
      reason: 'New feature(s) joined the known cycle: '
          '${addedMembers.join(', ')}\n'
          '${_allowlistDiffMessage(liveContractLines, allowlistLines)}',
    );
  });

  test('fixture detects the expected architecture violations and cycle',
      () async {
    final fixtureRoot =
        Directory.systemTemp.createTempSync('architecture_audit_fixture_');
    addTearDown(() {
      if (fixtureRoot.existsSync()) {
        fixtureRoot.deleteSync(recursive: true);
      }
    });

    final script = File('tool/arch_audit.dart').absolute;
    final fixtureTool = Directory(
      '${fixtureRoot.path}${Platform.pathSeparator}tool',
    )..createSync(recursive: true);
    script.copySync(
      '${fixtureTool.path}${Platform.pathSeparator}arch_audit.dart',
    );

    void writeFixture(String relativePath, String contents) {
      final file = File(
        '${fixtureRoot.path}${Platform.pathSeparator}'
        '${relativePath.replaceAll('/', Platform.pathSeparator)}',
      );
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(contents);
    }

    writeFixture(
      'lib/features/a/data/a.dart',
      "import 'package:church_service_management_system/"
      "features/b/domain/b.dart';\n",
    );
    writeFixture(
      'lib/features/b/domain/b.dart',
      "import 'package:church_service_management_system/"
      "features/a/data/a.dart';\n",
    );
    writeFixture(
      'lib/core/handler.dart',
      "import 'package:church_service_management_system/"
      "features/c/domain/c.dart';\n",
    );
    writeFixture(
      'lib/features/c/domain/c.dart',
      "import 'package:flutter/material.dart';\n",
    );
    writeFixture(
      'lib/features/d/presentation/page.dart',
      "import 'package:supabase_flutter/supabase_flutter.dart';\n",
    );

    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>['run', 'tool/arch_audit.dart'],
      workingDirectory: fixtureRoot.path,
    );
    expect(
      result.exitCode,
      0,
      reason: 'Fixture audit process failed:\n${result.stderr}',
    );

    final output = (result.stdout as String).split('\n');
    final violations = output
        .where((line) => line.startsWith('VIOLATION|'))
        .toList()
      ..sort();
    final expectedViolations = <String>[
      'VIOLATION|R10|lib/features/d/presentation/page.dart|'
          'package:supabase_flutter/supabase_flutter.dart',
      'VIOLATION|R1|lib/features/a/data/a.dart|'
          'lib/features/b/domain/b.dart',
      'VIOLATION|R1|lib/features/b/domain/b.dart|'
          'lib/features/a/data/a.dart',
      'VIOLATION|R3|lib/core/handler.dart|'
          'lib/features/c/domain/c.dart',
      'VIOLATION|R5|lib/features/c/domain/c.dart|'
          'package:flutter/material.dart',
    ]..sort();

    expect(violations, expectedViolations);
    expect(
      output.where((line) => line.startsWith('FEATURE_PAIR|')).toList(),
      <String>[
        'FEATURE_PAIR|a|b|1',
        'FEATURE_PAIR|b|a|1',
      ],
    );
    expect(
      output.where((line) => line.startsWith('RECIPROCAL_PAIR|')).toList(),
      <String>['RECIPROCAL_PAIR|a|b'],
    );
    expect(output, contains('RECIPROCAL_PAIR_COUNT|1'));
    expect(output, contains('CYCLE|a,b'));
  });

  test('allowlist diagnostics print exact add and remove lines', () {
    final message = _allowlistDiffMessage(
      <String>{'VIOLATION|R1|new.dart|target.dart'},
      <String>{'VIOLATION|R1|old.dart|target.dart'},
    );

    expect(
      message,
      contains('ADD: VIOLATION|R1|new.dart|target.dart'),
    );
    expect(
      message,
      contains('REMOVE: VIOLATION|R1|old.dart|target.dart'),
    );
  });
}

Set<String> _readAllowlist() {
  return File('test/architecture/known_violations.txt')
      .readAsLinesSync()
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

List<String> _contractLines(Iterable<String> lines) {
  return lines
      .where(
        (line) =>
            line.startsWith('VIOLATION|') ||
            line.startsWith('RECIPROCAL_PAIR|') ||
            line.startsWith('CYCLE|'),
      )
      .toList();
}

Set<String> _cycleMembers(Iterable<String> lines) {
  final members = <String>{};
  for (final line in lines.where((line) => line.startsWith('CYCLE|'))) {
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
