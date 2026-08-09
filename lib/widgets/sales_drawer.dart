import 'dart:convert';
import 'dart:io';

import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/About/about_app_screen.dart';
import 'package:BisonsTechs_app/core/About/privacypolicy_screen.dart';
import 'package:BisonsTechs_app/core/About/termsofservice_screen.dart';
import 'package:BisonsTechs_app/core/Contact/Screens/Contact_Screen.dart';
import 'package:BisonsTechs_app/core/Feedback/feedback_screen.dart';
import 'package:BisonsTechs_app/core/ReportIsuue/Report_issue_screen.dart';
import 'package:BisonsTechs_app/core/UserGuide/screen/user_guide_screen.dart';
import 'package:BisonsTechs_app/core/changepassword/screen/change_password_screen.dart';
import 'package:BisonsTechs_app/core/companyprofile/screen/company_profile_screen.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/settings/screens/currency_screen.dart';
import 'package:BisonsTechs_app/core/settings/screens/pdf_report_settings_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/Delievery/deleivery_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

class SalesDrawerController extends GetxController {
  final RxString businessLogo = ''.obs;
  final RxMap<String, bool> expandedSections = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadBusinessLogo();
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
      print('❌ [SalesDrawerController] Error loading business logo: $e');
    }
  }

  void toggleSection(String title, {bool fallback = false}) {
    final current = expandedSections[title] ?? fallback;
    expandedSections[title] = !current;
  }

  bool isSectionExpanded(String title, {bool fallback = false}) =>
      expandedSections[title] ?? fallback;
}

class SalesDrawer extends StatelessWidget {
  final String currentRoute;
  const SalesDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    Get.put(SalesDrawerController());

    return Drawer(
      width: 272,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          const _DrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              children: [
                _SectionLabel('MAIN'),
                _NavSection(
                  title: 'Sales Core',
                  icon: Mdi.cart_outline,
                  currentRoute: currentRoute,
                  module: 'sales',
                  permissions: const [
                    'products',
                    'orders',
                    'quotations',
                    'customers',
                    'deliveries',
                    'invoices',
                    'sales-payments',
                  ],
                  items: const [
                    (
                      'Products',
                      Mdi.package_variant_closed,
                      '/warehouse/products',
                    ),
                    ('Orders', Mdi.shopping, '/sales/orders'),
                    (
                      'Quotations',
                      Mdi.file_document_outline,
                      '/sales/quotations',
                    ),
                    (
                      'Customers',
                      Mdi.account_group,
                      '/sales/warehouse-customers',
                    ),
                    ('Deliveries', Mdi.truck_delivery, '/sales/delivery'),
                    ('Invoices', Mdi.receipt, '/sales-invoices'),
                    ('Sales Payments', Mdi.arrow_left_right, '/sales-payments'),
                  ],
                ),
                _NavSection(
                  title: 'Returns & Refunds',
                  icon: Mdi.undo_variant,
                  currentRoute: currentRoute,
                  module: 'sales',
                  permissions: const [
                    'sales-returns',
                    'refunds',
                    'credits',
                  ],
                  items: const [
                    ('Sales Returns', Mdi.undo_variant, '/sales/returns'),
                    ('Refunds', Mdi.cash_refund, '/sales/refunds'),
                    (
                      'Sales Credits',
                      Mdi.file_undo_outline,
                      '/sales/credits',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _SectionLabel('ACCOUNT'),
                _NavSection(
                  title: 'Settings',
                  icon: Mdi.cog,
                  currentRoute: currentRoute,
                  items: const [
                    ('Currency', Mdi.currency_usd, '__currency'),
                    ('PDF Reports', Mdi.file_pdf_box, '__pdf_report'),
                  ],
                ),
                _NavSection(
                  title: 'My Account',
                  icon: Mdi.account,
                  currentRoute: currentRoute,
                  items: const [
                    ('My Profile', Mdi.account_circle_outline, '__profile'),
                    ('Change Password', Mdi.lock_reset, '__changepassword'),
                  ],
                ),
                const SizedBox(height: 4),
                _SectionLabel('SUPPORT'),
                _NavSection(
                  title: 'Help & Support',
                  icon: Mdi.help_circle,
                  currentRoute: currentRoute,
                  items: const [
                    ('User Guide', Mdi.book_information_variant, '__userguide'),
                    ('Contact Support', Mdi.headset, '__contact'),
                    ('Report an Issue', Mdi.bug_outline, '__reportissue'),
                  ],
                ),
                _NavSection(
                  title: 'Feedback',
                  icon: Mdi.feedback,
                  currentRoute: currentRoute,
                  items: const [('Feedback', Mdi.feedback, '__feedback')],
                ),
                _NavSection(
                  title: 'Subscription',
                  icon: Mdi.crown,
                  currentRoute: currentRoute,
                  items: const [
                    ('Subscription Plans', Mdi.crown, '__subscription'),
                  ],
                ),
                _NavSection(
                  title: 'About',
                  icon: Mdi.information,
                  currentRoute: currentRoute,
                  items: const [
                    ('About App', Mdi.information_outline, '__about'),
                    ('Terms of Service', Mdi.file_sign, '__terms'),
                    ('Privacy Policy', Mdi.shield_lock_outline, '__privacy'),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: Colors.grey.shade100, height: 1),
                ),
                const SizedBox(height: 8),
                _BackToDashboard(),
              ],
            ),
          ),
          _DrawerFooter(),
        ],
      ),
    );
  }
}

class _DrawerHeader extends GetView<SalesDrawerController> {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: kPrimary),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Get.offAllNamed('/dashboard'),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Obx(() {
                final logo = controller.businessLogo.value;
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: logo.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: logo.startsWith('http')
                              ? Image.network(
                                  logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.trending_up_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(logo),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.trending_up_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    );
                                  },
                                ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.trending_up_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                );
              }),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'moltechq',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'jhon@gmail.com',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Iconify(
                  Mdi.shield_account,
                  size: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Current Plan',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Premium',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String title;
  final String icon;
  final String currentRoute;
  final List<(String, String, String)> items; // (label, mdi-icon, route-key)
  final String? module;
  final List<String>? permissions;

  const _NavSection({
    required this.title,
    required this.icon,
    required this.currentRoute,
    required this.items,
    this.module,
    this.permissions,
  });

  bool _isActive(String routeKey) {
    final r = currentRoute.toLowerCase();
    if (routeKey.startsWith('__')) return false;
    return r.contains(routeKey.toLowerCase());
  }

  bool get _hasActiveChild => items.any((i) => _isActive(i.$3));

  List<(String, String, String)> get _filteredItems {
    final permissionService = PermissionService.to;
    if (module == null || permissions == null) {
      return items;
    }

    if (permissionService.isAdmin) return items;

    final filtered = <(String, String, String)>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final permission = permissions![i];

      if (permissionService.hasSubPageAccess(module!, permission)) {
        filtered.add(item);
      }
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final drawerController = Get.find<SalesDrawerController>();
    final initiallyExpanded = _hasActiveChild;

    return Obx(() {
      final expanded = drawerController.isSectionExpanded(
        title,
        fallback: initiallyExpanded,
      );

      return Column(
        children: [
          InkWell(
            onTap: () => drawerController.toggleSection(
              title,
              fallback: initiallyExpanded,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Iconify(
                    icon,
                    size: 18,
                    color: _hasActiveChild ? kPrimary : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _hasActiveChild
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: _hasActiveChild ? Colors.black : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: _filteredItems.map((item) {
                final isActive = _isActive(item.$3);
                return _NavItem(
                  label: item.$1,
                  icon: item.$2,
                  isActive: isActive,
                  onTap: () {
                    Navigator.pop(context);
                    _navigate(item.$3, item.$1);
                  },
                );
              }).toList(),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      );
    });
  }

  void _navigate(String routeKey, String label) {
    switch (routeKey) {
      case '/warehouse/products':
        Get.toNamed('/warehouse/products');
        break;
      case '/sales/orders':
        Get.toNamed('/sales/orders');
        break;
      case '/sales/quotations':
        Get.toNamed('/sales/quotations');
        break;
      case '/sales/warehouse-customers':
        Get.toNamed('/sales/warehouse-customers');
        break;
      case '/sales/delivery':
        Get.to(() => const DeliveryScreen());
        break;
      case '/sales-invoices':
        Get.toNamed('/sales-invoices');
        break;
      case '/sales-payments':
        Get.toNamed('/sales-payments');
        break;
      case '/sales/returns':
        Get.toNamed('/sales/returns');
        break;
      case '/sales/refunds':
        Get.toNamed('/sales/refunds');
        break;
      case '/sales/credits':
        Get.toNamed('/sales/credits');
        break;
      case '__currency':
        Get.to(() => const CurrencyScreen());
        break;
      case '__pdf_report':
        Get.to(() => const PdfReportSettingsScreen());
        break;
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
        Get.to(() => const ContactScreen());
        break;
      case '__reportissue':
        Get.to(() => const ReportIssueScreen());
        break;
      case '__feedback':
        Get.to(() => const FeedbackScreen());
        break;
      case '__subscription':
        Get.to(() => const SelectPlanScreen());
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
        Get.snackbar('Coming Soon', '$label coming soon');
    }
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? kPrimary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // indent line
            Container(
              width: 2,
              height: 14,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isActive ? kPrimary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Iconify(
              icon,
              size: 16,
              color: isActive ? kPrimary : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? kPrimary : Colors.grey.shade700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: kPrimary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Back to Dashboard
// ══════════════════════════════════════════════════════════════════

class _BackToDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Get.offAllNamed('/dashboard');
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 10),
              Text(
                'Back to Dashboard',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // User card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPrimary, kPrimaryDark]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Premium Account',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Logout button
          InkWell(
            onTap: () => _showLogoutDialog(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Iconify(Mdi.logout, color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  void _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final permissionService = PermissionService.to;
      await permissionService.clearUserData();
      Get.offAll(() => const LoginScreen());
      AppSnackbar.success(kSuccess, 'Success', 'Logged out successfully');
    } catch (e) {
      Get.offAll(() => const LoginScreen());
    }
  }
}
