import 'dart:async';

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/warehouse/Stock_in/controller/stock_in_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/products/screen/product_qr_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StockProductSearch extends StatefulWidget {
  final StockController controller;
  final ValueChanged<Map<String, dynamic>> onSelected;
  final Map<String, dynamic>? selectedProduct;

  const StockProductSearch({
    super.key,
    required this.controller,
    required this.onSelected,
    this.selectedProduct,
  });

  @override
  State<StockProductSearch> createState() => _StockProductSearchState();
}

class _StockProductSearchState extends State<StockProductSearch> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _showResults = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.selectedProduct != null) {
      _searchCtrl.text = widget.selectedProduct!['name']?.toString() ?? '';
    }
  }

  @override
  void didUpdateWidget(covariant StockProductSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedProduct == null && oldWidget.selectedProduct != null) {
      _searchCtrl.clear();
    } else if (widget.selectedProduct != null) {
      _searchCtrl.text = widget.selectedProduct!['name']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (value.trim().length < 2) {
        setState(() {
          _results.clear();
          _showResults = false;
        });
        return;
      }
      setState(() => _loading = true);
      final list = await widget.controller.searchProducts(value);
      if (!mounted) return;
      setState(() {
        _results
          ..clear()
          ..addAll(list);
        _loading = false;
        _showResults = true;
      });
    });
  }

  Future<void> _scanBarcode() async {
    final result = await Get.to<Map<String, dynamic>>(
      () => const ProductQRScanScreen(),
    );

    if (result != null && result.isNotEmpty) {
      final scannedBarcode =
          result['text']?.toString() ??
          result['id']?.toString() ??
          result['url']?.toString() ??
          result['barcode']?.toString() ??
          result['code']?.toString() ??
          result['rawValue']?.toString();

      if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
        // Search for product by barcode
        final list = await widget.controller.searchProducts(scannedBarcode);

        if (list.isNotEmpty) {
          final product = list.first;
          setState(() {
            _searchCtrl.text = product['name']?.toString() ?? scannedBarcode;
            _results.clear();
            _results.addAll(list);
            _showResults = true;
          });

          Get.snackbar(
            'Product Found',
            'Found: ${product['name']}',
            backgroundColor: Colors.green.shade100,
            colorText: Colors.black,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          setState(() {
            _searchCtrl.text = scannedBarcode;
            _results.clear();
            _showResults = false;
          });

          Get.snackbar(
            'Product Not Found',
            'No product found with barcode: $scannedBarcode',
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.black,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            labelText: 'Select Product *',
            hintText: 'Search by name or SKU...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                GestureDetector(
                  onTap: _scanBarcode,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _onSearch,
          onTap: () {
            if (_searchCtrl.text.length >= 2 && _results.isNotEmpty) {
              setState(() => _showResults = true);
            }
          },
        ),
        if (_showResults && _results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) {
                final product = _results[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    product['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${product['sku']} • ${product['categoryName'] ?? 'Uncategorized'}',
                    style: TextStyle(fontSize: 11, color: kSubText),
                  ),
                  trailing: Text(
                    '${product['currentStock']} ${product['stockUnit'] ?? 'pcs'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    widget.onSelected(product);
                    setState(() {
                      _showResults = false;
                      _searchCtrl.text = product['name']?.toString() ?? '';
                    });
                  },
                );
              },
            ),
          ),
        if (widget.selectedProduct != null &&
            widget.selectedProduct!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.selectedProduct!['name']?.toString() ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                      Text(
                        'Stock: ${widget.selectedProduct!['currentStock']} ${widget.selectedProduct!['stockUnit'] ?? 'pcs'}',
                        style: TextStyle(fontSize: 12, color: kSubText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => widget.onSelected({}),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
