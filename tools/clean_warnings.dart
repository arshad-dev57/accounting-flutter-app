import 'dart:io';

/// Removes unused imports reported by `flutter analyze lib`.
Future<void> main() async {
  final root = Directory.current.path;
  final result = await Process.run(
    'flutter',
    ['analyze', 'lib', 'tools/update_currency.dart'],
    workingDirectory: root,
    runInShell: true,
  );
  final output = '${result.stdout}${result.stderr}';

  final removals = <String, Set<int>>{};
  for (final raw in output.split('\n')) {
    if (!raw.contains('unused_import')) continue;
    final match = RegExp(r'• ([^\s]+\.dart):(\d+):\d+ • unused_import').firstMatch(raw);
    if (match == null) continue;
    removals.putIfAbsent(match.group(1)!, () => {}).add(int.parse(match.group(2)!));
  }

  var files = 0;
  var lines = 0;
  for (final entry in removals.entries) {
    final file = File('$root/${entry.key}');
    if (!file.existsSync()) continue;
    final content = file.readAsLinesSync();
    final remove = entry.value.map((l) => l - 1).toSet();
    final out = <String>[];
    for (var i = 0; i < content.length; i++) {
      if (remove.contains(i) && content[i].trim().startsWith('import ')) {
        lines++;
        continue;
      }
      out.add(content[i]);
    }
    if (lines > 0) {
      file.writeAsStringSync('${out.join('\n')}\n');
      files++;
    }
  }
  stdout.writeln('Removed $lines unused imports from $files files');
}
