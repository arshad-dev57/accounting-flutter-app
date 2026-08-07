import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransferController extends GetxController {
  var bankAccounts = <BankAccountForTransfer>[].obs;
  var fromAccountId = ''.obs;
  var toAccountId = ''.obs;
  var amount = 0.0.obs;
  var isLoading = true.obs;
  var isTransferring = false.obs;
  var selectedDate = DateTime.now().obs;
  var reference = ''.obs;
  var description = ''.obs;

  final ApiClient _api = Get.find<ApiClient>();

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  void onInit() {
    super.onInit();
    fetchBankAccounts();
  }

  Future<void> fetchBankAccounts() async {
    try {
      isLoading(true);
      final response = await _api.get('/api/bank-accounts');
      if (response.success) {
        bankAccounts.value = (response.data['data'] as List)
            .map((e) => BankAccountForTransfer.fromJson(e))
            .toList();
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to load bank accounts: $e');
    } finally {
      isLoading(false);
    }
  }

  void setFromAccount(String accountId) => fromAccountId.value = accountId;
  void setToAccount(String accountId) => toAccountId.value = accountId;
  void setAmount(String value) => amount.value = double.tryParse(value) ?? 0.0;
  void setDate(DateTime date) => selectedDate.value = date;
  void setReference(String value) => reference.value = value;
  void setDescription(String value) => description.value = value;

  BankAccountForTransfer? getFromAccount() {
    try {
      return bankAccounts.firstWhere((a) => a.id == fromAccountId.value);
    } catch (e) {
      return null;
    }
  }

  BankAccountForTransfer? getToAccount() {
    try {
      return bankAccounts.firstWhere((a) => a.id == toAccountId.value);
    } catch (e) {
      return null;
    }
  }

  bool get isAmountValid {
    final fromAccount = getFromAccount();
    if (fromAccount == null) return false;
    return amount.value > 0 && amount.value <= fromAccount.balance;
  }

  bool get canTransfer {
    return fromAccountId.value.isNotEmpty &&
        toAccountId.value.isNotEmpty &&
        fromAccountId.value != toAccountId.value &&
        isAmountValid;
  }

  Future<void> transfer() async {
    if (!canTransfer) {
      AppSnackbar.error(
        kWarning,
        'Cannot Transfer',
        'Please check: From Account, To Account, and Amount',
      );
      return;
    }

    try {
      isTransferring(true);

      final body = {
        'fromAccountId': fromAccountId.value,
        'toAccountId': toAccountId.value,
        'amount': amount.value,
        'date': selectedDate.value.toIso8601String(),
        'reference': reference.value,
        'description': description.value.isEmpty
            ? 'Transfer from ${getFromAccount()?.name} to ${getToAccount()?.name}'
            : description.value,
      };

      final response = await _api.post('/api/transfers', body: body);

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Success',
          response.message.isNotEmpty
              ? response.message
              : 'Transfer completed successfully!',
        );

        // Reset form
        fromAccountId.value = '';
        toAccountId.value = '';
        amount.value = 0;
        reference.value = '';
        description.value = '';

        await fetchBankAccounts();
        Get.back();
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.message.isNotEmpty ? response.message : 'Transfer failed',
        );
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Transfer failed: $e');
    } finally {
      isTransferring(false);
    }
  }

  void resetForm() {
    fromAccountId.value = '';
    toAccountId.value = '';
    amount.value = 0;
    selectedDate.value = DateTime.now();
    reference.value = '';
    description.value = '';
  }
}

class BankAccountForTransfer {
  final String id;
  final String name;
  final String number;
  final double balance;
  final String currency;
  final String color;

  BankAccountForTransfer({
    required this.id,
    required this.name,
    required this.number,
    required this.balance,
    required this.currency,
    required this.color,
  });

  factory BankAccountForTransfer.fromJson(Map<String, dynamic> json) {
    return BankAccountForTransfer(
      id: (json['id'] ?? json['_id']).toString(),
      name: json['accountName']?.toString() ?? '',
      number: json['accountNumber']?.toString() ?? '',
      balance: (json['currentBalance'] ?? 0).toDouble(),
      currency: json['currency']?.toString() ?? '\$',
      color: json['color']?.toString() ?? '#1AB4F5',
    );
  }
}
