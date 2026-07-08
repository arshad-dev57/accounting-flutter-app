import 'dart:async';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LedgerPro_app/Services/api_client.dart';

class OTPController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var isOtpSent = false.obs;
  var isOtpVerified = false.obs;
  var timerSeconds = 0.obs;
  var email = ''.obs;
  var resetToken = ''.obs;

  // Form controllers
  late TextEditingController emailController;
  late TextEditingController otpController;

  // Error messages
  var emailError = ''.obs;
  var otpError = ''.obs;

  Timer? _timer;
  final ApiClient _api = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    otpController = TextEditingController();
  }

  // Send OTP
  Future<void> sendOTP() async {
    if (emailController.text.trim().isEmpty) {
      emailError.value = 'Please enter email address';
      return;
    }
    if (!emailController.text.contains('@') ||
        !emailController.text.contains('.')) {
      emailError.value = 'Please enter a valid email';
      return;
    }

    emailError.value = '';
    isLoading.value = true;

    try {
      final response = await _api.post(
        '/api/users/forgot-password',
        body: {'email': emailController.text.trim()},
        requiresAuth: false,
      );

      final data = response.data;

      if (response.success) {
        email.value = emailController.text.trim();
        isOtpSent.value = true;
        _startTimer();
        AppSnackbar.success(
          Colors.green,
          'Success',
          data['message'] ?? 'OTP sent to your email',
        );
      } else {
        AppSnackbar.success(
          Colors.red,
          'Error',
          data['message'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      AppSnackbar.success(Colors.red, 'Error', 'error. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP
  Future<void> verifyOTP() async {
    if (otpController.text.trim().isEmpty) {
      otpError.value = 'Please enter OTP';
      return;
    }
    if (otpController.text.trim().length != 6) {
      otpError.value = 'Please enter valid 6-digit OTP';
      return;
    }

    otpError.value = '';
    isLoading.value = true;

    try {
      final response = await _api.post(
        '/api/users/verify-otp',
        body: {'email': email.value, 'otp': otpController.text.trim()},
        requiresAuth: false,
      );

      final data = response.data;

      if (response.success) {
        // ✅ Get resetToken from response
        String token = data['resetToken'] ?? '';
        resetToken.value = token;

        // ✅ Store resetToken in SharedPreferences
        if (token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          print('Auth token stored in SharedPreferences: $token');
        }

        isOtpVerified.value = true;
        _stopTimer();

        AppSnackbar.success(
          Colors.green,
          'Success',
          data['message'] ?? 'OTP verified successfully',
        );
      } else {
        AppSnackbar.success(
          Colors.red,
          'Error',
          data['message'] ?? 'Invalid OTP',
        );
      }
    } catch (e) {
      print('Verify OTP Error: $e');
      AppSnackbar.success(Colors.red, 'Error', 'error. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Get reset token from SharedPreferences
  Future<String?> getResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('reset_token');
  }

  // ✅ Clear reset token from SharedPreferences
  Future<void> clearResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reset_token');
    print('Reset token cleared from SharedPreferences');
  }

  void _startTimer() {
    timerSeconds.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resendOTP() {
    if (timerSeconds.value == 0) {
      sendOTP();
    }
  }

  String get timerText {
    if (timerSeconds.value == 0) {
      return 'Resend OTP';
    }
    int minutes = timerSeconds.value ~/ 60;
    int seconds = timerSeconds.value % 60;
    return 'Resend in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void clearErrors() {
    emailError.value = '';
    otpError.value = '';
  }

  @override
  void onClose() {
    _stopTimer();
    emailController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
