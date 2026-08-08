import 'dart:io';

const skipFiles = {'currency_controller.dart', 'currency_utils.dart'};
const importLine =
    "import 'package:BisonsTechs_app/Utils/currency_utils.dart';\n";

String addImport(String content) {
  if (content.contains('currency_utils.dart')) return content;
  for (final anchor in [
    "import 'package:BisonsTechs_app/Utils/colors.dart';\n",
    "import 'package:flutter/material.dart';\n",
    "import 'package:get/get.dart';\n",
  ]) {
    if (content.contains(anchor)) {
      return content.replaceFirst(anchor, anchor + importLine);
    }
  }
  return importLine + content;
}

bool processFile(File file) {
  if (skipFiles.contains(file.uri.pathSegments.last)) return false;

  var content = file.readAsStringSync();
  final original = content;

  content = content.replaceAll(
    r"return '\$ ${formatter.format(amount)}';",
    'return CurrencyUtils.format(amount);',
  );
  content = content.replaceAll(
    r"String _formatAmount(double amount) => '\$ ${amount.toStringAsFixed(2)}';",
    'String _formatAmount(double amount) => CurrencyUtils.format(amount);',
  );
  content = content.replaceAll(
    r"return '\$. ${amount.toStringAsFixed(2)}';",
    'return CurrencyUtils.format(amount);',
  );
  content = content.replaceAll(
    r"'\$. ${amount.toStringAsFixed(2)}'",
    'CurrencyUtils.format(amount)',
  );
  content = content.replaceAll(
    r"prefixText: '\$ '",
    'prefixText: CurrencyUtils.prefix',
  );
  content = content.replaceAll(
    r"prefix: '\$ '",
    'prefix: CurrencyUtils.prefix',
  );

  content = content.replaceAllMapped(
    RegExp(
      r"String (_formatAmount|formatAmount)\(double amount\) \{\s*return '\\\$ \$\{amount\.toStringAsFixed\(2\)\}';\s*\}",
      multiLine: true,
    ),
    (m) =>
        'String ${m.group(1)}(double amount) => CurrencyUtils.format(amount);',
  );

  content = content.replaceAllMapped(
    RegExp(
      r"String (_formatAmount|formatAmount)\(double amount\) \{\s*final formatter = NumberFormat\('[^']+', 'en_US'\);\s*return CurrencyUtils\.format\(amount\);\s*\}",
      multiLine: true,
    ),
    (m) =>
        'String ${m.group(1)}(double amount) => CurrencyUtils.format(amount);',
  );

  content = content.replaceAllMapped(
    RegExp(
      r"String _formatAmount\(double amount\) \{\s*final f = NumberFormat\('[^']+', 'en_US'\);\s*return '\\\$ \$\{f\.format\(amount\)\}';\s*\}",
      multiLine: true,
    ),
    (_) =>
        'String _formatAmount(double amount) => CurrencyUtils.format(amount);',
  );

  // Bank compact amounts
  content = content.replaceAllMapped(
    RegExp(
      r"String _formatCompactAmount\(double amount\) \{\s*if \(amount >= 10000000\) \{\s*return '\\\$ \$\{\(amount / 10000000\)\.toStringAsFixed\(1\)\}Cr';\s*\}\s*if \(amount >= 100000\) \{\s*return '\\\$ \$\{\(amount / 100000\)\.toStringAsFixed\(1\)\}L';\s*\}\s*if \(amount >= 1000\) \{\s*return '\\\$ \$\{\(amount / 1000\)\.toStringAsFixed\(0\)\}K';\s*\}\s*return '\\\$ \$\{amount\.toStringAsFixed\(0\)\}';\s*\}",
      multiLine: true,
      dotAll: true,
    ),
    (_) =>
        'String _formatCompactAmount(double amount) => CurrencyUtils.formatCompact(amount);',
  );

  if (content == original) return false;

  content = addImport(content);
  file.writeAsStringSync(content);
  return true;
}

void main() {
  final libDir = Directory('lib');
  var count = 0;
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (processFile(entity)) {
      print(entity.path);
      count++;
    }
  }
  print('Updated $count files');
}
