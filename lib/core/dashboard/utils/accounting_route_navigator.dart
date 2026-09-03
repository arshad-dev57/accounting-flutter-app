import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/core/About/about_app_screen.dart';
import 'package:BisonsTechs_app/core/About/privacypolicy_screen.dart';
import 'package:BisonsTechs_app/core/About/termsofservice_screen.dart';
import 'package:BisonsTechs_app/core/AccountPayable/controller/account_payable_controller.dart';
import 'package:BisonsTechs_app/core/AccountPayable/screen/Account_payable_screen.dart';
import 'package:BisonsTechs_app/core/AccountRecievables/controllers/account_recievables_controller.dart';
import 'package:BisonsTechs_app/core/AccountRecievables/screens/account_recievables_screen.dart';
import 'package:BisonsTechs_app/core/AgedRecievables/screens/aged_recievables_screen.dart';
import 'package:BisonsTechs_app/core/BankAccounts/controllers/bankaccount_controller.dart';
import 'package:BisonsTechs_app/core/BankAccounts/screens/bank_acccounts_screen.dart';
import 'package:BisonsTechs_app/core/Bills/controller/bills_controller.dart';
import 'package:BisonsTechs_app/core/Bills/Screen/bill_Screen.dart';
import 'package:BisonsTechs_app/core/CapitalEquity/controller/equity_controller.dart';
import 'package:BisonsTechs_app/core/CapitalEquity/screens/capital_equity_screen.dart';
import 'package:BisonsTechs_app/core/CreditNote/controllers/creditnote_controller.dart';
import 'package:BisonsTechs_app/core/CreditNote/screens/credit_notes_screen.dart';
import 'package:BisonsTechs_app/core/Expense/controller/expense_controller.dart';
import 'package:BisonsTechs_app/core/Expense/screen/expense_screen.dart';
import 'package:BisonsTechs_app/core/Feedback/feedback_screen.dart';
import 'package:BisonsTechs_app/core/FixedAssets/controllers/fixed_asset_controller.dart';
import 'package:BisonsTechs_app/core/FixedAssets/Screens/fixed_assets_screen.dart';
import 'package:BisonsTechs_app/core/FiscalYear/screen/fiscal_year_list_screen.dart';
import 'package:BisonsTechs_app/core/GeneralLedger/Controller/general_ledger_controller.dart';
import 'package:BisonsTechs_app/core/GeneralLedger/Screen/general_ledger_screen.dart';
import 'package:BisonsTechs_app/core/Income/controller/income_controller.dart';
import 'package:BisonsTechs_app/core/Income/Screen/income_screen.dart';
import 'package:BisonsTechs_app/core/PaymentMade/controller/paymentmade_controller.dart';
import 'package:BisonsTechs_app/core/PaymentMade/screens/payment_made_screen.dart';
import 'package:BisonsTechs_app/core/ReportIsuue/Report_issue_screen.dart';
import 'package:BisonsTechs_app/core/TrailBalance/controller/trail_balance_controller.dart';
import 'package:BisonsTechs_app/core/TrailBalance/Screen/trail_balance_screen.dart';
import 'package:BisonsTechs_app/core/UserGuide/screen/user_guide_screen.dart';
import 'package:BisonsTechs_app/core/accountingReports/accounting_report_controller.dart';
import 'package:BisonsTechs_app/core/balancesheet/controller/balance_sheet_controller.dart';
import 'package:BisonsTechs_app/core/balancesheet/screens/balance_sheet_screen.dart';
import 'package:BisonsTechs_app/core/cashflowstatement/controller/cashflow_controller.dart';
import 'package:BisonsTechs_app/core/cashflowstatement/screen/cash_flow_statement_screen.dart';
import 'package:BisonsTechs_app/core/changepassword/screen/change_password_screen.dart';
import 'package:BisonsTechs_app/core/chartofaccounts/controller/chart_of_account_controller.dart';
import 'package:BisonsTechs_app/core/chartofaccounts/screens/chart_of_account_screen.dart';
import 'package:BisonsTechs_app/core/companyprofile/screen/company_profile_screen.dart';
import 'package:BisonsTechs_app/core/contactsupport/contact_support_screen.dart';
import 'package:BisonsTechs_app/core/journalEntries/Controllers/journal_entry_controller.dart';
import 'package:BisonsTechs_app/core/journalEntries/Screens/journal_entries_screen.dart';
import 'package:BisonsTechs_app/core/loanBorrowing/controller/loan_controller.dart';
import 'package:BisonsTechs_app/core/loanBorrowing/screen/_loan_borrowing_screen.dart';
import 'package:BisonsTechs_app/core/paymentRecieved/controller/payment_recieved_controller.dart';
import 'package:BisonsTechs_app/core/paymentRecieved/Screens/payment_recieved_screen.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/plans/views/billing_screen.dart';
import 'package:BisonsTechs_app/core/plans/views/pos_active_screen.dart';
import 'package:BisonsTechs_app/core/profitlossStatement/controllers/profit_and_loss_controller.dart';
import 'package:BisonsTechs_app/core/profitlossStatement/screens/profit_loss_statement_screen.dart';
import 'package:BisonsTechs_app/core/settings/controller/pdf_report_settings_controller.dart';
import 'package:BisonsTechs_app/core/settings/screens/currency_screen.dart';
import 'package:BisonsTechs_app/core/settings/screens/pdf_report_settings_screen.dart';
import 'package:BisonsTechs_app/core/tax/tax_controller.dart';
import 'package:BisonsTechs_app/core/tax/tax_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/invoice/controller/warehouse_invoice_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/invoice/screen/warehouse_invoice_screen.dart';
import 'package:BisonsTechs_app/core/warehousecustomer/warehouse_customer_controller.dart';
import 'package:BisonsTechs_app/core/warehousecustomer/warehouse_customer_screen.dart';
import 'package:BisonsTechs_app/widgets/reload_when_visible.dart';
import 'package:get/get.dart';

void navigateAccountingRoute(String routeKey, String label) {
  if (routeKey.startsWith('__')) {
    switch (routeKey) {
      case '__profile':
        Get.to(() => const ProfileScreen());
        break;
      case '__changepassword':
        Get.to(() => const ChangePasswordScreen());
        break;
      case '__userguide':
        Get.to(() => const UserGuideScreen());
        break;
      case '__contact':
        Get.to(() => const ContactSupportScreen());
        break;
      case '__reportissue':
        Get.to(() => const ReportIssueScreen());
        break;
      default:
        Get.snackbar('Coming soon', '$label coming soon');
    }
    return;
  }

  switch (routeKey) {
    case 'tax_compliance':
      if (Get.isRegistered<TaxController>()) Get.find<TaxController>().loadAll();
      Get.to(() => const TaxComplianceScreen());
      break;
    case 'chart_of_accounts':
      openFresh<ChartOfAccountController>(const ChartOfAccountsScreen());
      break;
    case 'journal_entries':
      openFresh<JournalEntryController>(const JournalEntriesScreen());
      break;
    case 'general_ledger':
      openFresh<GeneralLedgerController>(const GeneralLedgerScreen());
      break;
    case 'trial_balance':
      openFresh<TrialBalanceController>(const TrialBalanceScreen());
      break;
    case 'bank_accounts':
      openFresh<BankAccountController>(const BankAccountsScreen());
      break;
    case 'income':
      openFresh<IncomeController>(const IncomeScreen());
      break;
    case 'expense':
      openFresh<ExpenseController>(const ExpenseScreen());
      break;
    case 'accounts_receivable':
      openFresh<AccountsReceivableController>(const AccountsReceivableScreen());
      break;
    case 'accounts_payable':
      openFresh<AccountsPayableController>(const AccountsPayableScreen());
      break;
    case 'customers':
      openFresh<WarehouseCustomerController>(const WarehouseCustomerScreen());
      break;
    case 'bills':
      openFresh<BillController>(const BillsScreen());
      break;
    case 'payments_received':
      openFresh<PaymentReceivedController>(const PaymentsReceivedScreen());
      break;
    case 'payments_made':
      openFresh<PaymentMadeController>(const PaymentsMadeScreen());
      break;
    case 'credit_notes':
      openFresh<CreditNoteController>(const CreditNotesScreen());
      break;
    case 'fixed_assets':
      openFresh<FixedAssetController>(const FixedAssetsScreen());
      break;
    case 'loans':
      openFresh<LoanController>(const LoansBorrowingsScreen());
      break;
    case 'capital_equity':
      openFresh<EquityController>(const CapitalEquityScreen());
      break;
    case 'accounting_reports':
      if (Get.isRegistered<AccountingReportController>()) {
        Get.delete<AccountingReportController>(force: true);
      }
      Get.toNamed('/accounting/reports');
      break;
    case 'profit_loss':
      openFresh<PLController>(const ProfitLossStatementScreen());
      break;
    case 'balance_sheet':
      openFresh<BalanceSheetController>(const BalanceSheetScreen());
      break;
    case 'cash_flow':
      openFresh<CashFlowController>(const CashFlowStatementScreen());
      break;
    case 'aged_receivables':
      Get.to(() => const AgedReceivablesScreen());
      break;
    case 'warehouse_invoices':
      openFresh<WarehouseInvoiceController>(const WarehouseInvoiceScreen());
      break;
    case 'currency':
      Get.to(() => const CurrencyScreen());
      break;
    case 'fiscal_years':
      Get.to(() => const FiscalYearListScreen());
      break;
    case 'pdf_report':
      openFresh<PdfReportSettingsController>(const PdfReportSettingsScreen());
      break;
    case 'subscription':
      if (PermissionService.to.isAdmin) {
        Get.to(() => const SelectPlanScreen());
      }
      break;
    case 'billing':
      if (PermissionService.to.isAdmin) {
        Get.to(() => const BillingScreen());
      }
      break;
    case 'pos_desktop':
      if (PermissionService.to.isAdmin) {
        Get.to(() => const PosActiveScreen());
      }
      break;
    case 'feedback':
      Get.to(() => const FeedbackScreen());
      break;
    case 'about_app':
      Get.to(() => const AboutAppScreen());
      break;
    case 'terms':
      Get.to(() => const TermsOfServiceScreen());
      break;
    case 'privacy':
      Get.to(() => const PrivacyPolicyScreen());
      break;
    default:
      Get.snackbar('Coming soon', '$label coming soon');
  }
}
