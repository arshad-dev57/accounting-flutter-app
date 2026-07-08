class FixedAsset {
  final String id;
  final String name;
  final String assetCode;
  final String category;
  final DateTime purchaseDate;
  final double purchaseCost;
  final int usefulLife;
  final double salvageValue;
  final String depreciationMethod;
  final double currentDepreciation;
  final double accumulatedDepreciation;
  final double netBookValue;
  final String status;
  final String location;
  final String supplier;
  final DateTime? warrantyExpiry;
  final String notes;
  final DateTime? lastDepreciationDate;
  final DateTime? disposedDate;
  final double? disposalAmount;

  FixedAsset({
    required this.id,
    required this.name,
    required this.assetCode,
    required this.category,
    required this.purchaseDate,
    required this.purchaseCost,
    required this.usefulLife,
    required this.salvageValue,
    required this.depreciationMethod,
    required this.currentDepreciation,
    required this.accumulatedDepreciation,
    required this.netBookValue,
    required this.status,
    required this.location,
    required this.supplier,
    this.warrantyExpiry,
    required this.notes,
    this.lastDepreciationDate,
    this.disposedDate,
    this.disposalAmount,
  });

  factory FixedAsset.fromJson(Map<String, dynamic> json) {
    return FixedAsset(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      assetCode: json['assetCode'] ?? '',
      category: json['category'] ?? '',
      purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate']) : DateTime.now(),
      purchaseCost: (json['purchaseCost'] ?? 0).toDouble(),
      usefulLife: json['usefulLife'] ?? 0,
      salvageValue: (json['salvageValue'] ?? 0).toDouble(),
      depreciationMethod: json['depreciationMethod'] ?? 'Straight Line',
      currentDepreciation: (json['currentDepreciation'] ?? 0).toDouble(),
      accumulatedDepreciation: (json['accumulatedDepreciation'] ?? 0).toDouble(),
      netBookValue: (json['netBookValue'] ?? 0).toDouble(),
      status: json['status'] ?? 'Active',
      location: json['location'] ?? '',
      supplier: json['supplierName'] ?? json['supplier'] ?? '',
      warrantyExpiry: json['warrantyExpiry'] != null ? DateTime.parse(json['warrantyExpiry']) : null,
      notes: json['notes'] ?? '',
      lastDepreciationDate: json['lastDepreciationDate'] != null ? DateTime.parse(json['lastDepreciationDate']) : null,
      disposedDate: json['disposedDate'] != null ? DateTime.parse(json['disposedDate']) : null,
      disposalAmount: json['disposalAmount'] != null ? (json['disposalAmount']).toDouble() : null,
    );
  }
}