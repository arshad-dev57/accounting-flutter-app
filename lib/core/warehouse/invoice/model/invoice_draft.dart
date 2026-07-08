class InvoiceLineDraft {
  String description;
  int quantity;
  double unitPrice;
  double taxRate;
  String? sku;
  String? productId;

  InvoiceLineDraft({
    required this.description,
    this.quantity = 1,
    this.unitPrice = 0,
    this.taxRate = 0,
    this.sku,
    this.productId,
  });

  double get amount => quantity * unitPrice;
  double get taxAmount => amount * (taxRate / 100);
  double get lineTotal => amount + taxAmount;

  Map<String, dynamic> toPayload() => {
        'productId': productId,
        'productName': description.split(' (').first,
        'sku': sku,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'taxRate': taxRate,
      };

  factory InvoiceLineDraft.fromProduct(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? 'Product';
    final sku = product['sku']?.toString() ?? '';
    return InvoiceLineDraft(
      productId: product['id']?.toString(),
      sku: sku,
      description: sku.isNotEmpty ? '$name ($sku)' : name,
      quantity: 1,
      unitPrice: _toDouble(product['sellingPrice'] ?? product['price']),
      taxRate: _toDouble(product['taxRate']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class InvoiceDraft {
  String? customerId;
  String? customerName;
  DateTime issueDate;
  DateTime dueDate;
  double discount;
  String notes;
  List<InvoiceLineDraft> lines;
  String? sourceOrderId;
  String? sourceOrderNumber;

  InvoiceDraft({
    this.customerId,
    this.customerName,
    required this.issueDate,
    required this.dueDate,
    this.discount = 0,
    this.notes = '',
    List<InvoiceLineDraft>? lines,
    this.sourceOrderId,
    this.sourceOrderNumber,
  }) : lines = lines ?? [];

  double get subtotal => lines.fold(0.0, (s, l) => s + l.amount);
  double get taxTotal => lines.fold(0.0, (s, l) => s + l.taxAmount);
  double get grandTotal => (subtotal + taxTotal - discount).clamp(0, double.infinity);

  Map<String, dynamic> toPayload() {
    var noteText = notes;
    if (sourceOrderNumber != null && sourceOrderNumber!.isNotEmpty) {
      noteText = [if (notes.isNotEmpty) notes, 'Warehouse order: $sourceOrderNumber'].join('\n');
    }
    return {
      'customerId': customerId,
      'customerName': customerName ?? '',
      'invoiceDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'discountTotal': discount,
      'notes': noteText,
      'orderId': sourceOrderId,
      'orderNumber': sourceOrderNumber,
      'invoiceStatus': 'Sent',
      'items': lines.map((l) => l.toPayload()).toList(),
    };
  }
}
