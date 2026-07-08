class WarehouseCustomer {
  final String id;
  final String customerNumber;
  final String name;
  final String? email;
  final String? phone;
  final String? company;
  final String customerType;
  final String? taxId;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? billingAddress;

  WarehouseCustomer({
    required this.id,
    required this.customerNumber,
    required this.name,
    this.email,
    this.phone,
    this.company,
    this.customerType = 'Individual',
    this.taxId,
    this.address,
    this.shippingAddress,
    this.billingAddress,
  });

  factory WarehouseCustomer.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? readMap(dynamic value) {
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    return WarehouseCustomer(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      customerNumber: json['customerNumber']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      company: json['company']?.toString(),
      customerType: json['customerType']?.toString() ?? 'Individual',
      taxId: json['taxId']?.toString(),
      address: readMap(json['address']),
      shippingAddress: readMap(json['shippingAddress']),
      billingAddress: readMap(json['billingAddress']),
    );
  }

  Map<String, dynamic>? get primaryAddress =>
      shippingAddress ?? address ?? billingAddress;
}
