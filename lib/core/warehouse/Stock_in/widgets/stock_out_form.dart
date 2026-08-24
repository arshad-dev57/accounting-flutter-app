import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/warehouse/Stock_in/controller/stock_in_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Stock_in/widgets/stock_product_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StockOutForm extends StatefulWidget {
  final StockController controller;
  final VoidCallback onSuccess;

  const StockOutForm({
    super.key,
    required this.controller,
    required this.onSuccess,
  });

  @override
  State<StockOutForm> createState() => _StockOutFormState();
}

class _StockOutFormState extends State<StockOutForm> {
  Map<String, dynamic>? _selectedProduct;
  final _quantityCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _stockOutReason = 'damage_expiry';
  List<Map<String, dynamic>> _stockOutReasons = [];
  String? _error;

  int get _currentStock => (_selectedProduct?['currentStock'] as int?) ?? 0;
  int get _qty => int.tryParse(_quantityCtrl.text) ?? 0;
  int get _remaining => _currentStock - _qty;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    final reasons = await widget.controller.fetchStockReasons();
    if (!mounted) return;
    setState(() {
      _stockOutReasons = List<Map<String, dynamic>>.from(
        reasons['stockOut'] as List? ?? [],
      );
      if (_stockOutReasons.isNotEmpty) {
        _stockOutReason =
            _stockOutReasons.first['value']?.toString() ?? 'damage_expiry';
      }
    });
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _customerCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_selectedProduct == null) {
      setState(() => _error = 'Please select a product');
      return;
    }
    if (_qty <= 0) {
      setState(() => _error = 'Please enter a valid quantity');
      return;
    }
    if (_qty > _currentStock) {
      setState(() => _error = 'Insufficient stock. Available: $_currentStock');
      return;
    }
    if (_stockOutReason.isEmpty) {
      setState(() => _error = 'Please select a stock out reason');
      return;
    }

    final ok = await widget.controller.removeStock(
      productId: _selectedProduct!['id'].toString(),
      quantity: _qty,
      stockOutReason: _stockOutReason,
      customerName: _customerCtrl.text.trim().isEmpty
          ? null
          : _customerCtrl.text.trim(),
      reference: _referenceCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    if (ok) {
      setState(() {
        _selectedProduct = null;
        _quantityCtrl.clear();
        _customerCtrl.clear();
        _referenceCtrl.clear();
        _notesCtrl.clear();
      });
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Stock Out',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text(
                'Dispatch inventory',
                style: TextStyle(fontSize: 11, color: kSubText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),
          StockProductSearch(
            controller: widget.controller,
            selectedProduct: _selectedProduct,
            onSelected: (p) =>
                setState(() => _selectedProduct = p.isEmpty ? null : p),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantityCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity *',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_selectedProduct != null && _qty > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade100),
              ),
              child: Text(
                'Stock after dispatch: $_remaining ${_selectedProduct!['stockUnit'] ?? 'pcs'} remaining',
                style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _customerCtrl,
            decoration: const InputDecoration(
              labelText: 'Customer',
              hintText: 'Customer name...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _stockOutReason,
            decoration: const InputDecoration(
              labelText: 'Stock Out Reason *',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _stockOutReasons
                .map(
                  (r) => DropdownMenuItem(
                    value: r['value']?.toString() ?? '',
                    child: Text(r['label']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (v) =>
                setState(() => _stockOutReason = v ?? 'damage_expiry'),
          ),
          const SizedBox(height: 4),
          Text(
            'Posts Dr expense / Cr Inventory automatically',
            style: TextStyle(fontSize: 11, color: kSubText),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceCtrl,
            decoration: const InputDecoration(
              labelText: 'Reference #',
              hintText: 'SO # or Invoice #',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => ElevatedButton(
              onPressed: widget.controller.isSubmitting.value ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: widget.controller.isSubmitting.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_down, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Confirm Stock Out',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
