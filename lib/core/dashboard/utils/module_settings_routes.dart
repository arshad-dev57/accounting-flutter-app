import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/core/About/about_app_screen.dart';
import 'package:BisonsTechs_app/core/About/privacypolicy_screen.dart';
import 'package:BisonsTechs_app/core/About/termsofservice_screen.dart';
import 'package:BisonsTechs_app/core/Feedback/feedback_screen.dart';
import 'package:BisonsTechs_app/core/FiscalYear/screen/fiscal_year_list_screen.dart';
import 'package:BisonsTechs_app/core/ReportIsuue/Report_issue_screen.dart';
import 'package:BisonsTechs_app/core/UserGuide/screen/user_guide_screen.dart';
import 'package:BisonsTechs_app/core/changepassword/screen/change_password_screen.dart';
import 'package:BisonsTechs_app/core/companyprofile/screen/company_profile_screen.dart';
import 'package:BisonsTechs_app/core/contactsupport/contact_support_screen.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/settings/controller/pdf_report_settings_controller.dart';
import 'package:BisonsTechs_app/core/settings/screens/currency_screen.dart';
import 'package:BisonsTechs_app/core/settings/screens/pdf_report_settings_screen.dart';
import 'package:BisonsTechs_app/core/tax/tax_controller.dart';
import 'package:BisonsTechs_app/core/tax/tax_screen.dart';
import 'package:get/get.dart';

void navigateModuleSettingsRoute(String routeKey, String label) {
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
      case '__fiscal_years':
        Get.to(() => const FiscalYearListScreen());
        break;
      case '__currency':
        Get.to(() => const CurrencyScreen());
        break;
      case '__pdf_report':
        if (Get.isRegistered<PdfReportSettingsController>()) {
          Get.delete<PdfReportSettingsController>(force: true);
        }
        Get.put(PdfReportSettingsController());
        Get.to(() => const PdfReportSettingsScreen());
        break;
      case '__tax':
        if (Get.isRegistered<TaxController>()) {
          Get.find<TaxController>().loadAll();
        }
        Get.to(() => const TaxComplianceScreen());
        break;
      case '__subscription':
        if (PermissionService.to.isAdmin) {
          Get.to(() => const SelectPlanScreen());
        }
        break;
      case '__feedback':
        Get.to(() => const FeedbackScreen());
        break;
      case '__about':
        Get.to(() => const AboutAppScreen());
        break;
      case '__terms':
        Get.to(() => const TermsOfServiceScreen());
        break;
      case '__privacy':
        Get.to(() => const PrivacyPolicyScreen());
        break;
      default:
        Get.snackbar('Coming soon', '$label coming soon');
    }
    return;
  }

  switch (routeKey) {
    case 'fiscal_years':
      Get.to(() => const FiscalYearListScreen());
      break;
    case 'currency':
      Get.to(() => const CurrencyScreen());
      break;
    case 'pdf_report':
      if (Get.isRegistered<PdfReportSettingsController>()) {
        Get.delete<PdfReportSettingsController>(force: true);
      }
      Get.put(PdfReportSettingsController());
      Get.to(() => const PdfReportSettingsScreen());
      break;
    case 'subscription':
      if (PermissionService.to.isAdmin) {
        Get.to(() => const SelectPlanScreen());
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
