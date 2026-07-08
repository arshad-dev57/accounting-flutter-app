import 'package:LedgerPro_app/Utils/currency_utils.dart';
import 'dart:convert';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/plans/views/Subscription_plans.dart';
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
  
  final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  
  final ApiClient _api = Get.find<ApiClient>();
  
  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
        loadUserData();

  }
  
 Future<void> loadUserData() async {
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
  }


  
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      
      await Future.wait([
        loadSummary(),
        loadChartData(),
        loadExpenseCategories(),
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
  
  Future<void> loadSummary() async {
    try {
      final response = await _api.get('/api/dashboard/summary');
      
      if (response.statusCode == 403) {
        try {
          final data = response.data;
          final message = data['message'] ?? 'Subscription required. Please subscribe to access this feature.';
          final code = data['code'];
          
          hasError.value = true;
          errorMessage.value = message;
          
          return;
        } catch (e) {
          hasError.value = true;
          errorMessage.value = 'Subscription required. Please subscribe to continue using the app.';
          return;
        }
      }
      
      if (response.success) {
        final data = response.data;
        final kpi = data['data']['kpi'];
          
          totalRevenue.value = (kpi['totalRevenue']['amount'] ?? 0).toDouble();
          totalRevenueFormatted.value = formatAmount(totalRevenue.value);
          revenueChange.value = (kpi['totalRevenue']['change'] ?? 0).toDouble();
          isRevenuePositive.value = kpi['totalRevenue']['isPositive'] ?? true;
          
          totalExpenses.value = (kpi['totalExpenses']['amount'] ?? 0).toDouble();
          totalExpensesFormatted.value = formatAmount(totalExpenses.value);
          expenseChange.value = (kpi['totalExpenses']['change'] ?? 0).toDouble();
          isExpensePositive.value = kpi['totalExpenses']['isPositive'] ?? false;
          
          outstanding.value = (kpi['outstanding']['amount'] ?? 0).toDouble();
          outstandingFormatted.value = formatAmount(outstanding.value);
          outstandingChange.value = (kpi['outstanding']['change'] ?? 0).toDouble();
          outstandingCount.value = kpi['outstanding']['count'] ?? 0;
          
          cashBalance.value = (kpi['cashBalance']['amount'] ?? 0).toDouble();
          cashBalanceFormatted.value = formatAmount(cashBalance.value);
          cashChange.value = (kpi['cashBalance']['change'] ?? 0).toDouble();
          isCashPositive.value = kpi['cashBalance']['isPositive'] ?? true;
          
          weeklyRevenue.value = (data['data']['weeklyData']['revenue'] ?? 0).toDouble();
          weeklyExpenses.value = (data['data']['weeklyData']['expenses'] ?? 0).toDouble();
          weeklyProfit.value = (data['data']['weeklyData']['profit'] ?? 0).toDouble();
          
          dailyRevenue.value = (data['data']['dailyData']['revenue'] ?? 0).toDouble();
          dailyExpenses.value = (data['data']['dailyData']['expenses'] ?? 0).toDouble();
          dailyProfit.value = (data['data']['dailyData']['profit'] ?? 0).toDouble();
        }  else {
        hasError.value = true;
        errorMessage.value = response.message.isNotEmpty ? response.message : 'Server error: ${response.statusCode}';
        _showError(errorMessage.value);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'error: $e';
      _showError(errorMessage.value);
      rethrow;
    }
  }
  
  Future<void> loadChartData() async {
  try {
    final response = await _api.get('/api/dashboard/chart-data?months=12');
    
    if (response.success) {
      final data = response.data;
      chartData.value = List<Map<String, dynamic>>.from(data['data']);
    } else {
      chartData.clear();
    }
  } catch (e) {
    chartData.clear();
    rethrow;
  }
}
 Future<void> loadExpenseCategories() async {
  try {
    final response = await _api.get('/api/dashboard/expense-categories');
    
    // ✅ Handle 403 Forbidden - Subscription required
    if (response.statusCode == 403) {
      expenseCategories.clear();
      return;
    }
    
    if (response.success) {
      final data = response.data;
      expenseCategories.value = List<Map<String, dynamic>>.from(data['data']);
    } else {
      expenseCategories.clear();
    }
  } catch (e) {
    expenseCategories.clear();
    rethrow;
  }
}

Future<void> loadRecentTransactions() async {
  try {
    final response = await _api.get('/api/dashboard/recent-transactions?limit=10');
    
    // ✅ Handle 403 Forbidden - Subscription required
    if (response.statusCode == 403) {
      recentTransactions.clear();
      return;
    }
    
    if (response.success) {
      final data = response.data;
      recentTransactions.value = List<Map<String, dynamic>>.from(data['data']);
    } else {
      recentTransactions.clear();
    }
  } catch (e) {
    recentTransactions.clear();
    rethrow;
  }
} // ✅ Show Subscription Required Dialog
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
              // Navigate to subscription screen
              Get.to(() =>  SelectPlanScreen());
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
    if (monthIndex < chartData.length && chartData[monthIndex]['month'] != null) {
      return chartData[monthIndex]['month'];
    }
    return months[monthIndex % months.length];
  }
  
  IconData getIconFromName(String iconName) {
    switch (iconName) {
      case 'shopping_bag': return Icons.shopping_bag;
      case 'payment': return Icons.payment;
      case 'bolt': return Icons.bolt;
      case 'computer': return Icons.computer;
      case 'work': return Icons.work;
      case 'add_circle_outline': return Icons.add_circle_outline;
      case 'remove_circle_outline': return Icons.remove_circle_outline;
      case 'receipt_long': return Icons.receipt_long;
      case 'person_add': return Icons.person_add;
      default: return Icons.circle;
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