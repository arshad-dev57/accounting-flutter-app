// lib/core/login/screen/login_otp_screen.dart
// Redesigned to match login_screen.dart style exactly

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../controller/login_otp_controller.dart';

class LoginOtpScreen extends StatefulWidget {
  final String email;
  const LoginOtpScreen({super.key, required this.email});

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  late final LoginOtpController controller;
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoginOtpController(email: widget.email));
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
        controller.verifyOtp();
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
  // WEB LAYOUT — matches login_screen web layout
  // ══════════════════════════════════════════════════
  Widget _buildWebLayout(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Row(
      children: [
        // ── LEFT PANEL — same as login screen ──────────
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
                Container(color: kPrimary.withOpacity(0.25)),
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
                      const Text(
                        'Your Security\nComes First',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We verify every login with a one-time code\nto keep your financial data protected.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13.5,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _featurePill(
                            Icons.lock_outlined,
                            'End-to-End Encrypted',
                          ),
                          _featurePill(
                            Icons.timer_outlined,
                            'Expires in 10 min',
                          ),
                          _featurePill(
                            Icons.verified_user_outlined,
                            'Bank-grade Security',
                          ),
                          _featurePill(
                            Icons.no_encryption_gmailerrorred_outlined,
                            'Zero Data Sharing',
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
                  child: _buildOtpForm(context),
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
            child: _buildOtpForm(context),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // SHARED OTP FORM — styled like login form
  // ══════════════════════════════════════════════════
  Widget _buildOtpForm(BuildContext context) {
    final bool isWeb = ResponsiveUtils.isWeb(context);
    final bool isTablet = ResponsiveUtils.isTablet(context);

    // Pinput themes — matches login field borders
    final defaultTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPrimary, width: 2),
      ),
    );

    final errorTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kDanger, width: 1.5),
      ),
    );

    final submittedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPrimary, width: 1.5),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App logo
        Center(
          child: Image.asset(
            'assets/logo.png',
            height: isTablet || isWeb ? 110 : 90,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.account_balance_rounded,
              size: isTablet || isWeb ? 56 : 48,
              color: kPrimary,
            ),
          ),
        ),
        SizedBox(height: isWeb ? 28 : 24),

        // ── Heading — same font/style as login "Welcome back" ──
        Text(
          'Enter the code sent\nto your email',
          style: TextStyle(
            fontSize: isTablet || isWeb ? 28 : 24,
            fontWeight: FontWeight.bold,
            color: kTextLight,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Email hint line
        RichText(
          text: TextSpan(
            text: 'A 6-digit code was sent to ',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            children: [
              TextSpan(
                text: widget.email,
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── OTP label — same as login field labels ────
        Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),

        // ── Pinput ────────────────────────────────────
        Obx(() {
          final hasError = controller.otpError.value.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pinput(
                length: 6,
                controller: controller.pinController,
                focusNode: controller.pinFocusNode,
                defaultPinTheme: defaultTheme,
                focusedPinTheme: focusedTheme,
                errorPinTheme: errorTheme,
                submittedPinTheme: submittedTheme,
                pinAnimationType: PinAnimationType.slide,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                forceErrorState: hasError,
                errorText: null,
                closeKeyboardWhenCompleted: true,
                separatorBuilder: (i) => const SizedBox(width: 8),
                onCompleted: (pin) => controller.verifyOtp(pin: pin),
                onChanged: (_) {
                  if (controller.otpError.value.isNotEmpty) {
                    controller.otpError.value = '';
                  }
                },
              ),

              // Error — same red style as login field errors
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: kDanger,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.otpError.value,
                        style: const TextStyle(color: kDanger, fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),

        const SizedBox(height: 16),

        // ── OTP expiry countdown timer ────────────────
        Obx(() {
          final expired = controller.expirySeconds.value == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: expired
                  ? kDanger.withOpacity(0.08)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: expired
                    ? kDanger.withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  expired ? Icons.timer_off_outlined : Icons.timer_outlined,
                  size: 16,
                  color: expired ? kDanger : Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  expired
                      ? 'Code expired — request a new one'
                      : 'Code expires in ${controller.expiryTimerText}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: expired ? kDanger : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),

        // ── Verify button — same pill style as login "Log in" button ──
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.verifyOtp(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
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
                      'Verify & Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── Divider — same as login ───────────────────
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),

        const SizedBox(height: 24),

        // ── Resend code button ────────────────────────
        Obx(() {
          final canResend = controller.canResend;
          final isResending = controller.isResending.value;
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: canResend ? controller.resendOtp : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: canResend
                      ? Colors.grey.shade400
                      : Colors.grey.shade300,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                disabledForegroundColor: Colors.grey.shade400,
              ),
              child: isResending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey.shade500,
                      ),
                    )
                  : Text(
                      controller.resendButtonText,
                      style: TextStyle(
                        color: canResend
                            ? Colors.black
                            : Colors.grey.shade500,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          );
        }),

        const SizedBox(height: 32),

        // ── Bottom hint — same style as login "Don't have an account?" ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Wrong email? ',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () => Get.back(),
              child: Text(
                'Go back',
                style: TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────
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
}
