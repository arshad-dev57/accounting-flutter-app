import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_query.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/Sales/model/sales_credit_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SalesCreditController extends GetxController {
  final ApiClient _api = Get.find<ApiClient>();

  final RxList<SalesCredit> credits = <SalesCredit>[].obs;
  final RxList<SalesCredit> filteredCredits = <SalesCredit>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showCreateForm = false.obs;
  final RxBool showApplyForm = false.obs;
  final Rx<SalesCredit?> selectedCredit = Rx<SalesCredit?>(null);
  final Rx<SalesCreditSummary> summary = SalesCreditSummary().obs;

  final RxString searchFilter = ''.obs;
  final RxString selectedFilter = 'all'.obs;

  static const reasonTypes = [
    'Return',
    'Refund',
    'Discount',
    'Price Adjustment',
    'Damaged Goods',
  ];

  final List<String> filters = [
    'all',
    'Issued',
    'PartiallyApplied',
    'Applied',
    'Voided',
    'Expired',
  ];

  // ─── Create form ─────────────────────────────────────────────
  final Rx<Map<String, dynamic>?> selectedCustomer =
      Rx<Map<String, dynamic>?>(null);
  final RxList<Map<String, dynamic>> customerSearchResults =
      <Map<String, dynamic>>[].obs;
  final RxBool isSearchingCustomers = false.obs;
  final RxList<SalesCreditInvoice> availableInvoices =
      <SalesCreditInvoice>[].obs;
  final Rx<SalesCreditInvoice?> selectedInvoice = Rx<SalesCreditInvoice?>(null);
  final RxBool isLoadingInvoices = false.obs;
  final RxString reasonType = 'Return'.obs;
  final RxList<SalesCreditLineItem> lineItems = <SalesCreditLineItem>[].obs;

  final customerSearchController = TextEditingController();
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  final notesController = TextEditingController();
  final applyAmountController = TextEditingController();

  // ─── Apply form ──────────────────────────────────────────────
  final RxList<SalesCreditInvoice> applyInvoices = <SalesCreditInvoice>[].obs;
  final Rx<SalesCreditInvoice?> applyInvoice = Rx<SalesCreditInvoice?>(null);
  final RxBool isLoadingApplyInvoices = false.obs;

  Worker? _fyWorker;

  @override
  void onInit() {
    super.onInit();
    Future(() async {
      await waitForFiscalYearReady();
      fetchCredits();
      fetchSummary();
    });
    _fyWorker = listenFiscalYearChanges(() {
      fetchCredits();
      fetchSummary();
    });
  }

  @override
  void onClose() {
    _fyWorker?.dispose();
    try {
      customerSearchController.dispose();
      amountController.dispose();
      reasonController.dispose();
      notesController.dispose();
      applyAmountController.dispose();
    } catch (_) {}
    super.onClose();
  }

  String formatCurrency(double v) {
    if (Get.isRegistered<CurrencyController>()) {
      return Get.find<CurrencyController>().formatAmount(v);
    }
    return v.toStringAsFixed(2);
  }

  bool get canCreateCredit {
    final amt = double.tryParse(amountController.text) ?? 0;
    return selectedCustomer.value != null &&
        selectedInvoice.value != null &&
        amt > 0 &&
        reasonController.text.trim().isNotEmpty;
  }

  bool get canApplyCredit {
    final amt = double.tryParse(applyAmountController.text) ?? 0;
    final credit = selectedCredit.value;
    final inv = applyInvoice.value;
    if (credit == null || inv == null || amt <= 0) return false;
    return amt <= credit.remainingAmount && amt <= inv.outstanding;
  }

  // ═══════════════════════════════════════════════════════════════
  // LIST
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchCredits() async {
    try {
      isLoading.value = true;
      final params = <String, String>{};
      if (searchFilter.value.isNotEmpty) {
        params['search'] = searchFilter.value;
      }
      if (selectedFilter.value != 'all') {
        params['status'] = selectedFilter.value;
      }
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final path =
          query.isEmpty ? '/api/credit-notes' : '/api/credit-notes?$query';

      final response = await _api.get(path, requiresAuth: true);
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ??
            response.data['creditNotes'] as List? ??
            [];
        credits.value = list
            .map((e) => SalesCredit.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        applyLocalFilters();
      } else {
        Get.snackbar('Error', response.message ?? 'Failed to load credits');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSummary() async {
    try {
      final response =
          await _api.get('/api/credit-notes/summary', requiresAuth: true);
      if (response.success && response.data != null) {
        final data = response.data['data'] ?? response.data;
        summary.value =
            SalesCreditSummary.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
  }

  void applyLocalFilters() {
    final q = searchFilter.value.toLowerCase();
    filteredCredits.value = credits.where((c) {
      if (selectedFilter.value != 'all' && c.status != selectedFilter.value) {
        return false;
      }
      if (q.isEmpty) return true;
      return c.creditNumber.toLowerCase().contains(q) ||
          c.customerName.toLowerCase().contains(q) ||
          c.originalInvoiceNumber.toLowerCase().contains(q);
    }).toList();
  }

  void filterCredits(String status) {
    selectedFilter.value = status;
    applyLocalFilters();
  }

  void onSearchChanged(String value) {
    searchFilter.value = value;
    applyLocalFilters();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchCredits(), fetchSummary()]);
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE FORM
  // ═══════════════════════════════════════════════════════════════

  void openCreateForm() {
    _resetCreateForm();
    showCreateForm.value = true;
  }

  void closeCreateForm() {
    showCreateForm.value = false;
    _resetCreateForm();
  }

  void _resetCreateForm() {
    selectedCustomer.value = null;
    customerSearchResults.clear();
    availableInvoices.clear();
    selectedInvoice.value = null;
    lineItems.clear();
    reasonType.value = 'Return';
    customerSearchController.clear();
    amountController.clear();
    reasonController.clear();
    notesController.clear();
  }

  Future<void> searchCustomers(String query) async {
    if (query.trim().length < 2) {
      customerSearchResults.clear();
      return;
    }
    try {
      isSearchingCustomers.value = true;
      final encoded = Uri.encodeComponent(query.trim());
      final response = await _api.get(
        '/api/warehouse/customers?search=$encoded&limit=10',
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        customerSearchResults.value =
            list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        customerSearchResults.clear();
      }
    } catch (_) {
      customerSearchResults.clear();
    } finally {
      isSearchingCustomers.value = false;
    }
  }

  void selectCustomer(Map<String, dynamic> customer) {
    selectedCustomer.value = customer;
    customerSearchResults.clear();
    customerSearchController.text = customer['name']?.toString() ?? '';
    selectedInvoice.value = null;
    lineItems.clear();
    amountController.clear();
    availableInvoices.clear();
    final id = customer['id']?.toString() ??
        customer['_id']?.toString() ??
        '';
    fetchInvoicesForCreate(id);
  }

  Future<void> fetchInvoicesForCreate(String customerId) async {
    if (customerId.isEmpty) {
      Get.snackbar('Error', 'Customer id missing');
      return;
    }
    try {
      isLoadingInvoices.value = true;
      // Sales Credits uses Sales Invoices only (same pool as Sales Payments)
      final response = await _api.get(
        '/api/credit-notes/unpaid-invoices/$customerId?purpose=create&source=sales',
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        availableInvoices.value = list
            .map(
              (e) => SalesCreditInvoice.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
        if (availableInvoices.isEmpty) {
          Get.snackbar(
            'No invoices',
            'No unpaid sales invoices for this customer (same as Payments).',
          );
        }
      } else {
        availableInvoices.clear();
        Get.snackbar(
          'Error',
          response.data?['message']?.toString() ??
              response.message ??
              'Failed to load sales invoices',
        );
      }
    } catch (e) {
      availableInvoices.clear();
      Get.snackbar('Error', e.toString());
    } finally {
      isLoadingInvoices.value = false;
    }
  }

  void selectInvoice(SalesCreditInvoice invoice) {
    selectedInvoice.value = invoice;
    lineItems.value = invoice.items
        .map(
          (i) => SalesCreditLineItem(
            id: i.id,
            productId: i.productId,
            productName: i.productName,
            quantity: i.quantity,
            unitPrice: i.unitPrice,
            totalPrice: i.totalPrice,
            returnQty: 0,
          ),
        )
        .toList();
    // Default to full eligible credit for non-return types
    amountController.text = invoice.eligibleCredit.toStringAsFixed(2);
  }

  void setReturnQty(int index, int qty) {
    if (index < 0 || index >= lineItems.length) return;
    final item = lineItems[index];
    final capped = qty.clamp(0, item.quantity);
    lineItems[index] = SalesCreditLineItem(
      id: item.id,
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.totalPrice,
      returnQty: capped,
    );
    lineItems.refresh();
    if (['Return', 'Damaged Goods'].contains(reasonType.value)) {
      final total = lineItems.fold<double>(0, (s, i) => s + i.lineCredit);
      final max = selectedInvoice.value?.eligibleCredit ?? total;
      amountController.text = total.clamp(0, max).toStringAsFixed(2);
    }
  }

  void onReasonTypeChanged(String type) {
    reasonType.value = type;
    final inv = selectedInvoice.value;
    if (inv == null) return;
    if (['Return', 'Damaged Goods'].contains(type)) {
      final total = lineItems.fold<double>(0, (s, i) => s + i.lineCredit);
      if (total > 0) {
        amountController.text =
            total.clamp(0, inv.eligibleCredit).toStringAsFixed(2);
      }
    } else {
      amountController.text = inv.eligibleCredit.toStringAsFixed(2);
    }
  }

  Future<bool> createCredit() async {
    final customer = selectedCustomer.value;
    final invoice = selectedInvoice.value;
    if (customer == null || invoice == null) {
      Get.snackbar('Validation', 'Select a customer and invoice');
      return false;
    }

    final amount = double.tryParse(amountController.text) ?? 0;
    if (amount <= 0) {
      Get.snackbar('Validation', 'Enter a valid credit amount');
      return false;
    }
    if (amount > invoice.eligibleCredit) {
      Get.snackbar(
        'Validation',
        'Amount exceeds eligible credit (${formatCurrency(invoice.eligibleCredit)})',
      );
      return false;
    }
    if (reasonController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Enter a reason');
      return false;
    }

    List<Map<String, dynamic>> items = [];
    if (['Return', 'Damaged Goods'].contains(reasonType.value)) {
      items = lineItems
          .where((i) => i.returnQty > 0)
          .map(
            (i) => {
              'productId': i.productId,
              'productName': i.productName,
              'quantity': i.returnQty,
              'unitPrice': i.unitPrice,
              'amount': i.lineCredit,
            },
          )
          .toList();
      if (items.isEmpty) {
        Get.snackbar('Validation', 'Select return quantities for line items');
        return false;
      }
    } else {
      items = [
        {
          'productName': 'Sales credit — ${invoice.invoiceNumber}',
          'quantity': 1,
          'unitPrice': amount,
          'amount': amount,
        },
      ];
    }

    try {
      isSubmitting.value = true;
      final body = {
        'customerId': customer['id'],
        'originalInvoiceId': invoice.id,
        'amount': amount,
        'reason': reasonController.text.trim(),
        'reasonType': reasonType.value,
        'items': items,
        'notes': notesController.text.trim(),
        'expiryDays': 30,
      };

      final response = await _api.post('/api/credit-notes', body: body);
      if (response.success &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        Get.snackbar('Success', 'Sales credit created — posted to AR & GL');
        closeCreateForm();
        await refreshAll();
        return true;
      }
      Get.snackbar(
        'Error',
        response.data?['message']?.toString() ??
            response.message ??
            'Failed to create credit',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // APPLY FORM
  // ═══════════════════════════════════════════════════════════════

  Future<void> openApplyForm(SalesCredit credit) async {
    selectedCredit.value = credit;
    applyInvoice.value = null;
    applyInvoices.clear();
    applyAmountController.clear();
    showApplyForm.value = true;
    await fetchInvoicesForApply(credit.customerId);
  }

  void closeApplyForm() {
    showApplyForm.value = false;
    selectedCredit.value = null;
    applyInvoice.value = null;
    applyInvoices.clear();
    applyAmountController.clear();
  }

  Future<void> fetchInvoicesForApply(String customerId) async {
    try {
      isLoadingApplyInvoices.value = true;
      final response = await _api.get(
        '/api/credit-notes/unpaid-invoices/$customerId?purpose=apply&source=sales',
        requiresAuth: true,
      );
      if (response.success && response.data != null) {
        final list = response.data['data'] as List? ?? [];
        applyInvoices.value = list
            .map(
              (e) => SalesCreditInvoice.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      } else {
        applyInvoices.clear();
      }
    } catch (_) {
      applyInvoices.clear();
    } finally {
      isLoadingApplyInvoices.value = false;
    }
  }

  void selectApplyInvoice(SalesCreditInvoice invoice) {
    applyInvoice.value = invoice;
    final credit = selectedCredit.value;
    if (credit == null) return;
    final max = invoice.outstanding < credit.remainingAmount
        ? invoice.outstanding
        : credit.remainingAmount;
    applyAmountController.text = max.toStringAsFixed(2);
  }

  Future<bool> applyCredit() async {
    final credit = selectedCredit.value;
    final invoice = applyInvoice.value;
    if (credit == null || invoice == null) {
      Get.snackbar('Validation', 'Select an invoice to apply');
      return false;
    }
    final amount = double.tryParse(applyAmountController.text) ?? 0;
    if (amount <= 0) {
      Get.snackbar('Validation', 'Enter a valid amount');
      return false;
    }

    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/credit-notes/apply',
        body: {
          'creditNoteId': credit.id,
          'invoiceId': invoice.id,
          'amount': amount,
        },
      );
      if (response.success) {
        Get.snackbar('Success', 'Credit applied to ${invoice.invoiceNumber}');
        closeApplyForm();
        await refreshAll();
        return true;
      }
      Get.snackbar(
        'Error',
        response.data?['message']?.toString() ??
            response.message ??
            'Failed to apply credit',
      );
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> voidCredit(SalesCredit credit) async {
    try {
      isSubmitting.value = true;
      final response = await _api.post(
        '/api/credit-notes/${credit.id}/void',
        body: {},
      );
      if (response.success) {
        Get.snackbar('Success', 'Credit voided');
        await refreshAll();
      } else {
        Get.snackbar(
          'Error',
          response.data?['message']?.toString() ??
              response.message ??
              'Failed to void',
        );
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }
}
