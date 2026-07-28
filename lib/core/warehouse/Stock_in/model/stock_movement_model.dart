import 'package:flutter/material.dart';

class StockDetails {
  final String? type;
  final int? boxCount;
  final int? piecesPerBox;
  final int? totalPieces;
  final int? quantityAdded;

  StockDetails({
    this.type,
    this.boxCount,
    this.piecesPerBox,
    this.totalPieces,
    this.quantityAdded,
  });

  factory StockDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StockDetails();
    return StockDetails(
      type: json['type']?.toString(),
      boxCount: (json['boxCount'] as num?)?.toInt(),
      piecesPerBox: (json['piecesPerBox'] as num?)?.toInt(),
      totalPieces: (json['totalPieces'] as num?)?.toInt(),
      quantityAdded: (json['quantityAdded'] as num?)?.toInt(),
    );
  }

  String? get boxSummary {
    if (boxCount != null && piecesPerBox != null) {
      final total = totalPieces ?? (boxCount! * piecesPerBox!);
      return '$boxCount boxes × $piecesPerBox pcs = $total total';
    }
    return null;
  }
}

class StockMovementModel {
  final String id;
  final String productId;
  final String productName;
  final String type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String? stockType;
  final StockDetails? stockDetails;
  final String reason;
  final String? supplierId;
  final String? supplierName;
  final String? customerName;
  final String? reference;
  final String? notes;
  final String status;
  final UserInfo? createdBy;
  final DateTime createdAt;

  StockMovementModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.stockType,
    this.stockDetails,
    required this.reason,
    this.supplierId,
    this.supplierName,
    this.customerName,
    this.reference,
    this.notes,
    this.status = 'Completed',
    this.createdBy,
    required this.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) {
    return StockMovementModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'stock_in',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      previousStock: (json['previousStock'] as num?)?.toInt() ?? 0,
      newStock: (json['newStock'] as num?)?.toInt() ?? 0,
      stockType: json['stockType']?.toString(),
      stockDetails: json['stockDetails'] != null && json['stockDetails'] is Map
          ? StockDetails.fromJson(Map<String, dynamic>.from(json['stockDetails']))
          : null,
      reason: json['reason']?.toString() ?? '',
      supplierId: json['supplierId']?.toString(),
      supplierName: json['supplierName']?.toString(),
      customerName: json['customerName']?.toString(),
      reference: json['reference']?.toString(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? 'Completed',
      createdBy: json['createdBy'] != null
          ? (json['createdBy'] is String
              ? UserInfo(id: json['createdBy'], name: 'Unknown User')
              : UserInfo.fromJson(Map<String, dynamic>.from(json['createdBy'])))
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String getTypeLabel() => type == 'stock_in' ? 'Stock In' : 'Stock Out';

  Color getTypeColor() =>
      type == 'stock_in' ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);

  IconData getTypeIcon() =>
      type == 'stock_in' ? Icons.arrow_downward : Icons.arrow_upward;
}

class UserInfo {
  final String id;
  final String name;
  final String? email;

  UserInfo({required this.id, required this.name, this.email});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }
}
