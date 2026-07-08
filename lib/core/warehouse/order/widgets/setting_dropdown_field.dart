import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/order/controller/sales_order_controller.dart';
import 'package:flutter/material.dart';

class SettingDropdownField extends StatelessWidget {
  final String label;
  final String category;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool requiredField;
  final VoidCallback onManage;

  const SettingDropdownField({
    super.key,
    required this.label,
    required this.category,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.onManage,
    this.requiredField = false,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value)
        ? value
        : (options.isNotEmpty ? options.first : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          requiredField ? '$label *' : label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kSubText),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: safeValue.isEmpty ? null : safeValue,
                decoration: InputDecoration(
                  hintText: 'Select $label',
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: options
                    .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onManage,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}

class SettingsManageSheet extends StatefulWidget {
  final SalesOrderController controller;
  final String category;
  final String title;

  const SettingsManageSheet({
    super.key,
    required this.controller,
    required this.category,
    required this.title,
  });

  @override
  State<SettingsManageSheet> createState() => _SettingsManageSheetState();
}

class _SettingsManageSheetState extends State<SettingsManageSheet> {
  final TextEditingController _input = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_input.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final ok = await widget.controller.addSetting(widget.category, _input.text.trim());
    setState(() => _saving = false);
    if (ok) {
      _input.clear();
      setState(() {});
    }
  }

  Future<void> _delete(String name) async {
    await widget.controller.deleteSetting(widget.category, name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.controller.optionsForCategory(widget.category);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: InputDecoration(
                    hintText: 'Enter new ${widget.title.toLowerCase()}',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saving ? null : _add,
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.add, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final item = options[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: kDanger),
                    onPressed: () => _delete(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void openSettingsManageSheet(
  BuildContext context,
  SalesOrderController controller,
  String category,
  String title,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SettingsManageSheet(
      controller: controller,
      category: category,
      title: title,
    ),
  );
}
