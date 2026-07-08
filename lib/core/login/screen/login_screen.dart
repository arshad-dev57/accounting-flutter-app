// lib/core/login/screen/login_screen.dart

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/Register/Views/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController controller;
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoginController());
    _keyboardFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      if (!controller.isLoading.value) {
        controller.login();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ResponsiveUtils.isWeb(context)
            ? _buildWebLayout(context)
            : _buildMobileTabletLayout(context),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // WEB LAYOUT
  // ══════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context) {
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
                // Unsplash warehouse / logistics image
                Image.network(
                  'https://images.unsplash.com/photo-1553413077-190dd305871c?w=900&q=80&fit=crop',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: kPrimaryDark,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: kPrimary,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, _, __) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [kPrimaryDark, kPrimary],
                      ),
                    ),
                  ),
                ),

                // Dark gradient overlay — stronger at bottom for readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),

                // Tinted blue overlay for brand cohesion
                Container(color: kPrimary.withOpacity(0.25)),

                // Branding content pinned to bottom-left
                Positioned(
                  left: 36,
                  right: 36,
                  bottom: 48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo lockup
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'LedgerPro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Tagline
                      const Text(
                        'Complete Warehouse &\nAccounting Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Track inventory, manage ledgers, and generate\nfinancial reports — all in one platform.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13.5,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Feature pills
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _featurePill(
                            Icons.inventory_2_outlined,
                            'Inventory Tracking',
                          ),
                          _featurePill(
                            Icons.receipt_long_outlined,
                            'Invoicing',
                          ),
                          _featurePill(
                            Icons.analytics_outlined,
                            'Financial Reports',
                          ),
                          _featurePill(
                            Icons.warehouse_outlined,
                            'Warehouse Ops',
                          ),
                        ],
                      ),
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
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buildLoginForm(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // MOBILE & TABLET LAYOUT
  // ══════════════════════════════════════════════════
  Widget _buildMobileTabletLayout(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: ResponsiveUtils.getScreenPadding(context),
        child: Center(
          child: SizedBox(
            width: ResponsiveUtils.getFormWidth(context),
            child: _buildLoginForm(context),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // SHARED LOGIN FORM
  // ══════════════════════════════════════════════════
  Widget _buildLoginForm(BuildContext context) {
    final bool isMobile = ResponsiveUtils.isMobile(context);
    final bool isTablet = ResponsiveUtils.isTablet(context);
    final bool isWeb = ResponsiveUtils.isWeb(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button — mobile/tablet only
        if (!isWeb)
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back,
              color: kPrimary,
              size: isMobile ? 24 : 20,
            ),
            onPressed: () => Get.back(),
          ),
        if (!isWeb) const SizedBox(height: 16),

        // Logo + app name — mobile/tablet only
        if (!isWeb)
          Center(
            child: Column(
              children: [
                Container(
                  width: ResponsiveUtils.getLogoSize(context),
                  height: ResponsiveUtils.getLogoSize(context),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimary, kPrimaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getLogoSize(context) * 0.22,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance,
                    color: Colors.white,
                    size: ResponsiveUtils.getLogoSize(context) * 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'LedgerPro',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

        // Welcome heading
        Center(
          child: Column(
            children: [
              Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getHeadingFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: kTextLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to continue to your account',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getSubheadingFontSize(context),
                  color: kSubTextLight,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Email
        _fieldLabel('Email Address', context),
        const SizedBox(height: 8),
        Obx(
          () => _buildTextField(
            controller: controller.emailController,
            onChanged: (_) => controller.clearEmailError(),
            keyboardType: TextInputType.emailAddress,
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            errorText: controller.emailError.value.isEmpty
                ? null
                : controller.emailError.value,
            context: context,
            textInputAction: TextInputAction.next,
          ),
        ),

        const SizedBox(height: 20),

        // Password
        _fieldLabel('Password', context),
        const SizedBox(height: 8),
        Obx(
          () => _buildTextField(
            controller: controller.passwordController,
            onChanged: (_) => controller.clearPasswordError(),
            obscureText: !controller.isPasswordVisible.value,
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                controller.isPasswordVisible.value
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: kSubTextLight,
                size: 22,
              ),
              onPressed: () => controller.isPasswordVisible.toggle(),
            ),
            errorText: controller.passwordError.value.isEmpty
                ? null
                : controller.passwordError.value,
            context: context,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!controller.isLoading.value) controller.login();
            },
          ),
        ),

        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => controller.forgotPassword(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            ),
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                color: kPrimary,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveUtils.getSubheadingFontSize(context),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Sign In button
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.getButtonHeight(context),
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () async {
                      await controller.login();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: kBorderLight, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(color: kSubTextLight, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: kBorderLight, thickness: 1)),
          ],
        ),

        const SizedBox(height: 24),

        // Sign Up
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(
                color: kSubTextLight,
                fontSize: ResponsiveUtils.getSubheadingFontSize(context),
              ),
            ),
            GestureDetector(
              onTap: () => Get.to(() =>  RegistrationScreen()),
              child: Text(
                'Sign Up',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getSubheadingFontSize(context),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, BuildContext context) => Text(
    label,
    style: TextStyle(
      fontSize: ResponsiveUtils.getSubheadingFontSize(context),
      fontWeight: FontWeight.w600,
      color: kTextLight,
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required void Function(String) onChanged,
    required String hint,
    required IconData prefixIcon,
    required BuildContext context,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? errorText,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: 14, color: kTextLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: kSubTextLight.withOpacity(0.5),
          fontSize: 13,
        ),
        prefixIcon: Icon(prefixIcon, color: kSubTextLight, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: kBgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger, width: 2),
        ),
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
