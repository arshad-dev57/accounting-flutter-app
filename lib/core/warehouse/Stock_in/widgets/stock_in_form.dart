import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/warehouse/Stock_in/controller/stock_in_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Stock_in/widgets/stock_product_search.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StockInForm extends StatefulWidget {
  final StockController controller;
  final VoidCallback onSuccess;

  const StockInForm({
    super.key,
    required this.controller,
    required this.onSuccess,
  });

  @override
  State<StockInForm> createState() => _StockInFormState();
}

class _StockInFormState extends State<StockInForm> {
  Map<String, dynamic>? _selectedProduct;
  String _stockType = 'bulk';
  final _quantityCtrl = TextEditingController();
  final _boxCountCtrl = TextEditingController();
  final _piecesPerBoxCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _supplierId;
  List<Map<String, dynamic>> _suppliers = [];
  bool _loadingSuppliers = true;
  String? _error;

  int get _totalPieces {
    if (_stockType == 'box') {
      final boxes = int.tryParse(_boxCountCtrl.text) ?? 0;
      final pieces = int.tryParse(_piecesPerBoxCtrl.text) ?? 0;
      return boxes * pieces;
    }
    return int.tryParse(_quantityCtrl.text) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final list = await widget.controller.fetchSuppliers();
    if (mounted) {
      setState(() {
        _suppliers = list;
        _loadingSuppliers = false;
      });
    }
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _boxCountCtrl.dispose();
    _piecesPerBoxCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_selectedProduct == null ||
        (_selectedProduct!['id']?.toString().isEmpty ?? true)) {
      setState(() => _error = 'Please select a product');
      return;
    }
    if (_stockType == 'bulk' && (int.tryParse(_quantityCtrl.text) ?? 0) <= 0) {
      setState(() => _error = 'Please enter quantity');
      return;
    }
    if (_stockType == 'box') {
      if ((int.tryParse(_boxCountCtrl.text) ?? 0) <= 0 ||
          (int.tryParse(_piecesPerBoxCtrl.text) ?? 0) <= 0) {
        setState(() => _error = 'Please enter box count and pieces per box');
        return;
      }
    }

    Map<String, dynamic>? supplier;
    if (_supplierId != null) {
      for (final s in _suppliers) {
        if (s['id']?.toString() == _supplierId) {
          supplier = s;
          break;
        }
      }
    }

    final ok = await widget.controller.addStock(
      productId: _selectedProduct!['id'].toString(),
      stockType: _stockType,
      quantity: _stockType == 'box'
          ? int.parse(_boxCountCtrl.text)
          : int.parse(_quantityCtrl.text),
      boxCount: _stockType == 'box' ? int.parse(_boxCountCtrl.text) : null,
      piecesPerBox: _stockType == 'box'
          ? int.parse(_piecesPerBoxCtrl.text)
          : null,
      supplierId: _supplierId,
      supplierName: supplier?['name']?.toString() ?? 'Walk-in',
      reference: _referenceCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    if (ok) {
      setState(() {
        _selectedProduct = null;
        _quantityCtrl.clear();
        _boxCountCtrl.clear();
        _piecesPerBoxCtrl.clear();
        _referenceCtrl.clear();
        _notesCtrl.clear();
        _supplierId = null;
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
              Icon(
                Icons.local_shipping,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Stock In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text(
                'Receive inventory',
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _typeCard(
                  'Bulk Quantity',
                  'bulk',
                  Icons.bar_chart,
                  'Simple quantity',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _typeCard(
                  'Box / Case',
                  'box',
                  Icons.inventory_2_outlined,
                  'Box tracking',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_stockType == 'bulk') ...[
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
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _boxCountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Number of Boxes *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _piecesPerBoxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pieces per Box *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            if (_totalPieces > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  '${_boxCountCtrl.text} boxes × ${_piecesPerBoxCtrl.text} pieces = $_totalPieces total pieces',
                  style: TextStyle(fontSize: 13, color: Colors.green.shade800),
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _supplierId,
            decoration: InputDecoration(
              labelText: 'Supplier',
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _loadingSuppliers
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Select supplier...'),
              ),
              ..._suppliers.map(
                (s) => DropdownMenuItem(
                  value: s['id']?.toString(),
                  child: Text(
                    '${s['name']}${(s['companyName']?.toString().isNotEmpty ?? false) ? ' (${s['companyName']})' : ''}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _supplierId = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _referenceCtrl,
            decoration: const InputDecoration(
              labelText: 'Reference #',
              hintText: 'PO # or Invoice #',
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
                backgroundColor: Colors.green.shade600,
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
                        Icon(Icons.trending_up, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Confirm Stock In',
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

  Widget _typeCard(String title, String value, IconData icon, String subtitle) {
    final selected = _stockType == value;
    return InkWell(
      onTap: () => setState(() => _stockType = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? kPrimary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? kPrimary.withOpacity(0.05) : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: selected ? kPrimary : kSubText),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? kPrimary : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 10, color: kSubText)),
          ],
        ),
      ),
    );
  }
}
