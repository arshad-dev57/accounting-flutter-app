
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/login/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseDrawer extends StatelessWidget {
  final String currentRoute;

  const PurchaseDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                // ─── Navigation Label ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PURCHASE NAVIGATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

                _drawerItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  title: 'Purchase Dashboard',
                  route: '/warehouse/purchase',
                  isSelected: currentRoute == '/warehouse/purchase',
                ),

                // ─── Purchase Orders ──────────────────────────────────
                _drawerItem(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Purchase Orders',
                  route: '/purchase-order',
                  isSelected: currentRoute == '/purchase-order',
                ),
                _drawerItem(
                  context: context,
                  icon: Icons.business_outlined,
                  title: 'Suppliers',
                  route: '/warehouse/suppliers',
                  isSelected: currentRoute == '/warehouse/suppliers',
                ),
                _drawerItem(
                  context: context,
                  icon: Icons.inventory_outlined,
                  title: 'Goods Receiving',
                  route: '/purchase/goods-receiving',
                  isSelected: currentRoute == '/purchase/goods-receiving',
                ),

                // ─── Purchase Returns ─────────────────────────────────
                _drawerItem(
                  context: context,
                  icon: Icons.assignment_return_outlined,
                  title: 'Purchase Returns',
                  route: '/purchase/returns',
                  isSelected: currentRoute == '/purchase/returns',
                ),

                // ─── Purchase Payments ─────────────────────────────────
                _drawerItem(
                  context: context,
                  icon: Icons.payments_outlined,
                  title: 'Purchase Payments',
                  route: '/purchase/payments',
                  isSelected: currentRoute == '/purchase/payments',
                ),

                 Divider(height: 16, thickness: 1, color: kBorder),

                // ─── Back to Dashboard ─────────────────────────────────
                _drawerItem(
                  context: context,
                  icon: Icons.arrow_back_rounded,
                  title: 'Back to Dashboard',
                  route: '/dashboard',
                  isSelected: false,
                ),
              ],
            ),
          ),
          _buildBottomSection(context),
        ],
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryDark, kPrimary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'LedgerPro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Purchase Module',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Current: ${_getRouteName(currentRoute)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Drawer Item ──────────────────────────────────────────────

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? kPrimary : Colors.grey[600],
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? kPrimary : Colors.grey[800],
        ),
      ),
      trailing: isSelected
          ? Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: kPrimary.withOpacity(0.06),
      onTap: () {
        Navigator.pop(context);
        Get.toNamed(route);
      },
    );
  }

  // ─── Bottom Section ────────────────────────────────────────────

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // ─── User Info ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary, kPrimaryDark],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                      Text(
                        'User',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ─── Logout ──────────────────────────────────────────────
          ListTile(
            leading: Icon(
              Icons.logout_outlined,
              color: Colors.red,
              size: 20,
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────

  String _getRouteName(String route) {
    final parts = route.split('/');
    return parts.isNotEmpty ? parts.last : route;
  }

  // ─── Logout ─────────────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _logout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
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
    );
  }

  void _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Get.offAll(() => const LoginScreen());
      AppSnackbar.success(kSuccess, 'Success', 'Logged out successfully');
    } catch (e) {
      print('Logout error: $e');
      Get.offAll(() => const LoginScreen());
    }
  }
}