import 'package:BisonsTechs_app/core/accountingReports/accounting_report_controller.dart';
import 'package:BisonsTechs_app/core/profitlossStatement/controllers/profit_and_loss_controller.dart';
import 'package:BisonsTechs_app/core/AccountPayable/controller/account_payable_controller.dart';
import 'package:BisonsTechs_app/core/AccountRecievables/controllers/account_recievables_controller.dart';
import 'package:BisonsTechs_app/core/Bills/controller/bills_controller.dart';
import 'package:BisonsTechs_app/core/Expense/controller/expense_controller.dart';
import 'package:BisonsTechs_app/core/GeneralLedger/Controller/general_ledger_controller.dart';
import 'package:BisonsTechs_app/core/Income/controller/income_controller.dart';
import 'package:BisonsTechs_app/core/Invoice/controller/invoice_controller.dart';
import 'package:BisonsTechs_app/core/Sales/controller/sales_credit_controller.dart';
import 'package:BisonsTechs_app/core/Sales/controller/sales_report_controller.dart';
import 'package:BisonsTechs_app/core/TrailBalance/controller/trail_balance_controller.dart';
import 'package:BisonsTechs_app/core/balancesheet/controller/balance_sheet_controller.dart';
import 'package:BisonsTechs_app/core/cashflowstatement/controller/cashflow_controller.dart';
import 'package:BisonsTechs_app/core/dashboard/controllers/dashboard_controller.dart';
import 'package:BisonsTechs_app/core/goodsRecieving/goods_receiving_controller.dart';
import 'package:BisonsTechs_app/core/journalEntries/Controllers/journal_entry_controller.dart';
import 'package:BisonsTechs_app/core/paymentRecieved/controller/payment_recieved_controller.dart';
import 'package:BisonsTechs_app/core/purchaseInvoice/purchase_invoice_controller.dart';
import 'package:BisonsTechs_app/core/purchasePaymentmade/purchase_payment_controller.dart';
import 'package:BisonsTechs_app/core/purchaseReturn/purchase_return_controller.dart';
import 'package:BisonsTechs_app/core/purchasedashboard/purchase_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Delievery/deleivery_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Reports/controller/expiry_report_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Reports/controller/low_stock_report_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Reports/controller/stock_summary_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/Stock_in/controller/stock_in_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/category/category_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/dashboard/warehouse_dashboard_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/inventory_valuation/controller/inventory_valuation_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/invoice/controller/warehouse_invoice_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/controller/location_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/order/controller/sales_order_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/products/controller/product_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/purchases/controller/purchase_order_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/quotation/quotation_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/refunds/controller/sales_refund_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/returns/controller/sales_return_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/sales/controller/sales_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/salesInvoice/salesinvoice_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/salesPayment/sales_payment_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/supplier/controller/supplier_controller.dart';
import 'package:BisonsTechs_app/core/warehousecustomer/warehouse_customer_controller.dart';
import 'package:get/get.dart';

/// Reloads any open list/dashboard when the location header changes.
class LocationReloadBinder extends GetxController {
  Worker? _worker;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<LocationController>()) return;
    _worker = ever(
      Get.find<LocationController>().storedSelectedId,
      (_) => reloadOpenScreens(),
    );
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  void reloadOpenScreens() {
    _run<WarehouseDashboardController>((c) => c.loadDashboardData());
    _run<SalesController>((c) => c.fetchDashboard());
    _run<PurchaseController>((c) => c.fetchDashboard());
    _run<DashboardController>((c) => c.loadDashboardData());
    _run<ProductsController>((c) => c.refreshProducts());
    _run<CategoriesController>((c) => c.refreshCategories());
    _run<SupplierController>((c) => c.refreshAll());
    _run<WarehouseCustomerController>((c) => c.refreshCustomers());
    _run<SalesOrderController>((c) => c.fetchOrders());
    _run<SalesInvoiceController>((c) => c.refreshInvoices());
    _run<DeliveryController>((c) => c.refreshDeliveries());
    _run<QuotationController>((c) => c.refreshQuotations());
    _run<SalesPaymentController>((c) => c.refreshPayments());
    _run<SalesReturnController>((c) => c.refreshReturns());
    _run<SalesRefundController>((c) => c.refreshRefunds());
    _run<StockController>((c) => c.refreshMovements());
    _run<InventoryValuationController>((c) => c.refreshData());
    _run<ExpiryReportController>((c) => c.loadData());
    _run<LowStockReportController>((c) => c.loadData());
    _run<StockSummaryController>((c) => c.loadData());
    _run<PurchaseOrderController>((c) => c.refreshOrders());
    _run<PurchaseInvoiceController>((c) => c.refreshInvoices());
    _run<GoodsReceivingController>((c) => c.refreshGRNs());
    _run<PurchasePaymentController>((c) => c.refreshPayments());
    _run<PurchaseReturnController>((c) => c.refreshReturns());
    _run<WarehouseInvoiceController>((c) => c.refreshInvoices());
    _run<InvoiceController>((c) => c.fetchInvoices());
    _run<JournalEntryController>((c) => c.fetchJournalEntries());
    _run<GeneralLedgerController>((c) => c.refreshData());
    _run<TrialBalanceController>((c) => c.fetchTrialBalance());
    _run<BalanceSheetController>((c) => c.loadBalanceSheet());
    _run<CashFlowController>((c) => c.loadCashFlowData());
    _run<IncomeController>((c) => c.refreshData());
    _run<ExpenseController>((c) => c.loadAllData());
    _run<BillController>((c) => c.refreshData());
    _run<AccountsPayableController>((c) => c.refreshData());
    _run<AccountsReceivableController>((c) => c.fetchAllData());
    _run<PaymentReceivedController>((c) => c.fetchPayments());
    _run<SalesCreditController>((c) => c.refreshAll());
    _run<SalesReportController>((c) => c.loadReport());
    _run<AccountingReportController>((c) => c.loadReport());
    _run<PLController>((c) => c.loadReportData());
  }

  void _run<T>(void Function(T controller) fn) {
    try {
      if (!Get.isRegistered<T>()) return;
      fn(Get.find<T>());
    } catch (_) {}
  }
}
