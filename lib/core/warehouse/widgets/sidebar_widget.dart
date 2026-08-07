// lib/core/warehouse/widgets/sidebar_widget.dart

import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:BisonsTechs_app/core/warehouse/dashboard/warehouse_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WarehouseSidebar extends StatelessWidget {
  const WarehouseSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WarehouseDashboardController>();

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _HoverableIconButton(
                      onTap: () => _navigateToDashboardSelection(context),
                      icon: Icons.arrow_back_rounded,
                      size: 18,
                      bgColor: Colors.grey[100]!,
                      hoverColor: kPrimary.withOpacity(0.1),
                      iconColor: Colors.black87,
                      hoverIconColor: kPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Logo Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warehouse,
                        color: kPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'BisonsTechs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Warehouse',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Navigation Label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'NAVIGATION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: controller.menuItems.length,
              itemBuilder: (context, index) {
                return Obx(() {
                  final item = controller.menuItems[index];
                  final isSelected = controller.selectedIndex.value == index;

                  return _HoverableMenuItem(
                    icon: item['icon'],
                    title: item['title'],
                    isSelected: isSelected,
                    onTap: () => controller.navigateTo(index),
                  );
                });
              },
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Bottom Section - User Profile
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // User Info
                _HoverableUserCard(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text(
                            'B',
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
                          children: const [
                            Text(
                              'brostech',
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
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
                              'Premium',
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

                // Logout
                _HoverableMenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  isSelected: false,
                  iconColor: Colors.grey[600]!,
                  hoverIconColor: Colors.red,
                  textColor: Colors.grey,
                  hoverTextColor: Colors.red,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── Navigate to Dashboard Selection ─────────────────────────────

  void _navigateToDashboardSelection(BuildContext context) {
    Get.offAllNamed('/dashboard');
  }

  // ─── Show Logout Confirmation Dialog ──────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logout Icon
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

              // Title
              const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Are you sure you want to sign out?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Action Buttons
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
      barrierDismissible: true,
    );
  }

  // ─── Logout Method ─────────────────────────────────────────────────

  void _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Get.delete<WarehouseDashboardController>(force: true);
      Get.offAll(() => const LoginScreen());
      AppSnackbar.success(kSuccess, 'Success', 'Logged out successfully');
    } catch (e) {
      print('Logout error: $e');
      Get.offAll(() => const LoginScreen());
    }
  }
}

// ─── Hoverable Icon Button ─────────────────────────────────────────────────

class _HoverableIconButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final Color bgColor;
  final Color hoverColor;
  final Color iconColor;
  final Color hoverIconColor;

  const _HoverableIconButton({
    required this.onTap,
    required this.icon,
    required this.size,
    required this.bgColor,
    required this.hoverColor,
    required this.iconColor,
    required this.hoverIconColor,
  });

  @override
  State<_HoverableIconButton> createState() => _HoverableIconButtonState();
}

class _HoverableIconButtonState extends State<_HoverableIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              widget.icon,
              key: ValueKey(widget.icon),
              size: widget.size,
              color: _isHovered ? widget.hoverIconColor : widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hoverable Menu Item ──────────────────────────────────────────────────

class _HoverableMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? hoverIconColor;
  final Color? textColor;
  final Color? hoverTextColor;

  const _HoverableMenuItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.iconColor,
    this.hoverIconColor,
    this.textColor,
    this.hoverTextColor,
  });

  @override
  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<_HoverableMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.isSelected;
    final Color defaultIconColor = isSelected ? kPrimary : Colors.grey[500]!;
    final Color defaultTextColor = isSelected ? kPrimary : Colors.grey[700]!;
    final Color defaultHoverIconColor = isSelected ? kPrimary : kPrimary;
    final Color defaultHoverTextColor = isSelected ? kPrimary : kPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? kPrimary.withOpacity(0.06)
                : _isHovered
                ? kPrimary.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.icon,
                  key: ValueKey(widget.icon),
                  size: 18,
                  color: _isHovered && !isSelected
                      ? (widget.hoverIconColor ?? defaultHoverIconColor)
                      : (widget.iconColor ?? defaultIconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : _isHovered
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: _isHovered && !isSelected
                        ? (widget.hoverTextColor ?? defaultHoverTextColor)
                        : (widget.textColor ?? defaultTextColor),
                  ),
                  child: Text(widget.title),
                ),
              ),
              if (isSelected)
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hoverable User Card ─────────────────────────────────────────────────

class _HoverableUserCard extends StatefulWidget {
  final Widget child;

  const _HoverableUserCard({required this.child});

  @override
  State<_HoverableUserCard> createState() => _HoverableUserCardState();
}

class _HoverableUserCardState extends State<_HoverableUserCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: _isHovered ? Colors.grey[100] : Colors.grey[50],
        ),
        child: widget.child,
      ),
    );
  }
}
