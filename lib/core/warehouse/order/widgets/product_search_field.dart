import 'dart:async';

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/order/controller/sales_order_controller.dart';
import 'package:flutter/material.dart';

class ProductSearchField extends StatefulWidget {
  final SalesOrderController controller;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const ProductSearchField({
    super.key,
    required this.controller,
    required this.onSelected,
  });

  @override
  State<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<ProductSearchField> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _products = [];
  bool _loading = false;
  bool _expanded = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts(String query) async {
    setState(() => _loading = true);
    final list = await widget.controller.searchProducts(query);
    if (!mounted) return;
    setState(() {
      _products
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadProducts(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search products by name or SKU...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () async {
                      setState(() => _expanded = !_expanded);
                      if (_expanded && _products.isEmpty) {
                        await _loadProducts('');
                      }
                    },
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onTap: () async {
            if (!_expanded) {
              setState(() => _expanded = true);
              if (_products.isEmpty) await _loadProducts('');
            }
          },
          onChanged: (value) {
            setState(() => _expanded = true);
            _onSearchChanged(value);
          },
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: _products.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No products found', style: TextStyle(color: kSubText)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final stock = (product['currentStock'] as num?)?.toInt() ?? 0;
                      final outOfStock = stock <= 0;
                      return ListTile(
                        dense: true,
                        title: Text(product['name']?.toString() ?? 'Unknown'),
                        subtitle: Text(
                          '${product['sku']} • Stock: $stock • ${widget.controller.formatCurrency((product['sellingPrice'] as num?)?.toDouble() ?? 0)}',
                        ),
                        enabled: !outOfStock,
                        onTap: outOfStock
                            ? null
                            : () {
                                widget.onSelected(product);
                                setState(() {
                                  _expanded = false;
                                  _searchCtrl.text = product['name']?.toString() ?? '';
                                });
                              },
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
