import 'dart:collection';
import 'dart:io';

const _packageName = 'church_service_management_system';

class _Directive {
  const _Directive(this.uri);
  final String uri;
}

class _Violation implements Comparable<_Violation> {
  const _Violation(this.rule, this.source, this.target);
  final String rule;
  final String source;
  final String target;

  String get line => 'VIOLATION|$rule|$source|$target';

  @override
  int compareTo(_Violation other) => line.compareTo(other.line);
}

void main() {
  final files = _dartFiles();
  final violations = <_Violation>[];
  final featureEdges = <String, Set<String>>{};
  final pairCounts = <String, int>{};
  final featureNames = <String>{};

  for (final file in files) {
    final source = _relativePath(file.path);
    final sourceFeature = _featureOf(source);
    if (sourceFeature != null) featureNames.add(sourceFeature);

    for (final directive in _directives(file.readAsStringSync())) {
      final uri = directive.uri;
      final resolved = _resolveImport(source, uri);
      final targetFeature = resolved == null ? null : _featureOf(resolved);

      if (sourceFeature != null &&
          targetFeature != null &&
          sourceFeature != targetFeature) {
        final targetPath = resolved;
        if (targetPath == null) continue;
        featureEdges.putIfAbsent(sourceFeature, () => <String>{})
            .add(targetFeature);
        final pair = '$sourceFeature|$targetFeature';
        pairCounts[pair] = (pairCounts[pair] ?? 0) + 1;

        if (targetPath != 'lib/features/$targetFeature/$targetFeature.dart') {
          violations.add(_Violation('R1', source, targetPath));
        }
        if (_isPresentation(source) &&
            (_isPresentation(targetPath) || _isData(targetPath))) {
          violations.add(_Violation('R7', source, targetPath));
        }
        if (_isData(source) && _isData(targetPath)) {
          violations.add(_Violation('R8-X', source, targetPath));
        }
      }

      if (_isCore(source) &&
          resolved != null &&
          (resolved.startsWith('lib/features/') ||
              resolved.startsWith('lib/app/'))) {
        violations.add(_Violation('R3', source, resolved));
      }

      if (source.startsWith('lib/shared_kernel/') &&
          !_isAllowedSharedKernelImport(uri, resolved)) {
        violations.add(_Violation('R4', source, uri));
      }

      if (_isDomain(source)) {
        final package = _packageOf(uri);
        if (package == 'flutter') {
          if (uri == 'package:flutter/foundation.dart') {
            violations.add(_Violation('R5-SOFT', source, uri));
          } else {
            violations.add(_Violation('R5', source, uri));
          }
        } else if (package == 'supabase_flutter' ||
            package == 'drift' ||
            package == 'flutter_riverpod') {
          violations.add(_Violation('R5', source, uri));
        }
      }

      if ((_isPresentation(source) || _isApplication(source)) &&
          (_packageOf(uri) == 'supabase_flutter' ||
              _packageOf(uri) == 'drift')) {
        violations.add(_Violation('R10', source, uri));
      }
    }
  }

  violations.sort();
  final uniqueViolations = <String>{};
  for (final violation in violations) {
    if (uniqueViolations.add(violation.line)) {
      stdout.writeln(violation.line);
    }
  }

  final cycles = _stronglyConnectedComponents(featureNames, featureEdges)
      .where((component) => component.length > 1)
      .map((component) => component.toList()..sort())
      .toList()
    ..sort((a, b) => a.join(',').compareTo(b.join(',')));

  for (final cycle in cycles) {
    stdout.writeln('CYCLE|${cycle.join(',')}');
  }

  final ruleCounts = SplayTreeMap<String, int>();
  for (final line in uniqueViolations) {
    final rule = line.split('|')[1];
    ruleCounts[rule] = (ruleCounts[rule] ?? 0) + 1;
  }

  stdout.writeln('SUMMARY');
  stdout.writeln('FILES|${files.length}');
  for (final rule in <String>[
    'R1', 'R2', 'R3', 'R4', 'R5', 'R5-SOFT', 'R7', 'R8-X', 'R10',
  ]) {
    final count = rule == 'R2' ? cycles.length : (ruleCounts[rule] ?? 0);
    stdout.writeln('RULE_COUNT|$rule|$count');
  }
  stdout.writeln('CYCLE_COUNT|${cycles.length}');

  for (final entry in SplayTreeMap<String, int>.from(pairCounts).entries) {
    final parts = entry.key.split('|');
    stdout.writeln('FEATURE_PAIR|${parts[0]}|${parts[1]}|${entry.value}');
  }

  final fanIn = <String, Set<String>>{};
  final fanOut = <String, Set<String>>{};
  for (final feature in featureNames) {
    fanIn[feature] = <String>{};
    fanOut[feature] = <String>{};
  }
  for (final entry in featureEdges.entries) {
    fanOut.putIfAbsent(entry.key, () => <String>{}).addAll(entry.value);
    for (final target in entry.value) {
      fanIn.putIfAbsent(target, () => <String>{}).add(entry.key);
    }
  }
  for (final feature in featureNames.toList()..sort()) {
    stdout.writeln('FEATURE_FAN_IN|$feature|${fanIn[feature]?.length ?? 0}');
    stdout.writeln('FEATURE_FAN_OUT|$feature|${fanOut[feature]?.length ?? 0}');
  }
}

List<File> _dartFiles() {
  final lib = Directory('lib');
  if (!lib.existsSync()) return <File>[];
  return lib
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) {
        final path = file.path.replaceAll(r'\', '/');
        return path.endsWith('.dart') &&
            !path.endsWith('.g.dart') &&
            !path.endsWith('.freezed.dart');
      })
      .toList()
    ..sort((a, b) => _relativePath(a.path).compareTo(_relativePath(b.path)));
}

String _relativePath(String path) {
  var normalized = path.replaceAll(r'\', '/');
  while (normalized.startsWith('./')) {
    normalized = normalized.substring(2);
  }
  return normalized;
}

Iterable<_Directive> _directives(String source) sync* {
  final directivePattern = RegExp(
    r'^\s*(?:import|export)\s+([^;]+);',
    multiLine: true,
    dotAll: true,
  );
  final uriPattern = RegExp(r'''['"]([^'"]+)['"]''');
  for (final directive in directivePattern.allMatches(source)) {
    final body = directive.group(1);
    if (body == null) continue;
    for (final match in uriPattern.allMatches(body)) {
      final uri = match.group(1);
      if (uri == null) continue;
      yield _Directive(uri);
    }
  }
}

String? _resolveImport(String source, String uri) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:')) {
    final remainder = uri.substring('package:'.length);
    final slash = remainder.indexOf('/');
    if (slash < 0 || remainder.substring(0, slash) != _packageName) {
      return null;
    }
    return _normalizePath('lib/${remainder.substring(slash + 1)}');
  }
  if (uri.startsWith('/') || uri.contains('://')) return null;
  final sourceDirectory = source.substring(0, source.lastIndexOf('/') + 1);
  return _normalizePath('$sourceDirectory$uri');
}

String _normalizePath(String path) {
  final segments = <String>[];
  for (final segment in path.replaceAll(r'\', '/').split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else {
      segments.add(segment);
    }
  }
  return segments.join('/');
}

String? _featureOf(String path) {
  final parts = path.split('/');
  if (parts.length >= 4 && parts[0] == 'lib' && parts[1] == 'features') {
    return parts[2];
  }
  return null;
}

String? _packageOf(String uri) {
  if (!uri.startsWith('package:')) return null;
  final remainder = uri.substring('package:'.length);
  final slash = remainder.indexOf('/');
  return slash < 0 ? remainder : remainder.substring(0, slash);
}

bool _isCore(String path) => path.startsWith('lib/core/');
bool _isDomain(String path) =>
    path.startsWith('lib/features/') && path.contains('/domain/');
bool _isPresentation(String path) =>
    path.startsWith('lib/features/') && path.contains('/presentation/');
bool _isApplication(String path) =>
    path.startsWith('lib/features/') && path.contains('/application/');
bool _isData(String path) =>
    path.startsWith('lib/features/') && path.contains('/data/');

bool _isAllowedSharedKernelImport(String uri, String? resolved) {
  if (uri.startsWith('dart:')) return true;
  if (resolved == null) return false;
  return resolved.startsWith('lib/core/') ||
      resolved.startsWith('lib/shared_kernel/');
}

List<Set<String>> _stronglyConnectedComponents(
  Set<String> nodes,
  Map<String, Set<String>> edges,
) {
  var nextIndex = 0;
  final indices = <String, int>{};
  final lowLinks = <String, int>{};
  final stack = <String>[];
  final onStack = <String>{};
  final components = <Set<String>>[];

  void connect(String node) {
    indices[node] = nextIndex;
    lowLinks[node] = nextIndex;
    nextIndex++;
    stack.add(node);
    onStack.add(node);

    final neighbors = (edges[node] ?? <String>{}).toList()..sort();
    for (final neighbor in neighbors) {
      if (!indices.containsKey(neighbor)) {
        connect(neighbor);
        if (lowLinks[neighbor]! < lowLinks[node]!) {
          lowLinks[node] = lowLinks[neighbor]!;
        }
      } else if (onStack.contains(neighbor) &&
          indices[neighbor]! < lowLinks[node]!) {
        lowLinks[node] = indices[neighbor]!;
      }
    }

    if (lowLinks[node] == indices[node]) {
      final component = <String>{};
      while (stack.isNotEmpty) {
        final member = stack.removeLast();
        onStack.remove(member);
        component.add(member);
        if (member == node) break;
      }
      components.add(component);
    }
  }

  for (final node in nodes.toList()..sort()) {
    if (!indices.containsKey(node)) connect(node);
  }
  return components;
}
