// lib/core/warehouse/reports/controller/reports_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/warehouse/dashboard/warehouse_dashboard_controller.dart';

class ReportsController extends GetxController {
  final RxBool isLoading = false.obs;
  final WarehouseDashboardController _dashboardController =
      Get.find<WarehouseDashboardController>();

  // Reports List - 3 reports
  final List<Map<String, dynamic>> reports = [
    {
      'title': 'Stock Summary Report',
      'subtitle': 'Current stock levels with values',
      'icon': Icons.inventory_2_outlined,
      'color': const Color(0xFF3498DB),
      'route': '/stock-summary-report',
      'index': 0,
    },
    {
      'title': 'Low Stock Report',
      'subtitle': 'Products below minimum level',
      'icon': Icons.warning_amber_outlined,
      'color': const Color(0xFFF39C12),
      'route': '/low-stock-report',
      'index': 1,
    },
    {
      'title': 'Expiry Report',
      'subtitle': 'Products expiring soon',
      'icon': Icons.event_outlined,
      'color': const Color(0xFFE74C3C),
      'route': '/expiry-report',
      'index': 2,
    },
  ];

  // Recently Viewed
  final RxList<Map<String, dynamic>> recentReports =
      <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    recentReports.addAll([
      {
        'title': 'Stock Summary Report',
        'icon': Icons.inventory_2_outlined,
        'color': const Color(0xFF3498DB),
        'route': '/stock-summary-report',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'index': 0,
      },
      {
        'title': 'Low Stock Report',
        'icon': Icons.warning_amber_outlined,
        'color': const Color(0xFFF39C12),
        'route': '/low-stock-report',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'index': 1,
      },
    ]);

    isLoading.value = false;
  }

  void navigateToReport(Map<String, dynamic> report) {
    final index = report['index'] as int?;
    if (index != null) {
      _addToRecent(report);
      _dashboardController.navigateToReportDetail(index);
    } else {
      Get.snackbar(
        'Coming Soon',
        '${report['title']} will be available soon',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kPrimary,
        colorText: Colors.black,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _addToRecent(Map<String, dynamic> report) {
    recentReports.removeWhere((r) => r['route'] == report['route']);
    recentReports.insert(0, {
      'title': report['title'],
      'icon': report['icon'],
      'color': report['color'],
      'route': report['route'],
      'date': DateTime.now(),
      'index': report['index'],
    });
    if (recentReports.length > 5) {
      recentReports.removeLast();
    }
  }
}
