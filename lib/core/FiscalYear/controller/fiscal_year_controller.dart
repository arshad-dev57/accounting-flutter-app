// core/FiscalYear/controller/fiscal_year_controller.dart

import 'package:flutter/material.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/FiscalYear/models/fiscal_year_model.dart';
import 'package:BisonsTechs_app/core/FiscalYear/screen/fiscal_year_list_screen.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_dates.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kSelectedFiscalYearStorageKey = 'selected_fiscal_year_id';

class FiscalYearController extends GetxController {
  var fiscalYears = <FiscalYear>[].obs;
  var isLoading = true.obs;
  var selectedFiscalYear = Rx<FiscalYear?>(null);
  var error = ''.obs;

  final ApiClient _api = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    fetchFiscalYears();
  }

  Future<void> fetchFiscalYears() async {
    try {
      isLoading(true);
      error.value = '';

      final response = await _api.get('/api/fiscal-year');

      if (response.success) {
        final data = response.data;
        final raw = data is Map ? (data['data'] ?? data) : data;
        final list = raw is List ? raw : <dynamic>[];
        final years = list
            .whereType<Map>()
            .map((e) => FiscalYear.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        years.sort((a, b) => b.startDate.compareTo(a.startDate));
        fiscalYears.value = years;
        await _reconcileSelection(years);
      } else {
        error.value = response.message.isNotEmpty
            ? response.message
            : 'Failed to load fiscal years';
        // Silent when logged out / no token — list loads after login
        if (response.statusCode != 401 && response.statusCode != 403) {
          AppSnackbar.error(kDanger, 'Error', error.value);
        }
      }
    } catch (e) {
      error.value = 'Failed to load fiscal years: $e';
    } finally {
      isLoading(false);
    }
  }

  Future<void> _reconcileSelection(List<FiscalYear> years) async {
    if (years.isEmpty) {
      selectedFiscalYear.value = null;
      await _persistSelectedId(null);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(kSelectedFiscalYearStorageKey);
    FiscalYear? chosen;

    if (storedId != null && storedId.isNotEmpty) {
      chosen = years.firstWhereOrNull((y) => y.id == storedId);
    }
    chosen ??= years.firstWhereOrNull((y) => y.isOpen) ?? years.first;

    if (selectedFiscalYear.value?.id == chosen.id) {
      await _persistSelectedId(chosen.id);
      return;
    }
    selectedFiscalYear.value = chosen;
    await _persistSelectedId(chosen.id);
  }

  Future<void> _persistSelectedId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(kSelectedFiscalYearStorageKey);
    } else {
      await prefs.setString(kSelectedFiscalYearStorageKey, id);
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
          'name': name.trim(),
          'startDate': fiscalDateOnly(startDate),
          'endDate': fiscalDateOnly(endDate),
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

        // Prefer selecting the newly created year
        final created = response.data is Map
            ? (response.data['data'] ?? response.data)
            : null;
        if (created is Map && created['id'] != null) {
          final match = fiscalYears.firstWhereOrNull(
            (y) => y.id == created['id'].toString(),
          );
          if (match != null) await selectFiscalYear(match);
        }
        return true;
      } else {
        if (response.isFiscalYearError) {
          _showFiscalYearErrorDialog(response.message);
        } else {
          AppSnackbar.error(
            kDanger,
            'Error',
            response.message.isNotEmpty
                ? response.message
                : 'Failed to create fiscal year',
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
          if (startDate != null) 'startDate': fiscalDateOnly(startDate),
          if (endDate != null) 'endDate': fiscalDateOnly(endDate),
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
          response.message.isNotEmpty
              ? response.message
              : 'Failed to update fiscal year',
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
          response.message.isNotEmpty
              ? response.message
              : 'Failed to close fiscal year',
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
          response.message.isNotEmpty
              ? response.message
              : 'Failed to reopen fiscal year',
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
          response.message.isNotEmpty
              ? response.message
              : 'Failed to delete fiscal year',
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

  Future<void> selectFiscalYear(FiscalYear? year) async {
    if (selectedFiscalYear.value?.id == year?.id) return;
    selectedFiscalYear.value = year;
    await _persistSelectedId(year?.id);
  }

  String? get selectedFiscalYearId => selectedFiscalYear.value?.id;

  /// Clear in-memory + stored selection (call on logout).
  Future<void> clearSession() async {
    fiscalYears.clear();
    selectedFiscalYear.value = null;
    error.value = '';
    await _persistSelectedId(null);
  }

  FiscalYearDateRange suggestNextRange(String periodKey) {
    return suggestNextFiscalRange(
      periodKey: periodKey,
      existingEndDates: fiscalYears.map((y) => y.endDate).toList(),
    );
  }

  String getFormattedDateRange(FiscalYear year) {
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(year.startDate)} - ${formatter.format(year.endDate)}';
  }

  bool isDateInSelectedFiscalYear(DateTime date) {
    if (selectedFiscalYear.value == null) return true;
    final year = selectedFiscalYear.value!;
    return !date.isBefore(DateTime(
          year.startDate.year,
          year.startDate.month,
          year.startDate.day,
        )) &&
        !date.isAfter(DateTime(
          year.endDate.year,
          year.endDate.month,
          year.endDate.day,
          23,
          59,
          59,
        ));
  }

  FiscalYear? getCurrentFiscalYear() {
    if (fiscalYears.isEmpty) return null;
    final today = DateTime.now();
    return fiscalYears.firstWhereOrNull(
          (y) =>
              !today.isBefore(y.startDate) && !today.isAfter(y.endDate),
        ) ??
        fiscalYears.firstWhereOrNull((y) => y.isOpen) ??
        fiscalYears.first;
  }

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
