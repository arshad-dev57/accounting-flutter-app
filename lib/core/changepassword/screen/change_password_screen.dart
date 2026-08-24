// lib/core/changepassword/screen/change_password_screen.dart

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/changepassword/controller/change_password_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ChangePasswordScreen extends StatelessWidget {
  final bool isForgotFlow;

  const ChangePasswordScreen({super.key, this.isForgotFlow = false});

  String get _title => isForgotFlow ? 'Reset Password' : 'Change Password';
  String get _subtitle => isForgotFlow
      ? 'Create a new password for your account'
      : 'Secure your account with a new password';
  String get _heroSubtitle => isForgotFlow
      ? 'Create your new password after OTP verification.'
      : 'Update your password to keep your\naccount secure.';

  @override
  Widget build(BuildContext context) {
    ChangePasswordController controller;
    if (Get.isRegistered<ChangePasswordController>()) {
      final existing = Get.find<ChangePasswordController>();
      if (existing.isForgotFlow != isForgotFlow) {
        Get.delete<ChangePasswordController>(force: true);
        controller = Get.put(
          ChangePasswordController(isForgotFlow: isForgotFlow),
        );
      } else {
        controller = existing;
      }
    } else {
      controller = Get.put(
        ChangePasswordController(isForgotFlow: isForgotFlow),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: ResponsiveUtils.isWeb(context)
          ? _buildWebLayout(context, controller)
          : _buildMobileTabletLayout(context, controller),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WEB LAYOUT - Same as OTP Screen
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildWebLayout(
    BuildContext context,
    ChangePasswordController controller,
  ) {
    final screenH = MediaQuery.of(context).size.height;

    return Row(
      children: [
        // ── LEFT PANEL — full-bleed image ──────────────
        Expanded(
          flex: 1,
          child: SizedBox(
            height: screenH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1553413077-190dd305871c?w=900&q=80&fit=crop',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: const Color(0xFF0A3D5C),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1AB4F5),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, _, __) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0A3D5C), Color(0xFF0A7FA8)],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Color(0xCC000000)],
                    ),
                  ),
                ),
                Container(color: const Color(0xFF0A7FA8).withOpacity(0.25)),

                // Branding content pinned to bottom-left
                Positioned(
                  left: 36,
                  right: 36,
                  bottom: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 96,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _heroSubtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13.5,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _tipPill('🔒', 'Use at least 8 characters'),
                      const SizedBox(height: 10),
                      _tipPill('🔢', 'Include numbers & special characters'),
                      const SizedBox(height: 10),
                      _tipPill('🚫', 'Avoid using common words'),
                      const SizedBox(height: 10),
                      _tipPill('🔄', 'Don\'t reuse old passwords'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── RIGHT PANEL ──────────────────────────────
        Expanded(
          flex: 1,
          child: SizedBox(
            height: screenH,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWebHeader(),
                      const SizedBox(height: 32),
                      _buildForm(controller, context),
                      const SizedBox(height: 32),
                      _buildChangeButton(controller, context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MOBILE & TABLET LAYOUT
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMobileTabletLayout(
    BuildContext context,
    ChangePasswordController controller,
  ) {
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.getScreenPadding(context),
        child: Center(
          child: SizedBox(
            width: ResponsiveUtils.getFormWidth(context),
            child: Column(
              children: [
                SizedBox(height: isTablet ? 16 : 8),
                _buildMobileHeader(context),
                SizedBox(height: isTablet ? 32 : 24),
                _buildForm(controller, context),
                SizedBox(height: isTablet ? 32 : 24),
                _buildChangeButton(controller, context),
                SizedBox(height: isTablet ? 24 : 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WEB HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildWebHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          height: 110,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.account_balance_rounded,
            size: 56,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MOBILE APP BAR
  // ═══════════════════════════════════════════════════════════════════
  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        _title,
        style: TextStyle(
          fontSize: ResponsiveUtils.getHeadingFontSize(context),
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      backgroundColor: kPrimary,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Get.back(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MOBILE HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMobileHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.isTablet(context) ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.isTablet(context) ? 24 : 20,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: ResponsiveUtils.isTablet(context) ? 72 : 56,
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.isTablet(context) ? 16 : 12,
              vertical: ResponsiveUtils.isTablet(context) ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: ResponsiveUtils.isTablet(context) ? 20 : 16),
          Text(
            _title,
            style: TextStyle(
              fontSize: ResponsiveUtils.isTablet(context) ? 22 : 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _subtitle,
            style: TextStyle(
              fontSize: ResponsiveUtils.isTablet(context) ? 14 : 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FORM - with 3 fields
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildForm(ChangePasswordController controller, BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isForgotFlow) ...[
            _buildPasswordField(
              label: 'Current Password',
              hint: 'Enter your current password',
              icon: Mdi.lock_outline,
              controller: controller.oldPasswordController,
              error: controller.oldPasswordError,
              isVisible: controller.isOldPasswordVisible,
              onToggle: controller.toggleOldPasswordVisibility,
              onChanged: (_) => controller.clearOldPasswordError(),
              context: context,
            ),
            SizedBox(height: isWeb ? 20 : 16),
          ],

          // New Password
          _buildPasswordField(
            label: 'New Password',
            hint: 'Enter new password',
            icon: Mdi.lock_plus_outline,
            controller: controller.newPasswordController,
            error: controller.newPasswordError,
            isVisible: controller.isNewPasswordVisible,
            onToggle: controller.toggleNewPasswordVisibility,
            onChanged: (_) => controller.clearNewPasswordError(),
            context: context,
          ),

          SizedBox(height: isWeb ? 20 : 16),

          // Confirm Password
          _buildPasswordField(
            label: 'Confirm Password',
            hint: 'Confirm your new password',
            icon: Mdi.lock_check_outline,
            controller: controller.confirmPasswordController,
            error: controller.confirmPasswordError,
            isVisible: controller.isConfirmPasswordVisible,
            onToggle: controller.toggleConfirmPasswordVisibility,
            onChanged: (_) => controller.clearConfirmPasswordError(),
            context: context,
          ),

          SizedBox(height: isWeb ? 20 : 16),

          // Password requirements
          _buildPasswordRequirements(context),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required String icon,
    required TextEditingController controller,
    required RxString error,
    required RxBool isVisible,
    required VoidCallback onToggle,
    required Function(String) onChanged,
    required BuildContext context,
  }) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Iconify(icon, size: isWeb ? 20 : 18, color: kPrimary),
              SizedBox(width: isWeb ? 10 : 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isWeb ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: kSubText,
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 10 : 8),
          TextFormField(
            controller: controller,
            obscureText: !isVisible.value,
            onChanged: onChanged,
            style: TextStyle(fontSize: isWeb ? 14 : 13, color: kText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: isWeb ? 13 : 12,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                borderSide: BorderSide(color: kBorder.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                borderSide: const BorderSide(color: kPrimary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                borderSide: const BorderSide(color: kDanger, width: 1),
              ),
              suffixIcon: IconButton(
                icon: Iconify(
                  isVisible.value ? Mdi.eye : Mdi.eye_off,
                  size: isWeb ? 22 : 20,
                  color: kSubText,
                ),
                onPressed: onToggle,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isWeb ? 16 : 14,
                vertical: isWeb ? 16 : 14,
              ),
            ),
          ),
          if (error.value.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isWeb ? 8 : 6, left: isWeb ? 8 : 6),
              child: Row(
                children: [
                  Iconify(
                    Mdi.alert_circle,
                    size: isWeb ? 14 : 12,
                    color: kDanger,
                  ),
                  SizedBox(width: isWeb ? 8 : 6),
                  Expanded(
                    child: Text(
                      error.value,
                      style: TextStyle(
                        fontSize: isWeb ? 11 : 10,
                        color: kDanger,
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

  Widget _buildPasswordRequirements(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Container(
      padding: EdgeInsets.all(isWeb ? 16 : 14),
      decoration: BoxDecoration(
        color: kBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
        border: Border.all(color: kBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Iconify(Mdi.shield_check, size: isWeb ? 18 : 16, color: kSuccess),
              SizedBox(width: isWeb ? 10 : 8),
              Text(
                'Password Requirements:',
                style: TextStyle(
                  fontSize: isWeb ? 13 : 12,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 12 : 10),
          _buildRequirementItem('Minimum 6 characters', context),
          if (!isForgotFlow)
            _buildRequirementItem('Cannot be same as current password', context),
          _buildRequirementItem(
            'Should be different from previous passwords',
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 8 : 6, left: isWeb ? 24 : 20),
      child: Row(
        children: [
          Iconify(Mdi.check_circle, size: isWeb ? 14 : 12, color: kSuccess),
          SizedBox(width: isWeb ? 10 : 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: isWeb ? 11 : 10, color: kSubText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeButton(
    ChangePasswordController controller,
    BuildContext context,
  ) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: ResponsiveUtils.getButtonHeight(context),
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : controller.changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
            ),
          ),
          child: controller.isLoading.value
              ? Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: ResponsiveUtils.isWeb(context) ? 32 : 40,
                  ),
                )
                : Text(
                  isForgotFlow ? 'Reset Password' : 'Change Password',
                  style: TextStyle(
                    fontSize: isWeb ? 15 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _tipPill(String icon, String label) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
