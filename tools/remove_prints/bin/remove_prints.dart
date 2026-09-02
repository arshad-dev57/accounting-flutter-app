import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

/// Temporary cleanup tool — removes top-level `print(...)` invocations from lib/.
void main(List<String> args) {
  final projectRoot = p.normalize(
    p.join(p.dirname(Platform.script.toFilePath()), '..', '..', '..'),
  );
  final libDir = Directory(p.join(projectRoot, 'lib'));
  if (!libDir.existsSync()) {
    stderr.writeln('lib/ directory not found at ${libDir.path}');
    exit(1);
  }

  var filesChanged = 0;
  var printsRemoved = 0;

  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;

    final original = entity.readAsStringSync();
    final unit = parseString(content: original, throwIfDiagnostics: false).unit;

    final visitor = _PrintInvocationCollector();
    unit.visitChildren(visitor);

    if (visitor.ranges.isEmpty) continue;

    final updated = _applyRemovals(original, visitor.ranges);
    if (updated != original) {
      entity.writeAsStringSync(updated);
      filesChanged++;
      printsRemoved += visitor.ranges.length;
      stdout.writeln(
        '  ${p.relative(entity.path, from: projectRoot)}: ${visitor.ranges.length}',
      );
    }
  }

  stdout.writeln('');
  stdout.writeln('Files changed: $filesChanged');
  stdout.writeln('Print statements removed: $printsRemoved');
}

class _Range {
  final int start;
  final int end;

  const _Range(this.start, this.end);
}

class _PrintInvocationCollector extends RecursiveAstVisitor<void> {
  final List<_Range> ranges = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isTopLevelPrint(node)) {
      _maybeRecord(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (_isTopLevelPrintFunction(node)) {
      _maybeRecord(node);
    }
    super.visitFunctionExpressionInvocation(node);
  }

  bool _isTopLevelPrint(MethodInvocation node) {
    return node.methodName.name == 'print' && node.realTarget == null;
  }

  bool _isTopLevelPrintFunction(FunctionExpressionInvocation node) {
    final fn = node.function;
    return fn is SimpleIdentifier && fn.name == 'print';
  }

  void _maybeRecord(AstNode node) {
    final parent = node.parent;
    if (parent is ExpressionStatement) {
      ranges.add(_Range(parent.offset, parent.end));
      return;
    }
    // Fallback: remove only the invocation (rare non-statement usage).
    ranges.add(_Range(node.offset, node.end));
  }
}

String _applyRemovals(String source, List<_Range> ranges) {
  final expanded = <_Range>[];

  for (final range in ranges) {
    final start = _lineStart(source, range.start);
    var end = range.end;

    // Drop trailing whitespace on the line after the statement.
    while (end < source.length &&
        source[end] != '\n' &&
        source[end] != '\r' &&
        _isHorizontalSpace(source.codeUnitAt(end))) {
      end++;
    }

    // Drop one trailing newline to avoid blank lines piling up.
    if (end < source.length && source[end] == '\r') end++;
    if (end < source.length && source[end] == '\n') end++;

    expanded.add(_Range(start, end));
  }

  expanded.sort((a, b) => b.start.compareTo(a.start));

  var result = source;
  for (final range in expanded) {
    if (range.start < 0 || range.end > result.length || range.start >= range.end) {
      continue;
    }
    result = result.replaceRange(range.start, range.end, '');
  }
  return result;
}

int _lineStart(String source, int offset) {
  var i = offset;
  while (i > 0 && source[i - 1] != '\n') {
    i--;
  }
  return i;
}

bool _isHorizontalSpace(int codeUnit) {
  return codeUnit == 0x20 || codeUnit == 0x09;
}
