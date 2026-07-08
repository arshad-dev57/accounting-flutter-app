import 'package:LedgerPro_app/Utils/responsive_utils.dart';
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
                // Same Unsplash warehouse image as login screen
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

                // Dark gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Color(0xCC000000)],
                    ),
                  ),
                ),

                // Blue brand tint
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
                      // Logo lockup
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1AB4F5),
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

                      // Security-focused tagline for OTP screen
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

                      // Security feature pills
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
  // SHARED OTP FORM
  // ══════════════════════════════════════════════════
  Widget _buildOtpForm(BuildContext context) {
    final bool isMobile = ResponsiveUtils.isMobile(context);
    final bool isTablet = ResponsiveUtils.isTablet(context);
    final bool isWeb = ResponsiveUtils.isWeb(context);

    // ── Pinput themes ──────────────────────────────
    final defaultTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1AB4F5), width: 2),
      ),
    );

    final errorTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
    );

    final submittedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1AB4F5), width: 1.5),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button — mobile/tablet only
        if (!isWeb)
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back,
              color: const Color(0xFF1AB4F5),
              size: isMobile ? 24 : 20,
            ),
            onPressed: () => Get.back(),
          ),
        if (!isWeb) const SizedBox(height: 16),

        // Logo — mobile/tablet only
        if (!isWeb)
          Center(
            child: Column(
              children: [
                Container(
                  width: ResponsiveUtils.getLogoSize(context),
                  height: ResponsiveUtils.getLogoSize(context),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1AB4F5), Color(0xFF0D8CBF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getLogoSize(context) * 0.22,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1AB4F5).withOpacity(0.3),
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
                    color: const Color(0xFF1AB4F5),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

        // Shield icon
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1AB4F5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1AB4F5).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: Color(0xFF1AB4F5),
              size: 36,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Heading
        Center(
          child: Column(
            children: [
              Text(
                'Verify Your Identity',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getHeadingFontSize(context),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A 6-digit security code was sent to',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getSubheadingFontSize(context),
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getSubheadingFontSize(context),
                  color: const Color(0xFF1AB4F5),
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // OTP label
        Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: ResponsiveUtils.getSubheadingFontSize(context),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 16),

        // ── Pinput ──────────────────────────────────
        Obx(() {
          final hasError = controller.otpError.value.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Pinput(
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
                  onCompleted: (pin) => controller.verifyOtp(pin: pin),
                  onChanged: (_) {
                    if (controller.otpError.value.isNotEmpty) {
                      controller.otpError.value = '';
                    }
                  },
                ),
              ),

              // Error message
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.otpError.value,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }),

        const SizedBox(height: 32),

        // Verify button
        Obx(
          () => SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.getButtonHeight(context),
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.verifyOtp(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1AB4F5),
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
                      'Verify & Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Security note
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Colors.grey[400], size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'LedgerPro will never ask for your OTP via phone or chat. If you didn\'t attempt to login, please secure your account immediately.',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: Text(
            'Can\'t find the email? Check your spam folder.',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
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
}
