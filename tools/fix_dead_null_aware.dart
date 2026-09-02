import 'dart:io';

/// Removes dead `response.message ?? '...'` fallbacks where message is non-nullable.
void main() {
  final libDir = Directory('lib');
  final pattern = RegExp(
    r'''response\.message\s*\?\?\s*(?:'(?:\\'|[^'])*'|"[^"]*"|'Server error: \$\{response\.statusCode\}')''',
  );

  var total = 0;
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final source = entity.readAsStringSync();
    final updated = source.replaceAll(pattern, 'response.message');
    if (updated != source) {
      final count = pattern.allMatches(source).length;
      entity.writeAsStringSync(updated);
      total += count;
      stdout.writeln('${entity.path}: $count');
    }
  }
  stdout.writeln('Total replacements: $total');
}
