import os
import re

LIB_DIR = os.path.join(os.path.dirname(__file__), '..', 'lib')
SKIP_FILES = {'currency_controller.dart', 'currency_utils.dart'}

IMPORT_LINE = "import 'package:LedgerPro_app/Utils/currency_utils.dart';\n"

def add_import(content: str) -> str:
    if 'currency_utils.dart' in content:
        return content
    for anchor in [
        "import 'package:LedgerPro_app/Utils/colors.dart';\n",
        "import 'package:flutter/material.dart';\n",
        "import 'package:get/get.dart';\n",
    ]:
        if anchor in content:
            return content.replace(anchor, anchor + IMPORT_LINE, 1)
    return IMPORT_LINE + content

def process_file(path: str) -> bool:
    name = os.path.basename(path)
    if name in SKIP_FILES:
        return False

    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    content = content.replace(
        "return '\\$ ${formatter.format(amount)}';",
        'return CurrencyUtils.format(amount);',
    )
    content = content.replace(
        "String _formatAmount(double amount) => '\\$ ${amount.toStringAsFixed(2)}';",
        'String _formatAmount(double amount) => CurrencyUtils.format(amount);',
    )
    content = content.replace("prefixText: '\\$ '", 'prefixText: CurrencyUtils.prefix')
    content = content.replace("prefix: '\\$ '", 'prefix: CurrencyUtils.prefix')

    content = re.sub(
        r"String _formatAmount\(double amount\) \{\s*final formatter = NumberFormat\('#,##0\.00', 'en_US'\);\s*return '\\\$ \$\{formatter\.format\(amount\)\}';\s*\}",
        'String _formatAmount(double amount) => CurrencyUtils.format(amount);',
        content,
        flags=re.MULTILINE,
    )

    content = re.sub(
        r"String formatAmount\(double amount\) \{\s*final formatter = NumberFormat\('#,##0\.00', 'en_US'\);\s*return '\\\$ \$\{formatter\.format\(amount\)\}';\s*\}",
        'String formatAmount(double amount) => CurrencyUtils.format(amount);',
        content,
        flags=re.MULTILINE,
    )

    if content != original:
        content = add_import(content)
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)
        return True
    return False

def main():
    updated = []
    for root, _, files in os.walk(LIB_DIR):
        for name in files:
            if not name.endswith('.dart'):
                continue
            path = os.path.join(root, name)
            if process_file(path):
                updated.append(path)
    print(f'Updated {len(updated)} files')
    for p in updated:
        print(os.path.relpath(p, LIB_DIR))

if __name__ == '__main__':
    main()
