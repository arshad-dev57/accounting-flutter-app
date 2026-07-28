import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'dart:convert';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/plans/views/Subscription_plans.dart';
import 'package:LedgerPro_app/core/BankAccounts/controllers/bankaccount_controller.dart';
import 'package:LedgerPro_app/core/Invoice/controller/invoice_controller.dart';
import 'package:LedgerPro_app/core/purchaseInvoice/purchase_invoice_controller.dart';
import 'package:LedgerPro_app/core/Expense/controller/expense_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
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

  var currentRoute = 'dashboard'.obs;
  var currentScreen = Rx<Widget?>(null);

  void navigateTo(Widget screen, {String route = 'dashboard'}) {
    print('🖱️ Navigating to: $route');
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

  // Additional financial data
  var totalSales = 0.0.obs;
  var totalSalesFormatted = ''.obs;
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
  late final BankAccountController _bankAccountController;
  late final InvoiceController _invoiceController;
  late final PurchaseInvoiceController _purchaseInvoiceController;
  late final ExpenseController _expenseController;

  // Time period for data filtering
  var selectedTimePeriod = 'This Month'.obs;

  @override
  void onInit() {
    super.onInit();
    _bankAccountController = Get.put(BankAccountController());
    _invoiceController = Get.put(InvoiceController());
    _purchaseInvoiceController = Get.put(PurchaseInvoiceController());
    _expenseController = Get.put(ExpenseController());
    loadDashboardData();
    loadUserData();
    loadFinancialData();
  }

  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      companyName.value = prefs.getString('company_name') ?? '';
      userEmail.value = prefs.getString('user_email') ?? '';
      print("Company Name: ${companyName.value}");
      print("User Email: ${userEmail.value}");
      if (companyName.value.isEmpty && userEmail.value.isNotEmpty) {
        companyName.value = userEmail.value.split('@')[0];
      }
      if (companyName.value.isEmpty) {
        companyName.value = 'User';
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      companyName.value = 'User';
      userEmail.value = '';
    }
  }

  Future<void> loadDashboardData({String? timePeriod}) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      // Update selected time period
      if (timePeriod != null && timePeriod.isNotEmpty) {
        selectedTimePeriod.value = timePeriod;
        print('🔄 Time period changed to: ${selectedTimePeriod.value}');
      }

      // Get date range based on selected period
      final dateRange = _getDateRangeForPeriod(selectedTimePeriod.value);
      print(
        '📅 Date range: ${dateRange['startDate']} to ${dateRange['endDate']}',
      );

      // Load all data with the date range
      await Future.wait([
        loadSummary(dateRange),
        loadChartData(dateRange),
        loadExpenseCategories(dateRange),
        loadRecentTransactions(),
      ]);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load dashboard data: $e';
      _showError(errorMessage.value);
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to calculate date range based on selected period
  Map<String, String> _getDateRangeForPeriod(String period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;

      case 'Last Week':
        startDate = now.subtract(const Duration(days: 7));
        break;

      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;

      case 'Last Month':
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
        startDate = DateTime(lastMonthYear, lastMonth, 1);
        endDate = DateTime(
          lastMonthYear,
          lastMonth,
          DateTime(lastMonthYear, lastMonth + 1, 0).day,
        );
        break;

      case 'This Quarter':
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        startDate = DateTime(now.year, quarterMonth, 1);
        break;

      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;

      case 'Custom':
        // For custom, you can implement a date picker
        startDate = DateTime(now.year, 1, 1);
        break;

      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return {
      'startDate': DateFormat('yyyy-MM-dd').format(startDate),
      'endDate': DateFormat('yyyy-MM-dd').format(endDate),
    };
  }

  Future<void> loadSummary(Map<String, String> dateRange) async {
    try {
      Map<String, dynamic> params = {
        'startDate': dateRange['startDate'] ?? '',
        'endDate': dateRange['endDate'] ?? '',
        'timePeriod': selectedTimePeriod.value,
      };

      print('📊 Loading summary with params: $params');

      final response = await _api.get(
        '/api/dashboard/summary',
        queryParameters: params,
      );

      if (response.statusCode == 403) {
        try {
          final data = response.data;
          final message =
              data['message']?.toString() ??
              'Subscription required. Please subscribe to access this feature.';

          hasError.value = true;
          errorMessage.value = message;

          return;
        } catch (e) {
          hasError.value = true;
          errorMessage.value =
              'Subscription required. Please subscribe to continue using the app.';
          return;
        }
      }

      if (response.success) {
        final data = response.data;

        // Safely extract data with null checks
        final dataObj = data['data'] ?? {};
        final kpi = dataObj['kpi'] ?? {};

        // Total Revenue
        final totalRevenueData = kpi['totalRevenue'] ?? {};
        totalRevenue.value = (totalRevenueData['amount'] ?? 0).toDouble();
        totalRevenueFormatted.value = formatAmount(totalRevenue.value);
        revenueChange.value = (totalRevenueData['change'] ?? 0).toDouble();
        isRevenuePositive.value = totalRevenueData['isPositive'] ?? true;

        // Total Expenses
        final totalExpensesData = kpi['totalExpenses'] ?? {};
        totalExpenses.value = (totalExpensesData['amount'] ?? 0).toDouble();
        totalExpensesFormatted.value = formatAmount(totalExpenses.value);
        expenseChange.value = (totalExpensesData['change'] ?? 0).toDouble();
        isExpensePositive.value = totalExpensesData['isPositive'] ?? false;

        // Outstanding
        final outstandingData = kpi['outstanding'] ?? {};
        outstanding.value = (outstandingData['amount'] ?? 0).toDouble();
        outstandingFormatted.value = formatAmount(outstanding.value);
        outstandingChange.value = (outstandingData['change'] ?? 0).toDouble();
        outstandingCount.value = outstandingData['count'] ?? 0;

        // Cash Balance
        final cashBalanceData = kpi['cashBalance'] ?? {};
        cashBalance.value = (cashBalanceData['amount'] ?? 0).toDouble();
        cashBalanceFormatted.value = formatAmount(cashBalance.value);
        cashChange.value = (cashBalanceData['change'] ?? 0).toDouble();
        isCashPositive.value = cashBalanceData['isPositive'] ?? true;

        // Weekly Data
        final weeklyData = dataObj['weeklyData'] ?? {};
        weeklyRevenue.value = (weeklyData['revenue'] ?? 0).toDouble();
        weeklyExpenses.value = (weeklyData['expenses'] ?? 0).toDouble();
        weeklyProfit.value = (weeklyData['profit'] ?? 0).toDouble();

        // Daily Data
        final dailyData = dataObj['dailyData'] ?? {};
        dailyRevenue.value = (dailyData['revenue'] ?? 0).toDouble();
        dailyExpenses.value = (dailyData['expenses'] ?? 0).toDouble();
        dailyProfit.value = (dailyData['profit'] ?? 0).toDouble();

        print('✅ Summary loaded successfully for ${selectedTimePeriod.value}');
        print('📊 Revenue: $totalRevenueFormatted');
        print('📊 Expenses: $totalExpensesFormatted');
      } else {
        hasError.value = true;
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Server error: ${response.statusCode}';
        _showError(errorMessage.value);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'error: $e';
      _showError(errorMessage.value);
      rethrow;
    }
  }

  Future<void> loadChartData(Map<String, String> dateRange) async {
    try {
      Map<String, dynamic> chartParams = {
        'startDate': dateRange['startDate'] ?? '',
        'endDate': dateRange['endDate'] ?? '',
        'timePeriod': selectedTimePeriod.value,
      };

      print('📈 Loading chart data with params: $chartParams');

      final response = await _api.get(
        '/api/dashboard/chart-data',
        queryParameters: chartParams,
      );

      if (response.success) {
        final data = response.data;
        final dataList = data['data'] ?? [];
        chartData.value = List<Map<String, dynamic>>.from(dataList);
        print('✅ Chart data loaded: ${chartData.length} entries');
      } else {
        chartData.clear();
      }
    } catch (e) {
      chartData.clear();
      print('❌ Error loading chart data: $e');
    }
  }

  Future<void> loadExpenseCategories(Map<String, String> dateRange) async {
    try {
      Map<String, dynamic> expenseParams = {
        'startDate': dateRange['startDate'] ?? '',
        'endDate': dateRange['endDate'] ?? '',
        'timePeriod': selectedTimePeriod.value,
      };

      final response = await _api.get(
        '/api/dashboard/expense-categories',
        queryParameters: expenseParams,
      );

      if (response.statusCode == 403) {
        expenseCategories.clear();
        return;
      }

      if (response.success) {
        final data = response.data;
        final dataList = data['data'] ?? [];
        expenseCategories.value = List<Map<String, dynamic>>.from(dataList);
        print(
          '✅ Expense categories loaded: ${expenseCategories.length} categories',
        );
      } else {
        expenseCategories.clear();
      }
    } catch (e) {
      expenseCategories.clear();
      print('❌ Error loading expense categories: $e');
    }
  }

  Future<void> loadRecentTransactions() async {
    try {
      // Also filter recent transactions by date range
      final dateRange = _getDateRangeForPeriod(selectedTimePeriod.value);

      final response = await _api.get(
        '/api/dashboard/recent-transactions',
        queryParameters: {
          'limit': '10',
          'startDate': dateRange['startDate'] ?? '',
          'endDate': dateRange['endDate'] ?? '',
        },
      );

      if (response.statusCode == 403) {
        recentTransactions.clear();
        return;
      }

      if (response.success) {
        final data = response.data;
        final dataList = data['data'] ?? [];
        recentTransactions.value = List<Map<String, dynamic>>.from(dataList);
        print(
          '✅ Recent transactions loaded: ${recentTransactions.length} transactions',
        );
      } else {
        recentTransactions.clear();
      }
    } catch (e) {
      recentTransactions.clear();
      print('❌ Error loading recent transactions: $e');
    }
  }

  // Load comprehensive financial data from all controllers
  Future<void> loadFinancialData() async {
    try {
      // Load bank accounts data
      try {
        await _bankAccountController.fetchBankAccounts();
        totalBankBalance.value = _bankAccountController.totalBalance.value;
        totalBankBalanceFormatted.value = CurrencyUtils.format(
          totalBankBalance.value,
        );
        bankAccountsCount.value = _bankAccountController.bankAccounts.length;

        // Separate cash and bank accounts
        final cashAccounts = _bankAccountController.bankAccounts
            .where((acc) => acc.accountType.toLowerCase().contains('cash'))
            .toList();

        totalCashBalance.value = cashAccounts.fold(
          0.0,
          (sum, acc) => sum + acc.currentBalance,
        );
        totalCashBalanceFormatted.value = CurrencyUtils.format(
          totalCashBalance.value,
        );
        cashAccountsCount.value = cashAccounts.length;
      } catch (e) {
        print('❌ Error loading bank accounts: $e');
        totalBankBalance.value = 0.0;
        totalBankBalanceFormatted.value = CurrencyUtils.format(0.0);
        bankAccountsCount.value = 0;
        totalCashBalance.value = 0.0;
        totalCashBalanceFormatted.value = CurrencyUtils.format(0.0);
        cashAccountsCount.value = 0;
      }

      // Load sales/invoice data with null safety
      try {
        await _invoiceController.fetchInvoices();
        totalSales.value = _invoiceController.totalAmount.value;
        totalSalesFormatted.value = CurrencyUtils.format(totalSales.value);
        salesCount.value = _invoiceController.invoices.length;

        // Update revenue from sales
        totalRevenue.value = totalSales.value;
        totalRevenueFormatted.value = totalSalesFormatted.value;
      } catch (e) {
        print('❌ Error loading invoices: $e');
        totalSales.value = 0.0;
        totalSalesFormatted.value = CurrencyUtils.format(0.0);
        salesCount.value = 0;
        totalRevenue.value = 0.0;
        totalRevenueFormatted.value = CurrencyUtils.format(0.0);
      }

      // Load purchase invoice data with null safety
      try {
        await _purchaseInvoiceController.fetchInvoices();
        totalPurchases.value = _purchaseInvoiceController
            .stats
            .value
            .monthAmount
            .toDouble();
        totalPurchasesFormatted.value = CurrencyUtils.format(
          totalPurchases.value,
        );
        purchaseCount.value = _purchaseInvoiceController.invoices.length;
      } catch (e) {
        print('❌ Error loading purchase invoices: $e');
        totalPurchases.value = 0.0;
        totalPurchasesFormatted.value = CurrencyUtils.format(0.0);
        purchaseCount.value = 0;
      }

      // Load expense data with null safety
      try {
        await _expenseController.loadExpenses();
        totalExpenses.value = _expenseController.totalExpense.value;
        totalExpensesFormatted.value = CurrencyUtils.format(
          totalExpenses.value,
        );
      } catch (e) {
        print('❌ Error loading expenses: $e');
        totalExpenses.value = 0.0;
        totalExpensesFormatted.value = CurrencyUtils.format(0.0);
      }

      // Calculate profit metrics with null safety
      try {
        grossProfit.value = totalSales.value - totalPurchases.value;
        grossProfitFormatted.value = CurrencyUtils.format(grossProfit.value);

        netProfit.value = grossProfit.value - totalExpenses.value;
        netProfitFormatted.value = CurrencyUtils.format(netProfit.value);

        if (totalSales.value > 0) {
          profitMargin.value = (netProfit.value / totalSales.value) * 100;
        } else {
          profitMargin.value = 0.0;
        }
      } catch (e) {
        print('❌ Error calculating profit metrics: $e');
        grossProfit.value = 0.0;
        grossProfitFormatted.value = CurrencyUtils.format(0.0);
        netProfit.value = 0.0;
        netProfitFormatted.value = CurrencyUtils.format(0.0);
        profitMargin.value = 0.0;
      }

      print('✅ Financial data loaded successfully');
      print('💰 Total Sales: $totalSalesFormatted');
      print('💰 Total Purchases: $totalPurchasesFormatted');
      print('💰 Total Expenses: $totalExpensesFormatted');
      print('💰 Gross Profit: $grossProfitFormatted');
      print('💰 Net Profit: $netProfitFormatted');
      print('💰 Bank Balance: $totalBankBalanceFormatted');
      print('💰 Cash Balance: $totalCashBalanceFormatted');
    } catch (e) {
      print('❌ Error loading financial data: $e');
      // Set all values to 0 on complete failure
      _resetFinancialData();
    }
  }

  void _resetFinancialData() {
    totalSales.value = 0.0;
    totalSalesFormatted.value = CurrencyUtils.format(0.0);
    salesCount.value = 0;
    totalPurchases.value = 0.0;
    totalPurchasesFormatted.value = CurrencyUtils.format(0.0);
    purchaseCount.value = 0;
    totalExpenses.value = 0.0;
    totalExpensesFormatted.value = CurrencyUtils.format(0.0);
    totalBankBalance.value = 0.0;
    totalBankBalanceFormatted.value = CurrencyUtils.format(0.0);
    bankAccountsCount.value = 0;
    totalCashBalance.value = 0.0;
    totalCashBalanceFormatted.value = CurrencyUtils.format(0.0);
    cashAccountsCount.value = 0;
    grossProfit.value = 0.0;
    grossProfitFormatted.value = CurrencyUtils.format(0.0);
    netProfit.value = 0.0;
    netProfitFormatted.value = CurrencyUtils.format(0.0);
    profitMargin.value = 0.0;
    totalRevenue.value = 0.0;
    totalRevenueFormatted.value = CurrencyUtils.format(0.0);
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

  void _redirectToLogin() {
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAllNamed('/login');
    });
  }

  // Helper Methods
  double getMonthlyRevenue(int monthIndex) {
    if (monthIndex < chartData.length) {
      return (chartData[monthIndex]['revenue'] ?? 0).toDouble();
    }
    return 0;
  }

  double getMonthlyExpenses(int monthIndex) {
    if (monthIndex < chartData.length) {
      return (chartData[monthIndex]['expenses'] ?? 0).toDouble();
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
