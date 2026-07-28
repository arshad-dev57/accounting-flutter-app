// core/FiscalYear/controller/fiscal_year_controller.dart

import 'package:flutter/material.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/FiscalYear/models/fiscal_year_model.dart';
import 'package:LedgerPro_app/core/FiscalYear/screen/fiscal_year_list_screen.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class FiscalYearController extends GetxController {
  var fiscalYears = <FiscalYear>[].obs;
  var isLoading = true.obs;
  var selectedFiscalYear = Rx<FiscalYear?>(null);

  final ApiClient _api = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    fetchFiscalYears();
  }

  Future<void> fetchFiscalYears() async {
    try {
      isLoading(true);

      final response = await _api.get('/api/fiscal-year');

      if (response.success) {
        final data = response.data;
        final years = (data['data'] as List)
            .map((e) => FiscalYear.fromJson(e))
            .toList();

        fiscalYears.value = years;
        if (years.isNotEmpty && selectedFiscalYear.value == null) {
          final openYear = years.firstWhere(
            (y) => y.isOpen,
            orElse: () => years.first,
          );
          selectedFiscalYear.value = openYear;
        }
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to load fiscal years: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<bool> createFiscalYear({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? periodType,
  }) async {
    try {
      isLoading(true);

      final response = await _api.post(
        '/api/fiscal-year',
        body: {
          'name': name,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'periodType': periodType ?? 'Custom',
        },
      );

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Fiscal year created successfully',
        );
        await fetchFiscalYears();
        return true;
      } else {
        if (response.isFiscalYearError) {
          _showFiscalYearErrorDialog(response.message);
        } else {
          AppSnackbar.error(
            kDanger,
            'Error',
            response.message ?? 'Failed to create fiscal year',
          );
        }
        return false;
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to create fiscal year: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> updateFiscalYear({
    required String id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? periodType,
  }) async {
    try {
      isLoading(true);

      final response = await _api.put(
        '/api/fiscal-year/$id',
        body: {
          if (name != null) 'name': name,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (periodType != null) 'periodType': periodType,
        },
      );

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Fiscal year updated successfully',
        );
        await fetchFiscalYears();
        return true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message ?? 'Failed to update fiscal year',
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to update fiscal year: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> closeFiscalYear(String id) async {
    try {
      isLoading(true);

      final response = await _api.post('/api/fiscal-year/$id/close');

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Fiscal year closed successfully',
        );
        await fetchFiscalYears();
        return true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message ?? 'Failed to close fiscal year',
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to close fiscal year: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> reopenFiscalYear(String id) async {
    try {
      isLoading(true);

      final response = await _api.post('/api/fiscal-year/$id/reopen');

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Fiscal year reopened successfully',
        );
        await fetchFiscalYears();
        return true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message ?? 'Failed to reopen fiscal year',
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to reopen fiscal year: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  Future<bool> deleteFiscalYear(String id) async {
    try {
      isLoading(true);

      final response = await _api.delete('/api/fiscal-year/$id');

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          'Fiscal year deleted successfully',
        );
        await fetchFiscalYears();
        return true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message ?? 'Failed to delete fiscal year',
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to delete fiscal year: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }

  void selectFiscalYear(FiscalYear? year) {
    selectedFiscalYear.value = year;
  }

  String? get selectedFiscalYearId {
    return selectedFiscalYear.value?.id;
  }

  // Get formatted date range for display
  String getFormattedDateRange(FiscalYear year) {
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(year.startDate)} - ${formatter.format(year.endDate)}';
  }

  // Check if a date falls within the selected fiscal year
  bool isDateInSelectedFiscalYear(DateTime date) {
    if (selectedFiscalYear.value == null) return true;
    final year = selectedFiscalYear.value!;
    return date.isAfter(year.startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(year.endDate.add(const Duration(days: 1)));
  }

  // Get current fiscal year based on today's date
  FiscalYear? getCurrentFiscalYear() {
    final today = DateTime.now();
    return fiscalYears.firstWhere(
      (y) =>
          today.isAfter(y.startDate.subtract(const Duration(days: 1))) &&
          today.isBefore(y.endDate.add(const Duration(days: 1))),
      orElse: () => fiscalYears.firstWhere(
        (y) => y.isOpen,
        orElse: () => fiscalYears.isNotEmpty
            ? fiscalYears.first
            : FiscalYear(
                id: '',
                userId: '',
                name: 'No Fiscal Year',
                startDate: DateTime.now(),
                endDate: DateTime.now(),
                status: 'Open',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
      ),
    );
  }

  // Show fiscal year error dialog
  void _showFiscalYearErrorDialog(String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: kDanger),
            const SizedBox(width: 8),
            const Text('Fiscal Year Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => const FiscalYearListScreen());
            },
            child: const Text('Manage Fiscal Years'),
          ),
        ],
      ),
    );
  }
}
