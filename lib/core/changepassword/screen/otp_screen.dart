import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/changepassword/controller/Otp_controller.dart';
import 'package:BisonsTechs_app/core/changepassword/screen/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/mdi.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final OTPController controller;
  late final FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    controller = Get.put(OTPController());
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
      if (controller.isLoading.value) return;
      if (!controller.isOtpSent.value) {
        controller.sendOTP();
      } else {
        controller.verifyOTP();
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
        backgroundColor: kBg,
        body: ResponsiveUtils.isWeb(context)
            ? _buildWebLayout(context)
            : _buildMobileTabletLayout(context),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WEB LAYOUT
  // ═══════════════════════════════════════════════════════════════════
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
                // Unsplash warehouse image — consistent with login screens
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

                      // Tagline
                      const Text(
                        'Account Recovery\nMade Simple',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Follow the steps to securely reset your\npassword and regain access to your account.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13.5,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Recovery steps inline
                      _recoveryStepPill('1', 'Enter your registered email'),
                      const SizedBox(height: 10),
                      _recoveryStepPill('2', 'Receive OTP on your email'),
                      const SizedBox(height: 10),
                      _recoveryStepPill('3', 'Enter the 6-digit OTP'),
                      const SizedBox(height: 10),
                      _recoveryStepPill('4', 'Create your new password'),
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
                  child: Obx(() {
                    if (controller.isOtpVerified.value) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Get.off(
                          () => const ChangePasswordScreen(isForgotFlow: true),
                        );
                      });
                      return const SizedBox.shrink();
                    }
                    if (!controller.isOtpSent.value) {
                      return _buildEmailContent(context);
                    } else {
                      return _buildOTPContent(context);
                    }
                  }),
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
  Widget _buildMobileTabletLayout(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildMobileAppBar(context),
      body: Obx(() {
        if (controller.isOtpVerified.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.off(
              () => const ChangePasswordScreen(isForgotFlow: true),
            );
          });
          return const SizedBox.shrink();
        }
        return SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Center(
            child: SizedBox(
              width: ResponsiveUtils.getFormWidth(context),
              child: Column(
                children: [
                  SizedBox(height: isTablet ? 16 : 8),
                  if (!controller.isOtpSent.value)
                    _buildEmailScreen(context)
                  else
                    _buildOTPScreen(context),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // WEB CONTENT
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildEmailContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWebHeader('Reset Password', 'Enter your email address'),
        const SizedBox(height: 32),
        _buildEmailField(context),
        const SizedBox(height: 32),
        _buildSendButton(context),
      ],
    );
  }

  Widget _buildOTPContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildWebHeader(
          'Verify OTP',
          'Please enter the 6-digit OTP sent to ${controller.email.value}',
        ),
        const SizedBox(height: 32),
        _buildOTPField(context),
        const SizedBox(height: 20),
        _buildTimerButton(context),
        const SizedBox(height: 32),
        _buildVerifyButton(context),
      ],
    );
  }

  Widget _buildWebHeader(String title, String subtitle) {
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
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
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
        'Forgot Password',
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
  // EMAIL SCREEN (MOBILE)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildEmailScreen(BuildContext context) {
    return Column(
      children: [
        _buildMobileHeader(
          'Reset Password',
          'Enter your email address and we\'ll send you an OTP to reset your password',
          context,
        ),
        SizedBox(height: ResponsiveUtils.isTablet(context) ? 32 : 24),
        _buildEmailField(context),
        SizedBox(height: ResponsiveUtils.isTablet(context) ? 32 : 24),
        _buildSendButton(context),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // OTP SCREEN (MOBILE)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildOTPScreen(BuildContext context) {
    return Column(
      children: [
        _buildMobileHeader(
          'Verify OTP',
          'Please enter the 6-digit OTP sent to ${controller.email.value}',
          context,
        ),
        SizedBox(height: ResponsiveUtils.isTablet(context) ? 32 : 24),
        _buildOTPField(context),
        SizedBox(height: ResponsiveUtils.isTablet(context) ? 20 : 16),
        _buildTimerButton(context),
        SizedBox(height: ResponsiveUtils.isTablet(context) ? 32 : 24),
        _buildVerifyButton(context),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MOBILE HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMobileHeader(
    String title,
    String subtitle,
    BuildContext context,
  ) {
    final isTablet = ResponsiveUtils.isTablet(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
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
            height: isTablet ? 72 : 56,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 10 : 8,
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
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // EMAIL FIELD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildEmailField(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Iconify(Mdi.email, size: isWeb ? 20 : 18, color: kPrimary),
              SizedBox(width: isWeb ? 10 : 8),
              Text(
                'Email Address',
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
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => controller.emailError.value = '',
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!controller.isLoading.value) controller.sendOTP();
            },
            style: TextStyle(fontSize: isWeb ? 14 : 13, color: kText),
            decoration: InputDecoration(
              hintText: 'Enter your email address',
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: isWeb ? 16 : 14,
                vertical: isWeb ? 16 : 14,
              ),
            ),
          ),
          if (controller.emailError.value.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isWeb ? 8 : 6, left: isWeb ? 8 : 6),
              child: Text(
                controller.emailError.value,
                style: TextStyle(fontSize: isWeb ? 11 : 10, color: kDanger),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // OTP FIELD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildOTPField(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final pinWidth = isWeb
        ? 60.0
        : (ResponsiveUtils.isTablet(context) ? 55.0 : 45.0);

    final defaultPinTheme = PinTheme(
      width: pinWidth,
      height: pinWidth,
      textStyle: TextStyle(
        fontSize: isWeb ? 20 : 18,
        fontWeight: FontWeight.w600,
        color: kText,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
        border: Border.all(color: kBorder),
      ),
    );

    return Obx(
      () => Column(
        children: [
          Row(
            children: [
              Iconify(Mdi.shield_key, size: isWeb ? 20 : 18, color: kPrimary),
              SizedBox(width: isWeb ? 10 : 8),
              Text(
                'Enter OTP',
                style: TextStyle(
                  fontSize: isWeb ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: kSubText,
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 10 : 8),
          Pinput(
            length: 6,
            controller: controller.otpController,
            onChanged: (_) => controller.otpError.value = '',
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: kPrimary, width: 2),
              ),
            ),
            errorPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: kDanger, width: 1),
              ),
            ),
            onCompleted: (_) {
              if (!controller.isLoading.value) controller.verifyOTP();
            },
          ),
          if (controller.otpError.value.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: isWeb ? 8 : 6),
              child: Text(
                controller.otpError.value,
                style: TextStyle(fontSize: isWeb ? 11 : 10, color: kDanger),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TIMER BUTTON
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTimerButton(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            controller.timerText,
            style: TextStyle(
              fontSize: isWeb ? 13 : 12,
              color: controller.timerSeconds.value == 0 ? kPrimary : kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (controller.timerSeconds.value == 0)
            TextButton(
              onPressed: controller.resendOTP,
              child: Text(
                'Resend',
                style: TextStyle(
                  fontSize: isWeb ? 13 : 12,
                  color: kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEND BUTTON
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSendButton(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: ResponsiveUtils.getButtonHeight(context),
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.sendOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
            ),
          ),
          child: controller.isLoading.value
              ? SizedBox(
                  height: isWeb ? 22 : 20,
                  width: isWeb ? 22 : 20,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Send OTP',
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
  // VERIFY BUTTON
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildVerifyButton(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: ResponsiveUtils.getButtonHeight(context),
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.verifyOTP,
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
                    size: isWeb ? 32 : 40,
                  ),
                )
              : Text(
                  'Verify OTP',
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
  Widget _recoveryStepPill(String step, String label) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF1AB4F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
