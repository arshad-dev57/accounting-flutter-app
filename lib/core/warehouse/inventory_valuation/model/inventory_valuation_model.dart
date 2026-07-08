// lib/core/warehouse/inventory/model/inventory_valuation_model.dart

import 'package:flutter/material.dart';

class InventoryValuationModel {
  final String id;
  final String name;
  final String sku;
  final String category;
  final String? categoryId;
  final int qty;
  final double unitCost;
  final double sellingPrice;
  final double totalCostValue;
  final double sellingValue;
  final double potentialProfit;
  final double profitMargin;
  final int minStock;
  final int maxStock;
  final String status;
  final String? location;
  final DateTime? expiryDate;

  InventoryValuationModel({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    this.categoryId,
    required this.qty,
    required this.unitCost,
    required this.sellingPrice,
    required this.totalCostValue,
    required this.sellingValue,
    required this.potentialProfit,
    required this.profitMargin,
    required this.minStock,
    required this.maxStock,
    required this.status,
    this.location,
    this.expiryDate,
  });

  factory InventoryValuationModel.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse double
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Remove any non-numeric characters except dot and minus
        final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    // Helper function to safely parse int
    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return InventoryValuationModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Uncategorized',
      categoryId: json['categoryId']?.toString(),
      qty: _parseInt(json['qty']),
      unitCost: _parseDouble(json['unitCost']),
      sellingPrice: _parseDouble(json['sellingPrice']),
      totalCostValue: _parseDouble(json['totalCostValue']),
      sellingValue: _parseDouble(json['sellingValue']),
      potentialProfit: _parseDouble(json['potentialProfit']),
      profitMargin: _parseDouble(json['profitMargin']),
      minStock: _parseInt(json['minStock']),
      maxStock: _parseInt(json['maxStock']),
      status: json['status']?.toString() ?? 'OK',
      location: json['location']?.toString(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'categoryId': categoryId,
      'qty': qty,
      'unitCost': unitCost,
      'sellingPrice': sellingPrice,
      'totalCostValue': totalCostValue,
      'sellingValue': sellingValue,
      'potentialProfit': potentialProfit,
      'profitMargin': profitMargin,
      'minStock': minStock,
      'maxStock': maxStock,
      'status': status,
      'location': location,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  Color getStatusColor() {
    switch (status) {
      case 'LOW':
        return const Color(0xFFE74C3C);
      case 'OVER':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFF2ECC71);
    }
  }

  String getStatusLabel() {
    switch (status) {
      case 'LOW':
        return 'Low Stock';
      case 'OVER':
        return 'Over Stock';
      default:
        return 'OK';
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case 'LOW':
        return Icons.warning_amber_rounded;
      case 'OVER':
        return Icons.inventory_2_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }
}

class ValuationSummary {
  final int totalItems;
  final int totalQty;
  final double totalCostValue;
  final double totalSellingValue;
  final double totalPotentialProfit;
  final double avgProfitMargin;
  final int lowStockCount;
  final int overStockCount;

  ValuationSummary({
    required this.totalItems,
    required this.totalQty,
    required this.totalCostValue,
    required this.totalSellingValue,
    required this.totalPotentialProfit,
    required this.avgProfitMargin,
    required this.lowStockCount,
    required this.overStockCount,
  });

  factory ValuationSummary.fromJson(Map<String, dynamic> json) {
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return ValuationSummary(
      totalItems: _parseInt(json['totalItems']),
      totalQty: _parseInt(json['totalQty']),
      totalCostValue: _parseDouble(json['totalCostValue']),
      totalSellingValue: _parseDouble(json['totalSellingValue']),
      totalPotentialProfit: _parseDouble(json['totalPotentialProfit']),
      avgProfitMargin: _parseDouble(json['avgProfitMargin']),
      lowStockCount: _parseInt(json['lowStockCount']),
      overStockCount: _parseInt(json['overStockCount']),
    );
  }
}

class CategoryBreakdown {
  final String category;
  final int items;
  final int qty;
  final double value;

  CategoryBreakdown({
    required this.category,
    required this.items,
    required this.qty,
    required this.value,
  });

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) {
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return CategoryBreakdown(
      category: json['category']?.toString() ?? '',
      items: _parseInt(json['items']),
      qty: _parseInt(json['qty']),
      value: _parseDouble(json['value']),
    );
  }
}
