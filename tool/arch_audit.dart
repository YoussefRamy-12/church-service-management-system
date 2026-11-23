import 'dart:io';

import 'arch_audit_lib.dart';

void main(List<String> args) {
  final libDir = Directory(args.isEmpty ? 'lib' : args.first);
  final audit = collectAudit(libDir);

  for (final violation in audit.violations) {
    stdout.writeln(violation.line);
  }

  for (final cycle in audit.cycles) {
    final members = cycle.toList()..sort();
    stdout.writeln('CYCLE|${members.join(',')}');
  }

  stdout.writeln('SUMMARY');
  stdout.writeln('FILES|${audit.counts.fileCount}');
  for (final rule in <String>[
    'R1', 'R2', 'R3', 'R4', 'R5', 'R5-SOFT', 'R7', 'R8-X', 'R10',
  ]) {
    final count = rule == 'R2'
        ? audit.counts.cycleCount
        : (audit.counts.ruleCounts[rule] ?? 0);
    stdout.writeln('RULE_COUNT|$rule|$count');
  }
  stdout.writeln('CYCLE_COUNT|${audit.counts.cycleCount}');
  stdout.writeln('RECIPROCAL_PAIR_COUNT|${audit.counts.reciprocalPairCount}');

  for (final entry in audit.counts.featurePairCounts.entries) {
    final parts = entry.key.split('|');
    stdout.writeln('FEATURE_PAIR|${parts[0]}|${parts[1]}|${entry.value}');
  }

  for (final pair in audit.reciprocalPairs) {
    stdout.writeln(pair.line);
  }

  final features = audit.counts.featureFanIn.keys.toList()..sort();
  for (final feature in features) {
    stdout.writeln(
      'FEATURE_FAN_IN|$feature|${audit.counts.featureFanIn[feature] ?? 0}',
    );
    stdout.writeln(
      'FEATURE_FAN_OUT|$feature|${audit.counts.featureFanOut[feature] ?? 0}',
    );
  }
}
