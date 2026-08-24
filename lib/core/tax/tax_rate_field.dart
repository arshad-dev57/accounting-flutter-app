import 'package:BisonsTechs_app/core/tax/tax_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TaxRateField extends StatelessWidget {
  final double value;
  final ValueChanged<double> onRateChanged;
  final ValueChanged<String>? onTypeChanged;
  final bool dense;
  final String label;

  const TaxRateField({
    super.key,
    required this.value,
    required this.onRateChanged,
    this.onTypeChanged,
    this.dense = false,
    this.label = 'Tax',
  });

  @override
  Widget build(BuildContext context) {
    final c = ensureTaxController();
    return Obx(() {
      if (!c.enabled.value) {
        final child = InputDecorator(
          decoration: _dec(dense ? 'Tax' : label),
          child: Text(
            'Tax off',
            style: TextStyle(fontSize: dense ? 12 : 13, color: Colors.grey.shade600),
          ),
        );
        return InkWell(onTap: () => Get.toNamed('/tax'), child: child);
      }

      final rates = c.rates.toList();
      Map<String, dynamic>? selected;
      for (final r in rates) {
        if ((r['rate'] as num?)?.toDouble() == value) {
          selected = r;
          if (r['isDefault'] == true) break;
        }
      }

      final currentValue = selected?['id']?.toString() ?? (value == 0 ? '0' : 'custom:$value');
      final items = <DropdownMenuItem<String>>[
        const DropdownMenuItem(value: '0', child: Text('Exempt · 0%')),
        ...rates.map(
          (r) => DropdownMenuItem(
            value: r['id']?.toString() ?? c.rateLabel(r),
            child: Text(c.rateLabel(r), overflow: TextOverflow.ellipsis),
          ),
        ),
      ];
      if (currentValue.startsWith('custom:')) {
        items.add(DropdownMenuItem(value: currentValue, child: Text('Custom $value%')));
      }

      final dropdown = DropdownButtonFormField<String>(
        key: ValueKey('tax-rate-${rates.length}-$currentValue'),
        value: items.any((i) => i.value == currentValue) ? currentValue : '0',
        isExpanded: true,
        decoration: _dec(dense ? 'Tax' : label),
        items: items,
        onChanged: (v) {
          if (v == null || v == '0') {
            onRateChanged(0);
            onTypeChanged?.call('Exempt');
            return;
          }
          final match = rates.firstWhereOrNull((r) => r['id']?.toString() == v);
          if (match != null) {
            onRateChanged((match['rate'] as num?)?.toDouble() ?? 0);
            onTypeChanged?.call(c.deriveProductTaxType(match));
          }
        },
      );

      if (dense) return dropdown;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dropdown,
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => Get.toNamed('/tax'),
              child: const Text('Edit rates in Tax Compliance', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      );
    });
  }

  InputDecoration _dec(String text) {
    return InputDecoration(
      labelText: text,
      isDense: dense,
      border: const OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 8 : 12),
    );
  }
}

class TaxCodeField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const TaxCodeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = ensureTaxController();
    return Obx(() {
      if (!c.enabled.value) {
        return InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Tax Code',
            border: OutlineInputBorder(),
          ),
          child: Row(
            children: [
              const Expanded(child: Text('N/A — tax off', style: TextStyle(fontSize: 13))),
              TextButton(onPressed: () => Get.toNamed('/tax'), child: const Text('Turn on')),
            ],
          ),
        );
      }
      final labels = <String>['N/A', ...c.rates.map(c.rateLabel)];
      if (value.isNotEmpty && !labels.contains(value)) labels.add(value);
      return DropdownButtonFormField<String>(
        value: labels.contains(value) ? value : 'N/A',
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Tax Code', border: OutlineInputBorder()),
        items: labels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: enabled
            ? (v) {
                if (v != null) onChanged(v);
              }
            : null,
      );
    });
  }
}
