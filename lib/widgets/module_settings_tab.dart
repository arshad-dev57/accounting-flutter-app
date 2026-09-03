import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/companyprofile/controller/profile_controller.dart';
import 'package:BisonsTechs_app/core/dashboard/utils/module_settings_routes.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';

class ModuleSettingsTab extends StatelessWidget {
  final VoidCallback onLogout;
  final bool embedded;

  const ModuleSettingsTab({
    super.key,
    required this.onLogout,
    this.embedded = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController());
    }
    if (!Get.isRegistered<SubscriptionController>()) {
      Get.put(SubscriptionController());
    }

    final content = ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, embedded ? 24 : 32),
      children: [
        const _ProfileCard(),
        const SizedBox(height: 16),
        _SettingsSection(
          title: 'MY ACCOUNT',
          items: const [
            _SettingsItem(
              label: 'My Profile',
              icon: Mdi.account_circle_outline,
              routeKey: '__profile',
            ),
            _SettingsItem(
              label: 'Change Password',
              icon: Mdi.lock_reset,
              routeKey: '__changepassword',
            ),
          ],
        ),
        _SettingsSection(
          title: 'APP SETTINGS',
          items: const [
            _SettingsItem(
              label: 'Fiscal Years',
              icon: Mdi.calendar_range,
              routeKey: 'fiscal_years',
            ),
            _SettingsItem(
              label: 'Currency',
              icon: Mdi.currency_usd,
              routeKey: 'currency',
            ),
            _SettingsItem(
              label: 'PDF Reports',
              icon: Mdi.file_pdf_box,
              routeKey: 'pdf_report',
            ),
          ],
        ),
        if (PermissionService.to.isAdmin)
          _SettingsSection(
            title: 'SUBSCRIPTION',
            items: const [
              _SettingsItem(
                label: 'Billing & Invoices',
                icon: Mdi.receipt_text_outline,
                routeKey: 'billing',
              ),
              _SettingsItem(
                label: 'POS Desktop App',
                icon: Mdi.desktop_classic,
                routeKey: 'pos_desktop',
              ),
              _SettingsItem(
                label: 'Subscription Plans',
                icon: Mdi.crown,
                routeKey: 'subscription',
              ),
            ],
          ),
        _SettingsSection(
          title: 'SUPPORT',
          items: const [
            _SettingsItem(
              label: 'User Guide',
              icon: Mdi.book_information_variant,
              routeKey: '__userguide',
            ),
            _SettingsItem(
              label: 'Contact Support',
              icon: Mdi.headset,
              routeKey: '__contact',
            ),
            _SettingsItem(
              label: 'Report an Issue',
              icon: Mdi.bug_outline,
              routeKey: '__reportissue',
            ),
            _SettingsItem(
              label: 'Feedback',
              icon: Mdi.feedback,
              routeKey: 'feedback',
            ),
          ],
        ),
        _SettingsSection(
          title: 'ABOUT',
          items: const [
            _SettingsItem(
              label: 'About App',
              icon: Mdi.information_outline,
              routeKey: 'about_app',
            ),
            _SettingsItem(
              label: 'Terms of Service',
              icon: Mdi.file_sign,
              routeKey: 'terms',
            ),
            _SettingsItem(
              label: 'Privacy Policy',
              icon: Mdi.shield_lock_outline,
              routeKey: 'privacy',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SignOutButton(onLogout: onLogout),
      ],
    );

    if (embedded) {
      return ColoredBox(color: const Color(0xFFF5F6FA), child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: content,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    final subscription = Get.find<SubscriptionController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_rounded, color: kPrimary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.organizationName.value.isEmpty
                        ? 'Company'
                        : profile.organizationName.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1D2E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    PermissionService.to.isAdmin
                        ? (subscription.hasActiveSubscription.value
                              ? 'Premium account'
                              : subscription.isTrialActive.value
                              ? 'Trial account'
                              : 'Free account')
                        : 'Team member',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
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
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEEFF4)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  items[i],
                  if (i < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: Colors.grey.shade100,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String label;
  final String icon;
  final String routeKey;

  const _SettingsItem({
    required this.label,
    required this.icon,
    required this.routeKey,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => navigateModuleSettingsRoute(routeKey, label),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Iconify(icon, size: 18, color: kPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _SignOutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onLogout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEE2E2)),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Sign out',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
