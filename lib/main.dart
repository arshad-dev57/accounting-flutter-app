// lib/main.dart - COMPLETE FIXED

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/core/Onboarding/views/Onboarding_screen.dart';
import 'package:BisonsTechs_app/core/Register/Views/register_screen.dart';
import 'package:BisonsTechs_app/core/Sales/screens/sales_credits_screen.dart';
import 'package:BisonsTechs_app/core/Sales/screens/sales_dashbaord_screen.dart';
import 'package:BisonsTechs_app/core/Sales/screens/sales_report_screen.dart';
import 'package:BisonsTechs_app/core/accountingReports/accounting_report_screen.dart';
import 'package:BisonsTechs_app/core/purchasedashboard/purchase_report_screen.dart';
import 'package:BisonsTechs_app/core/Splash/screen/splash_screen.dart';
import 'package:BisonsTechs_app/core/dashboard/Screens/dashbaord_screen.dart';
import 'package:BisonsTechs_app/core/dashboard/controllers/dashboard_controller.dart';
import 'package:BisonsTechs_app/core/dashboardSelection/screen/dashboard_selection.dart';
import 'package:BisonsTechs_app/core/goodsRecieving/goods_receiving_controller.dart';
import 'package:BisonsTechs_app/core/goodsRecieving/goods_receiving_screen.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/plans/views/payment_cancel_screen.dart';
import 'package:BisonsTechs_app/core/plans/views/payment_sucess_screen.dart';
import 'package:BisonsTechs_app/core/purchaseInvoice/purchase_invoice_controller.dart';
import 'package:BisonsTechs_app/core/purchaseInvoice/purchase_invoice_screen.dart';
import 'package:BisonsTechs_app/core/purchasePaymentmade/purchase_payment_controller.dart';
import 'package:BisonsTechs_app/core/purchasePaymentmade/purchase_payment_screen.dart';
import 'package:BisonsTechs_app/core/purchaseReturn/purchase_return_controller.dart';
import 'package:BisonsTechs_app/core/purchaseReturn/purchase_return_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/Delievery/deleivery_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Delievery/deleivery_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/Reports/screen/expiry_report_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/Reports/screen/low_stock_report_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/Reports/screen/stock_summary_report_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/Stock_in/screen/stock_in_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/category/category_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/dashboard/warehouse_dashboard_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/inventory_valuation/screen/inventory_valuation_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/invoice/screen/warehouse_invoice_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/order/screen/Sales_order_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/products/controller/product_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/products/screen/product_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/purchases/controller/purchase_order_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/purchases/screen/purchase_order_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/quotation/quotation_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/quotation/quotation_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/refunds/screen/sales_refund_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/reports/screen/reports_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/returns/screen/sales_return_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/salesInvoice/sales_invoice_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/salesInvoice/salesinvoice_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/salesPayment/sales_payment_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/salesPayment/sales_payment_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/supplier/controller/supplier_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/supplier/screen/supplier_screen.dart';
import 'package:BisonsTechs_app/core/warehousecustomer/warehouse_customer_controller.dart';
import 'package:BisonsTechs_app/core/warehousecustomer/warehouse_customer_screen.dart';
import 'package:BisonsTechs_app/core/Users/screen/user_list_screen.dart';
import 'package:BisonsTechs_app/core/Users/screen/user_form_screen.dart';
import 'package:BisonsTechs_app/core/Users/screen/access_management_screen.dart';
import 'package:BisonsTechs_app/core/Users/screen/enhanced_access_management_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Services/notification_Service.dart';
import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/tax/tax_screen.dart';

class ThemeController extends GetxController {
  var isDarkMode = false.obs;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  Get.put(ApiClient(), permanent: true);
  Get.put(SubscriptionController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(CurrencyController(), permanent: true);
  Get.put(FiscalYearController(), permanent: true);
  Get.put(PermissionService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await NotificationService.instance.init();
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('auth_user_id');
        if (userId != null && userId.isNotEmpty) {
          await NotificationService.instance.login(userId);
          await NotificationService.instance.verifyDeviceRegistration();
        }
      });
    }

    return Sizer(
      builder: (context, orientation, deviceType) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'BisonsTechs App',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: Get.find<ThemeController>().isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: '/',
          getPages: [
            // ========== AUTH ROUTES ==========
            GetPage(name: '/', page: () => SplashScreen()),
            GetPage(name: '/login', page: () => const LoginScreen()),
            GetPage(name: '/register', page: () => RegistrationScreen()),
            GetPage(name: '/onboarding', page: () => const OnboardingScreen()),

            // ========== DASHBOARD ROUTES ==========
            GetPage(
              name: '/dashboard',
              page: () => const DashboardSelectionScreen(),
            ),
            GetPage(
              name: '/tax',
              page: () => const TaxComplianceScreen(),
            ),
            GetPage(
              name: '/accounting/dashboard',
              page: () => const DashboardScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => DashboardController(), fenix: true);
              }),
            ),
            GetPage(
              name: '/sales-invoices',
              page: () => const SalesInvoiceScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => SalesInvoiceController());
              }),
            ),

            GetPage(
              name: '/purchase-order',
              page: () => const PurchaseOrderScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => PurchaseOrderController());
              }),
            ),

            GetPage(
              name: '/sales-payments',
              page: () => const SalesPaymentScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => SalesPaymentController());
              }),
            ),
            GetPage(
              name: '/sales/quotations',
              page: () => const QuotationScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => QuotationController());
              }),
            ),
            GetPage(
              name: '/purchase/invoices',
              page: () => const PurchaseInvoiceScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => PurchaseInvoiceController());
              }),
            ),
            GetPage(
              name: '/purchase/purchase-return',
              page: () => const PurchaseReturnScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => PurchaseReturnController());
              }),
            ),

            GetPage(
              name: '/purchase/purchase-payment',
              page: () => PurchasePaymentScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => PurchasePaymentController());
              }),
            ),
            GetPage(
              name: '/purchase/goods-receiving',
              page: () => const GoodsReceivingScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => GoodsReceivingController());
              }),
            ),

            GetPage(
              name: '/sales/warehouse-customers',
              page: () => const WarehouseCustomerScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => WarehouseCustomerController());
              }),
            ),

            GetPage(
              name: '/sales/delievery',
              page: () => const DeliveryScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => DeliveryController());
              }),
            ),
            // ========== SUBSCRIPTION ROUTES ==========
            GetPage(name: '/plans', page: () => const SelectPlanScreen()),
            GetPage(
              name: '/payment-success',
              page: () => const PaymentSuccessScreen(),
            ),
            GetPage(
              name: '/payment-cancel',
              page: () => const PaymentCancelScreen(),
            ),

            GetPage(
              name: '/warehouse/dashboard',
              page: () => WarehouseDashboard(),
            ),
            GetPage(
              name: '/warehouse/invoices',
              page: () => const WarehouseInvoiceScreen(),
            ),
            GetPage(
              name: '/warehouse/products',
              page: () => const ProductsScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => ProductsController());
              }),
            ),
            GetPage(
              name: '/warehouse/categories',
              page: () => const CategoriesScreen(),
            ),
            GetPage(
              name: '/warehouse/suppliers',
              page: () => const SuppliersScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => SupplierController());
              }),
            ),
            GetPage(
              name: '/warehouse/customers',
              page: () => const WarehouseCustomerScreen(),
              binding: BindingsBuilder(() {
                Get.lazyPut(() => WarehouseCustomerController());
              }),
            ),
            GetPage(
              name: '/warehouse/orders',
              page: () => const SalesOrdersScreen(),
            ),
            GetPage(
              name: '/warehouse/sales',
              page: () => const SalesDashboardScreen(),
            ),
            GetPage(
              name: '/warehouse/refunds',
              page: () => const SalesRefundsScreen(),
            ),
            GetPage(
              name: '/warehouse/returns',
              page: () => SalesReturnScreen(),
            ),
            GetPage(name: '/warehouse/stock', page: () => const StockScreen()),
            GetPage(
              name: '/warehouse/reports',
              page: () => const ReportsScreen(),
            ),
            GetPage(
              name: '/warehouse/inventory',
              page: () => const InventoryValuationScreen(),
            ),
            GetPage(
              name: '/warehouse/reports/stock-summary',
              page: () => const StockSummaryReportScreen(),
            ),
            GetPage(
              name: '/warehouse/reports/low-stock',
              page: () => const LowStockReportScreen(),
            ),
            GetPage(
              name: '/warehouse/reports/expiry',
              page: () => const ExpiryReportScreen(),
            ),
            // ========== SALES ROUTES ==========
            GetPage(
              name: '/sales/orders',
              page: () => const SalesOrdersScreen(),
            ),
            GetPage(
              name: '/sales/invoices',
              page: () =>
                  const SalesDashboardScreen(), // TODO: Replace with actual invoice screen
            ),
            GetPage(
              name: '/sales/returns',
              page: () => const SalesReturnScreen(),
            ),
            GetPage(
              name: '/sales/refunds',
              page: () => const SalesRefundsScreen(),
            ),
            GetPage(
              name: '/sales/credits',
              page: () => const SalesCreditsScreen(),
            ),
            GetPage(
              name: '/sales/reports',
              page: () => const SalesReportScreen(),
            ),
            GetPage(
              name: '/purchase/reports',
              page: () => const PurchaseReportScreen(),
            ),
            GetPage(
              name: '/accounting/reports',
              page: () => const AccountingReportScreen(),
            ),
            // ========== USER MANAGEMENT ROUTES ==========
            GetPage(name: '/admin/users', page: () => const UserListScreen()),
            GetPage(
              name: '/admin/users/add',
              page: () => const UserFormScreen(),
            ),
            GetPage(
              name: '/admin/users/edit/:id',
              page: () {
                final id = Get.parameters['id'];
                return UserFormScreen(userId: id);
              },
            ),
            GetPage(
              name: '/admin/users/access/:id',
              page: () {
                final id = Get.parameters['id'];
                return EnhancedAccessManagementScreen(userId: id ?? '');
              },
            ),
          ],
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1AB4F5),
        primary: const Color(0xFF1AB4F5),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: kBg,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFF1AB4F5),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1AB4F5),
          foregroundColor: Colors.white,
          minimumSize: Size(100.w, 6.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1AB4F5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE74C3C)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
        titleLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(fontSize: 14.sp, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 12.sp, color: Colors.black87),
        labelSmall: TextStyle(fontSize: 10.sp, color: Colors.black54),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1AB4F5),
        primary: const Color(0xFF1AB4F5),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFF1AB4F5),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1AB4F5),
          foregroundColor: Colors.white,
          minimumSize: Size(100.w, 6.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1AB4F5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE74C3C)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(fontSize: 14.sp, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 12.sp, color: Colors.white70),
        labelSmall: TextStyle(fontSize: 10.sp, color: Colors.white60),
      ),
    );
  }
}
