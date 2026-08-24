import 'dart:convert';
import 'dart:io';

import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/About/about_app_screen.dart';
import 'package:BisonsTechs_app/core/About/privacypolicy_screen.dart';
import 'package:BisonsTechs_app/core/About/termsofservice_screen.dart';
import 'package:BisonsTechs_app/core/Feedback/feedback_screen.dart';
import 'package:BisonsTechs_app/core/ReportIsuue/Report_issue_screen.dart';
import 'package:BisonsTechs_app/core/contactsupport/contact_support_screen.dart';
import 'package:BisonsTechs_app/core/support/screens/support_tickets_screen.dart';
import 'package:BisonsTechs_app/core/UserGuide/screen/user_guide_screen.dart';
import 'package:BisonsTechs_app/core/changepassword/screen/change_password_screen.dart';
import 'package:BisonsTechs_app/core/companyprofile/screen/company_profile_screen.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/settings/screens/currency_screen.dart';
import 'package:BisonsTechs_app/core/settings/screens/pdf_report_settings_screen.dart';
import 'package:BisonsTechs_app/core/FiscalYear/screen/fiscal_year_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

class PurchaseDrawer extends StatelessWidget {
  final String currentRoute;
  const PurchaseDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 272,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _PurchaseDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              children: [
                _SectionLabel('MAIN'),
                _NavSection(
                  title: 'Purchase Core',
                  icon: Mdi.cart_plus,
                  currentRoute: currentRoute,
                  module: 'purchase',
                  permissions: const [
                    'dashboard',
                    'dashboard',
                    'products',
                    'purchase-orders',
                    'suppliers',
                    'goods-receiving',
                    'purchase-invoices',
                    'purchase-payments',
                    'purchase-returns',
                  ],
                  items: const [
                    (
                      'Purchase Dashboard',
                      Mdi.view_dashboard,
                      '/warehouse/purchase',
                    ),
                    (
                      'Purchase Reports',
                      Mdi.file_chart,
                      '/purchase/reports',
                    ),
                    (
                      'Products',
                      Mdi.package_variant_closed,
                      '/purchase/products',
                    ),
                    ('Purchase Orders', Mdi.receipt_text, '/purchase-order'),
                    ('Suppliers', Mdi.account_tie, '/warehouse/suppliers'),
                    (
                      'Goods Receiving',
                      Mdi.archive_arrow_down,
                      '/purchase/goods-receiving',
                    ),
                    (
                      'Purchase Invoices',
                      Mdi.file_document,
                      '/purchase/invoices',
                    ),
                    (
                      'Purchase Payments',
                      Mdi.cash,
                      '/purchase/purchase-payment',
                    ),
                    (
                      'Purchase Returns',
                      Mdi.undo_variant,
                      '/purchase/purchase-return',
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
                    ('Fiscal Years', Mdi.calendar_range, '__fiscal_years'),
                    ('Currency', Mdi.currency_usd, '__currency'),
                    ('PDF Reports', Mdi.file_pdf_box, '__pdf_report'),
                    ('Tax Compliance', Mdi.percent, '__tax'),
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
                    ('Support Tickets', Mdi.ticket_outline, '__supporttickets'),
                    ('Report an Issue', Mdi.bug_outline, '__reportissue'),
                  ],
                ),
                _NavSection(
                  title: 'Feedback',
                  icon: Mdi.feedback,
                  currentRoute: currentRoute,
                  items: const [('Feedback', Mdi.feedback, '__feedback')],
                ),
                if (PermissionService.to.isAdmin)
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
          _PurchaseDrawerFooter(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Purchase-specific Header
// ══════════════════════════════════════════════════════════════════

class _PurchaseDrawerHeader extends StatefulWidget {
  @override
  State<_PurchaseDrawerHeader> createState() => _PurchaseDrawerHeaderState();
}

class _PurchaseDrawerHeaderState extends State<_PurchaseDrawerHeader> {
  String _businessLogo = '';

  @override
  void initState() {
    super.initState();
    _loadBusinessLogo();
  }

  Future<void> _loadBusinessLogo() async {
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
            setState(() {
              _businessLogo = logo;
            });
          }
        }
      }
    } catch (e) {
      print('❌ [PurchaseDrawerHeader] Error loading business logo: $e');
    }
  }

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _businessLogo.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _businessLogo.startsWith('http')
                            ? Image.network(
                                _businessLogo,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.shopping_bag_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(_businessLogo),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.shopping_bag_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  );
                                },
                              ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
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
                      'Purchase Module',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (PermissionService.to.isAdmin) ...[
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
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Purchase-specific Footer
// ══════════════════════════════════════════════════════════════════

class _PurchaseDrawerFooter extends StatelessWidget {
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
                      if (PermissionService.to.isAdmin)
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

// ══════════════════════════════════════════════════════════════════
// Shared sub-widgets
// ══════════════════════════════════════════════════════════════════

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

class _NavSection extends StatefulWidget {
  final String title;
  final String icon;
  final String currentRoute;
  final List<(String, String, String)> items;
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

  @override
  State<_NavSection> createState() => _NavSectionState();
}

class _NavSectionState extends State<_NavSection> {
  bool _expanded = false;
  final PermissionService _permissionService = PermissionService.to;

  bool get _hasActiveChild => widget.items.any((i) => _isActive(i.$3));

  List<(String, String, String)> get _filteredItems {
    if (widget.module == null || widget.permissions == null) {
      return widget.items;
    }

    final isAdmin = _permissionService.isAdmin;
    if (isAdmin) return widget.items;

    final filtered = <(String, String, String)>[];
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      final permission = widget.permissions![i];

      if (_permissionService.hasSubPageAccess(widget.module!, permission)) {
        filtered.add(item);
      }
    }
    return filtered;
  }

  bool _isActive(String routeKey) {
    if (routeKey.startsWith('__')) return false;
    return widget.currentRoute.toLowerCase().contains(routeKey.toLowerCase());
  }

  @override
  void initState() {
    super.initState();
    _expanded = _hasActiveChild;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Iconify(
                  widget.icon,
                  size: 18,
                  color: _hasActiveChild ? kPrimary : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
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
                  _expanded
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
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: _filteredItems.map((item) {
              return _NavItem(
                label: item.$1,
                icon: item.$2,
                isActive: _isActive(item.$3),
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
  }

  void _navigate(String routeKey, String label) {
    if (!routeKey.startsWith('__')) {
      Get.toNamed(routeKey);
      return;
    }
    switch (routeKey) {
      case '__tax':
        Get.toNamed('/tax');
        break;
      case '__fiscal_years':
        Get.to(() => const FiscalYearListScreen());
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
        Get.to(() => const ContactSupportScreen());
        break;
      case '__supporttickets':
        Get.to(() => const SupportTicketsScreen());
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
