import 'dart:convert';

import 'package:BisonsTechs_app/Utils/currency_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class DashboardController extends GetxController {
  var isLoading = true.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  var totalRevenue = 0.0.obs;
  var totalRevenueFormatted = ''.obs;
  var revenueChange = 0.0.obs;
  var isRevenuePositive = true.obs;

  var totalExpenses = 0.0.obs;
  var totalExpensesFormatted = ''.obs;
  var expenseChange = 0.0.obs;
  var isExpensePositive = false.obs;

  var outstanding = 0.0.obs;
  var outstandingFormatted = ''.obs;
  var outstandingChange = 0.0.obs;
  var outstandingCount = 0.obs;

  var payables = 0.0.obs;
  var payablesFormatted = ''.obs;
  var payablesCount = 0.obs;

  var cashBalance = 0.0.obs;
  var cashBalanceFormatted = ''.obs;
  var cashChange = 0.0.obs;
  var isCashPositive = true.obs;

  var weeklyRevenue = 0.0.obs;
  var weeklyExpenses = 0.0.obs;
  var weeklyProfit = 0.0.obs;

  var dailyRevenue = 0.0.obs;
  var dailyExpenses = 0.0.obs;
  var dailyProfit = 0.0.obs;
  var companyName = ''.obs;
  var userEmail = ''.obs;
  final RxString businessLogo = ''.obs;

  var currentRoute = 'dashboard'.obs;
  var currentScreen = Rx<Widget?>(null);

  void navigateTo(Widget screen, {String route = 'dashboard'}) {
    currentScreen.value = screen;
    currentRoute.value = route;
  }

  bool isActive(String route) {
    return currentRoute.value == route;
  }

  var chartData = <Map<String, dynamic>>[].obs;
  var expenseCategories = <Map<String, dynamic>>[].obs;
  var recentTransactions = <Map<String, dynamic>>[].obs;
  var quickActions = <Map<String, dynamic>>[].obs;

  var revenueIncomeModule = 0.0.obs;
  var revenueInvoiceTotal = 0.0.obs;
  var revenueCreditNotes = 0.0.obs;

  var totalSales = 0.0.obs;
  var totalSalesFormatted = ''.obs;
  var salesChange = 0.0.obs;
  var isSalesPositive = true.obs;
  var salesCount = 0.obs;

  var totalPurchases = 0.0.obs;
  var totalPurchasesFormatted = ''.obs;
  var purchaseCount = 0.obs;

  var totalBankBalance = 0.0.obs;
  var totalBankBalanceFormatted = ''.obs;
  var bankAccountsCount = 0.obs;

  var totalCashBalance = 0.0.obs;
  var totalCashBalanceFormatted = ''.obs;
  var cashAccountsCount = 0.obs;

  var grossProfit = 0.0.obs;
  var grossProfitFormatted = ''.obs;
  var netProfit = 0.0.obs;
  var netProfitFormatted = ''.obs;
  var profitMargin = 0.0.obs;
  var profitChange = 0.0.obs;
  var isProfitPositive = true.obs;

  var salesOrdersCount = 0.obs;
  var purchaseOrdersCount = 0.obs;

  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final ApiClient _api = Get.find<ApiClient>();

  var selectedTimePeriod = 'Today'.obs;
  final Rx<DateTime?> customStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> customEndDate = Rx<DateTime?>(null);
  bool _subscriptionWatchStarted = false;

  static const timePeriodLabels = [
    'Today',
    'Last Week',
    'This Month',
    'Last Month',
    'This Quarter',
    'This Year',
    'Custom',
  ];

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    loadBusinessLogo();
    loadDashboardData();
    ensureSubscriptionWatch();
  }

  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      companyName.value = prefs.getString('company_name') ?? '';
      userEmail.value = prefs.getString('user_email') ?? '';
      if (companyName.value.isEmpty && userEmail.value.isNotEmpty) {
        companyName.value = userEmail.value.split('@')[0];
      }
      if (companyName.value.isEmpty) {
        companyName.value = 'User';
      }
    } catch (e) {
      companyName.value = 'User';
      userEmail.value = '';
    }
  }

  Future<void> loadBusinessLogo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null) {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        final businessDetails =
            userData['businessDetails'] as Map<String, dynamic>?;

        if (businessDetails != null && businessDetails['logo'] != null) {
          final logo = businessDetails['logo'] as String;
          if (logo.isNotEmpty) {
            businessLogo.value = logo;
          }
        }
      }
    } catch (e) {
      print('❌ [DashboardController] Error loading business logo: $e');
    }
  }

  void ensureSubscriptionWatch() {
    if (_subscriptionWatchStarted) return;
    _subscriptionWatchStarted = true;
    Future.delayed(const Duration(seconds: 2), _subscriptionCheckLoop);
  }

  Future<void> _subscriptionCheckLoop() async {
    if (isClosed) return;
    try {
      if (!Get.isRegistered<SubscriptionController>()) return;
      final sub = Get.find<SubscriptionController>();
      await sub.checkSubscriptionStatus();
      if (!sub.hasActiveSubscription.value &&
          sub.subscriptionStatus.value == 'expired') {
        _showExpiredDialog(sub);
      }
    } catch (_) {}
    if (isClosed) return;
    Future.delayed(const Duration(minutes: 5), _subscriptionCheckLoop);
  }

  void _showExpiredDialog(SubscriptionController sub) {
    final ctx = Get.context;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Subscription expired'),
        content: Text(
          sub.trialDaysRemaining.value > 0
              ? 'Your free trial has ended. Subscribe to continue.'
              : 'Your subscription has expired. Renew to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Get.to(() => const SelectPlanScreen());
            },
            child: const Text('Subscribe now'),
          ),
        ],
      ),
    );
  }

  Future<void> loadDashboardData({
    String? timePeriod,
    DateTime? customStart,
    DateTime? customEnd,
  }) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      if (timePeriod != null && timePeriod.isNotEmpty) {
        selectedTimePeriod.value = timePeriod;
      }

      if (selectedTimePeriod.value == 'Custom') {
        if (customStart != null) customStartDate.value = customStart;
        if (customEnd != null) customEndDate.value = customEnd;
      } else if (timePeriod != null) {
        customStartDate.value = null;
        customEndDate.value = null;
      }

      await loadOverview();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load dashboard data: $e';
      _showError(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, String> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;

      case 'Last Week':
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        break;

      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;

      case 'Last Month':
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        startDate = DateTime(lastMonthYear, lastMonth, 1);
        endDate = DateTime(lastMonthYear, lastMonth + 1, 0, 23, 59, 59);
        break;

      case 'This Quarter':
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterMonth, 1);
        endDate = DateTime(now.year, quarterMonth + 3, 0, 23, 59, 59);
        break;

      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;

      case 'Custom':
        startDate = customStartDate.value ?? DateTime(now.year, now.month, 1);
        final end =
            customEndDate.value ?? DateTime(now.year, now.month, now.day);
        endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
        break;

      default:
        startDate = DateTime(now.year, now.month, now.day);
        break;
    }

    return {
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate),
    };
  }

  String get periodLabel {
    if (selectedTimePeriod.value == 'Custom' &&
        customStartDate.value != null &&
        customEndDate.value != null) {
      final s = customStartDate.value!;
      final e = customEndDate.value!;
      return '${DateFormat('dd MMM').format(s)} – ${DateFormat('dd MMM').format(e)}';
    }
    return selectedTimePeriod.value;
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  /// Single API: KPIs + charts + categories + recent txns for the selected period.
  Future<void> loadOverview() async {
    final params = <String, String>{
      'timePeriod': selectedTimePeriod.value,
      'limit': '10',
    };

    // Only Custom needs client dates — named periods are resolved on the backend.
    if (selectedTimePeriod.value == 'Custom') {
      final dateRange = _getDateRangeForPeriod('Custom');
      params['startDate'] = dateRange['startDate'] ?? '';
      params['endDate'] = dateRange['endDate'] ?? '';
    }

    print(
      '🔵 [Dashboard] overview period=${selectedTimePeriod.value} '
      'params=$params',
    );

    final response = await _api.get(
      '/api/dashboard/overview',
      queryParameters: params,
    );

    if (response.statusCode == 403) {
      final data = response.data;
      final message = data is Map
          ? (data['message']?.toString() ??
                'Subscription required. Please subscribe to access this feature.')
          : 'Subscription required. Please subscribe to access this feature.';
      hasError.value = true;
      errorMessage.value = message;
      return;
    }

    if (!response.success) {
      hasError.value = true;
      errorMessage.value = response.message.isNotEmpty
          ? response.message
          : 'Server error: ${response.statusCode}';
      _showError(errorMessage.value);
      return;
    }

    final root = response.data;
    final dataObj = (root is Map ? root['data'] : null) ?? {};
    if (dataObj is! Map) {
      hasError.value = true;
      errorMessage.value = 'Invalid dashboard response';
      return;
    }

    _applyKpi(dataObj);
    _applyCharts(dataObj);
    _applyExpenseCategories(dataObj);
    _applyRecentTransactions(dataObj);
  }

  void _applyKpi(Map dataObj) {
    final kpi = dataObj['kpi'] ?? {};

    final totalRevenueData = kpi['totalRevenue'] ?? {};
    totalRevenue.value = _asDouble(totalRevenueData['amount']);
    totalRevenueFormatted.value = formatAmount(totalRevenue.value);
    revenueChange.value = _asDouble(totalRevenueData['change']);
    isRevenuePositive.value = totalRevenueData['isPositive'] ?? true;

    final revenueSources = totalRevenueData['sources'] ?? {};
    if (revenueSources is Map) {
      revenueIncomeModule.value = _asDouble(revenueSources['incomeModule']);
      revenueInvoiceTotal.value = _asDouble(revenueSources['salesModule']);
      revenueCreditNotes.value = _asDouble(revenueSources['creditNotes']);
    } else {
      final breakdown = dataObj['breakdown'] ?? {};
      revenueIncomeModule.value = _asDouble(breakdown['otherIncome']);
      revenueInvoiceTotal.value = _asDouble(breakdown['salesRevenue']);
      revenueCreditNotes.value = _asDouble(breakdown['creditNotes']);
    }

    final totalSalesData = kpi['totalSales'] ?? {};
    totalSales.value = _asDouble(
      totalSalesData['amount'] ?? revenueInvoiceTotal.value,
    );
    totalSalesFormatted.value = formatAmount(totalSales.value);
    salesChange.value = _asDouble(totalSalesData['change']);
    isSalesPositive.value = totalSalesData['isPositive'] ?? true;
    salesCount.value = _asInt(totalSalesData['count']);

    final totalPurchasesData = kpi['totalPurchases'] ?? {};
    totalPurchases.value = _asDouble(totalPurchasesData['amount']);
    totalPurchasesFormatted.value = formatAmount(totalPurchases.value);

    final totalExpensesData = kpi['totalExpenses'] ?? {};
    totalExpenses.value = _asDouble(totalExpensesData['amount']);
    totalExpensesFormatted.value = formatAmount(totalExpenses.value);
    expenseChange.value = _asDouble(totalExpensesData['change']);
    isExpensePositive.value = totalExpensesData['isPositive'] ?? false;

    final netProfitData = kpi['netProfit'] ?? {};
    if (netProfitData is Map && netProfitData.isNotEmpty) {
      netProfit.value = _asDouble(netProfitData['amount']);
      profitMargin.value = _asDouble(netProfitData['margin']);
      profitChange.value = _asDouble(netProfitData['change']);
      isProfitPositive.value =
          netProfitData['isPositive'] ?? (netProfit.value >= 0);
    } else {
      netProfit.value =
          totalRevenue.value - totalExpenses.value;
      profitMargin.value = totalRevenue.value > 0
          ? (netProfit.value / totalRevenue.value) * 100
          : 0.0;
      profitChange.value = 0.0;
      isProfitPositive.value = netProfit.value >= 0;
    }
    netProfitFormatted.value = formatAmount(netProfit.value);

    final grossProfitData = kpi['grossProfit'] ?? {};
    if (grossProfitData is Map && grossProfitData.isNotEmpty) {
      grossProfit.value = _asDouble(grossProfitData['amount']);
    } else {
      grossProfit.value = totalSales.value - totalPurchases.value;
    }
    grossProfitFormatted.value = formatAmount(grossProfit.value);

    final outstandingData =
        kpi['accountsReceivable'] ?? kpi['outstanding'] ?? {};
    outstanding.value = _asDouble(outstandingData['amount']);
    outstandingFormatted.value = formatAmount(outstanding.value);
    outstandingChange.value = _asDouble(outstandingData['change']);
    outstandingCount.value = _asInt(outstandingData['count']);

    final payablesData = kpi['accountsPayable'] ?? {};
    payables.value = _asDouble(payablesData['amount']);
    payablesFormatted.value = formatAmount(payables.value);
    payablesCount.value = _asInt(payablesData['count']);

    final bankData = kpi['bankBalance'] ?? kpi['cashBalance'] ?? {};
    totalBankBalance.value = _asDouble(bankData['amount']);
    totalBankBalanceFormatted.value = formatAmount(totalBankBalance.value);
    bankAccountsCount.value = _asInt(
      bankData['accountsCount'] ??
          (dataObj['breakdown'] is Map
              ? dataObj['breakdown']['bankAccountsCount']
              : 0),
    );
    cashBalance.value = totalBankBalance.value;
    cashBalanceFormatted.value = totalBankBalanceFormatted.value;
    cashChange.value = _asDouble(bankData['change']);
    isCashPositive.value = bankData['isPositive'] ?? true;

    final cashOnly = _asDouble(
      (kpi['cashBalance'] is Map) ? (kpi['cashBalance']['cashOnly']) : null,
    );
    totalCashBalance.value = cashOnly;
    totalCashBalanceFormatted.value = formatAmount(totalCashBalance.value);

    final weeklyData = dataObj['weeklyData'] ?? {};
    weeklyRevenue.value = _asDouble(weeklyData['revenue']);
    weeklyExpenses.value = _asDouble(weeklyData['expenses']);
    weeklyProfit.value = _asDouble(weeklyData['profit']);

    final dailyData = dataObj['dailyData'] ?? {};
    dailyRevenue.value = _asDouble(dailyData['revenue']);
    dailyExpenses.value = _asDouble(dailyData['expenses']);
    dailyProfit.value = _asDouble(dailyData['profit']);
  }

  void _applyCharts(Map dataObj) {
    final dataList = dataObj['chartData'];
    if (dataList is List) {
      chartData.value = List<Map<String, dynamic>>.from(
        dataList.map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } else {
      chartData.clear();
    }
  }

  void _applyExpenseCategories(Map dataObj) {
    final dataList = dataObj['expenseCategories'];
    if (dataList is List) {
      expenseCategories.value = List<Map<String, dynamic>>.from(
        dataList.map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } else {
      expenseCategories.clear();
    }
  }

  void _applyRecentTransactions(Map dataObj) {
    final dataList = dataObj['recentTransactions'];
    if (dataList is List) {
      recentTransactions.value = List<Map<String, dynamic>>.from(
        dataList.map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } else {
      recentTransactions.clear();
    }
  }

  void _showSubscriptionRequiredDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.w)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 6.w),
            SizedBox(width: 2.w),
            Text(
              'Subscription Required',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.to(() => SelectPlanScreen());
            },
            child: Text(
              'Subscribe Now',
              style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  double getMonthlyRevenue(int monthIndex) {
    if (monthIndex < chartData.length) {
      return _asDouble(chartData[monthIndex]['revenue']);
    }
    return 0;
  }

  double getMonthlyExpenses(int monthIndex) {
    if (monthIndex < chartData.length) {
      return _asDouble(chartData[monthIndex]['expenses']);
    }
    return 0;
  }

  String getMonthName(int monthIndex) {
    if (monthIndex < chartData.length &&
        chartData[monthIndex]['month'] != null) {
      return chartData[monthIndex]['month']?.toString() ??
          months[monthIndex % months.length];
    }
    return months[monthIndex % months.length];
  }

  IconData getIconFromName(String iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'payment':
        return Icons.payment;
      case 'bolt':
        return Icons.bolt;
      case 'computer':
        return Icons.computer;
      case 'work':
        return Icons.work;
      case 'add_circle_outline':
        return Icons.add_circle_outline;
      case 'remove_circle_outline':
        return Icons.remove_circle_outline;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'person_add':
        return Icons.person_add;
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.circle;
    }
  }

  Color getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  String formatAmount(double amount) => CurrencyUtils.format(amount);

  String formatTrend(double change, {bool invertSense = false}) {
    final abs = change.abs().toStringAsFixed(1);
    if (change > 0) return '+$abs%';
    if (change < 0) return '−$abs%';
    return '0%';
  }

  void refreshData() {
    loadDashboardData();
  }

  void _showError(String message) {
    AppSnackbar.error(
      kDanger,
      'Error',
      message,
      duration: const Duration(seconds: 3),
    );
  }
}
