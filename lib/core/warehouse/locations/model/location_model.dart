// core/warehouse/locations/model/location_model.dart

class WarehouseLocation {
  final String id;
  final String name;
  final String code;
  final String type;
  final bool isDefault;
  final bool isActive;
  final String? address;
  final String? phone;
  final String? notes;

  WarehouseLocation({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    this.isDefault = false,
    this.isActive = true,
    this.address,
    this.phone,
    this.notes,
  });

  factory WarehouseLocation.fromJson(Map<String, dynamic> json) {
    return WarehouseLocation(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Shop',
      isDefault: json['isDefault'] == true,
      isActive: json['isActive'] != false,
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': type,
      'isDefault': isDefault,
      'isActive': isActive,
      'address': address,
      'phone': phone,
      'notes': notes,
    };
  }

  String get typeDisplay {
    switch (type) {
      case 'POS_Store':
        return 'POS Store';
      case 'Warehouse':
        return 'Warehouse';
      case 'Shop':
        return 'Shop';
      default:
        return type;
    }
  }
}
