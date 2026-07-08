// lib/core/login/controller/login_controller.dart

import 'package:LedgerPro_app/core/changepassword/screen/otp_screen.dart';
import 'package:LedgerPro_app/core/dashboard/Screens/dashbaord_screen.dart';
import 'package:LedgerPro_app/core/loginOtp/screen/login_otp_screen.dart';
import 'package:LedgerPro_app/core/plans/controllers/subscription_controller.dart';
import 'package:LedgerPro_app/core/plans/views/Subscription_plans.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LedgerPro_app/Services/api_client.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  var isPasswordVisible = false.obs;
  var emailError = ''.obs;
  var passwordError = ''.obs;

  final ApiClient _api = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void clearEmailError() {
    if (emailError.value.isNotEmpty) emailError.value = '';
  }

  void clearPasswordError() {
    if (passwordError.value.isNotEmpty) passwordError.value = '';
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _validateForm() {
    bool isValid = true;

    if (emailController.text.trim().isEmpty) {
      emailError.value = 'Please enter email';
      isValid = false;
    } else if (!_isValidEmail(emailController.text.trim())) {
      emailError.value = 'Please enter a valid email';
      isValid = false;
    } else {
      emailError.value = '';
    }

    if (passwordController.text.isEmpty) {
      passwordError.value = 'Please enter password';
      isValid = false;
    } else if (passwordController.text.length < 6) {
      passwordError.value = 'Password must be at least 6 characters';
      isValid = false;
    } else {
      passwordError.value = '';
    }

    return isValid;
  }

  Future<bool> login() async {
    if (!_validateForm()) return false;

    isLoading.value = true;

    try {
      final response = await _api.post(
        '/api/users/login',
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
        requiresAuth: false,
      );

      final data = response.data;

      // ✅ FIX: Check if data is null before accessing
      if (data == null) {
        AppSnackbar.error(
          kDanger,
          'Error',
          'No response from server. Please try again.',
        );
        return false;
      }

      if (response.success) {
        // ✅ Check if requiresOtp exists
        if (data['requiresOtp'] == true) {
          Get.to(
            () => LoginOtpScreen(
              email: data['email'] ?? emailController.text.trim(),
            ),
          );
          return false;
        }

        // Backup — normal flow
        await _saveUserData(data);
        final subscriptionController = Get.find<SubscriptionController>();
        await subscriptionController.checkSubscriptionStatus();
        AppSnackbar.success(kSuccess, 'Success', 'Login successful!');
        if (subscriptionController.hasAccess) {
          Get.offAllNamed('/dashboard');
        } else {
          Get.offAll(() => const SelectPlanScreen());
        }
        return true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          data['message'] ?? 'Invalid email or password',
        );
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      AppSnackbar.error(
        kDanger,
        'Error',
        'Error. Please check your connection.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveUserData(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ FIX: Check if token exists before saving
      if (data['token'] != null) {
        await _api.setBothTokens(data['token'], data['refreshToken']);
      }

      // ✅ FIX: Check if user exists before saving
      if (data['user'] != null) {
        await prefs.setString('user_data', json.encode(data['user']));

        if (data['user']['organizationName'] != null &&
            data['user']['organizationName'].toString().isNotEmpty) {
          await prefs.setString(
            'company_name',
            data['user']['organizationName'],
          );
        } else {
          await prefs.setString('company_name', '');
        }

        if (data['user']['address'] != null &&
            data['user']['address'].toString().isNotEmpty) {
          await prefs.setString('company_address', data['user']['address']);
        }

        if (data['user']['firstName'] != null &&
            data['user']['lastName'] != null) {
          await prefs.setString(
            'user_name',
            '${data['user']['firstName']} ${data['user']['lastName']}',
          );
        }

        if (data['user']['email'] != null) {
          await prefs.setString('user_email', data['user']['email']);
        }
      }
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  void forgotPassword() {
    Get.to(() => const OtpScreen());
  }
}
