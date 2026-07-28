import 'dart:async';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/warehouse/order/controller/sales_order_controller.dart';
import 'package:flutter/material.dart';

class ProductSearchField extends StatefulWidget {
  final SalesOrderController controller;
  final ValueChanged<Map<String, dynamic>?> onSelected;

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
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _selectedProduct;
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), _removeOverlay);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();

    final renderBox = context.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 300;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 54),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(10),
            color: kCardBg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: _products.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No products found',
                        style: TextStyle(color: kSubText, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: _products.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.grey.withOpacity(0.1)),
                      itemBuilder: (_, i) {
                        final p = _products[i];
                        final stock =
                            (p['currentStock'] as num?)?.toInt() ?? 0;
                        final price =
                            (p['sellingPrice'] as num?)?.toDouble() ?? 0;
                        final outOfStock = stock <= 0;
                        final isSelected =
                            _selectedProduct?['id'] == p['id'];

                        return InkWell(
                          onTap: outOfStock
                              ? null
                              : () {
                                  setState(
                                      () => _selectedProduct = p);
                                  _searchCtrl.text =
                                      p['name']?.toString() ?? '';
                                  widget.onSelected(p);
                                  _removeOverlay();
                                  _focusNode.unfocus();
                                },
                          child: Opacity(
                            opacity: outOfStock ? 0.45 : 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? kPrimary.withOpacity(0.07)
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name']?.toString() ??
                                              'Unknown',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? kPrimary
                                                : kText,
                                          ),
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'SKU: ${p['sku'] ?? '—'} • Stock: $stock',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: outOfStock
                                                ? kDanger
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        widget.controller
                                            .formatCurrency(price),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: kPrimary,
                                        ),
                                      ),
                                      if (outOfStock)
                                        Text(
                                          'Out of stock',
                                          style: TextStyle(
                                              fontSize: 9,
                                              color: kDanger),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _loadProducts(String query) async {
    setState(() => _loading = true);
    final list = await widget.controller.searchProducts(query);
    if (!mounted) return;
    setState(() {
      _products = list;
      _loading = false;
    });
    _showOverlay();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadProducts(value.trim());
    });
  }

  void _clearSelection() {
    _searchCtrl.clear();
    _removeOverlay();
    setState(() {
      _products = [];
      _selectedProduct = null;
    });
    widget.onSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search TextField
          SizedBox(
            height: 48,
            child: TextField(
              controller: _searchCtrl,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Search products by name or SKU...',
                hintStyle: TextStyle(
                    fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      )
                    : _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _clearSelection,
                          )
                        : IconButton(
                            icon: const Icon(Icons.expand_more,
                                size: 20),
                            onPressed: () async {
                              _focusNode.requestFocus();
                              await _loadProducts(
                                  _searchCtrl.text.trim());
                            },
                          ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: kPrimary, width: 1.5),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
              onTap: () => _loadProducts(_searchCtrl.text.trim()),
              onChanged: (v) {
                setState(() {});
                _onSearchChanged(v);
              },
            ),
          ),

          // Selected product chip
          if (_selectedProduct != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: kPrimary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 15, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedProduct!['name']?.toString() ??
                              '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${_selectedProduct!['sku'] ?? '—'} • '
                          'Stock: ${(_selectedProduct!['currentStock'] as num?)?.toInt() ?? 0} • '
                          '${widget.controller.formatCurrency((_selectedProduct!['sellingPrice'] as num?)?.toDouble() ?? 0)}',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearSelection,
                    child: Icon(Icons.close,
                        size: 15, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}