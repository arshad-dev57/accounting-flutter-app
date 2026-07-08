// lib/core/warehouse/products/model/product_model.dart

import 'package:flutter/material.dart';

class ProductModel {
  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String? description;
  final String categoryId;
  final String? categoryName;
  final String? supplierId;
  final String? supplierName;
  final double costPrice;
  final double sellingPrice;
  final int currentStock;
  final int minimumStock;
  final int maximumStock;
  final String? location;
  final DateTime? expiryDate;
  final List<String>? images;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.description,
    required this.categoryId,
    this.categoryName,
    this.supplierId,
    this.supplierName,
    required this.costPrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumStock,
    this.location,
    this.expiryDate,
    this.images,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      description: json['description']?.toString(),
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString(),
      supplierId: json['supplierId']?.toString(),
      supplierName: json['supplierName']?.toString(),
      costPrice: (json['costPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      currentStock: json['currentStock'] ?? 0,
      minimumStock: json['minimumStock'] ?? 0,
      maximumStock: json['maximumStock'] ?? 0,
      location: json['location']?.toString(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'location': location,
      'expiryDate': expiryDate?.toIso8601String(),
      'images': images,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isLowStock => currentStock <= minimumStock && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  bool get isInStock => currentStock > 0;
  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());
  bool get isExpiringSoon =>
      expiryDate != null &&
      expiryDate!.difference(DateTime.now()).inDays <= 30 &&
      expiryDate!.difference(DateTime.now()).inDays > 0;

  String get stockStatus {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  Color get stockColor {
    if (isOutOfStock) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  double get totalValue => currentStock * sellingPrice;
  double get profit => sellingPrice - costPrice;
  double get profitMargin => costPrice > 0 ? (profit / costPrice) * 100 : 0;
}
