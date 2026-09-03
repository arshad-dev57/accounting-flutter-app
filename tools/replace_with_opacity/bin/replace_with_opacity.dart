import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// Replaces `.withOpacity(value)` with `.withValues(alpha: value)`.
void main() {
  final projectRoot = p.normalize(
    p.join(p.dirname(Platform.script.toFilePath()), '..', '..', '..'),
  );
  final libDir = Directory(p.join(projectRoot, 'lib'));
  if (!libDir.existsSync()) {
    stderr.writeln('lib/ directory not found at ${libDir.path}');
    exit(1);
  }

  var filesChanged = 0;
  var replacements = 0;

  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final source = entity.readAsStringSync();
    final unit = parseString(content: source, throwIfDiagnostics: false).unit;

    final collector = _WithOpacityCollector(source);
    unit.visitChildren(collector);

    if (collector.edits.isEmpty) continue;

    final updated = _applyEdits(source, collector.edits);
    if (updated != source) {
      entity.writeAsStringSync(updated);
      filesChanged++;
      replacements += collector.edits.length;
      stdout.writeln(
        '  ${p.relative(entity.path, from: projectRoot)}: ${collector.edits.length}',
      );
    }
  }

  stdout.writeln('');
  stdout.writeln('Files changed: $filesChanged');
  stdout.writeln('withOpacity usages replaced: $replacements');
}

class _Edit {
  final int start;
  final int end;
  final String replacement;

  const _Edit(this.start, this.end, this.replacement);
}

class _WithOpacityCollector extends RecursiveAstVisitor<void> {
  final String source;
  final List<_Edit> edits = [];

  _WithOpacityCollector(this.source);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'withOpacity') {
      final args = node.argumentList.arguments;
      final target = node.realTarget;
      if (args.length == 1 && target != null) {
        final receiverText = source.substring(target.offset, target.end);
        final argText = source.substring(args.first.offset, args.first.end);
        edits.add(
          _Edit(
            node.offset,
            node.end,
            '$receiverText.withValues(alpha: $argText)',
          ),
        );
      }
    }
    super.visitMethodInvocation(node);
  }
}

String _applyEdits(String source, List<_Edit> edits) {
  final sorted = List<_Edit>.from(edits)
    ..sort((a, b) => b.start.compareTo(a.start));

  var result = source;
  for (final edit in sorted) {
    if (edit.start < 0 || edit.end > result.length || edit.start >= edit.end) {
      continue;
    }
    result = result.replaceRange(edit.start, edit.end, edit.replacement);
  }
  return result;
}
