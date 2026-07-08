// lib/core/loginOtp/controller/login_otp_controller.dart

import 'package:LedgerPro_app/core/plans/controllers/subscription_controller.dart';
import 'package:LedgerPro_app/core/plans/views/Subscription_plans.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LedgerPro_app/Services/api_client.dart';

class LoginOtpController extends GetxController {
  final String email;
  LoginOtpController({required this.email});

  final ApiClient _api = Get.find<ApiClient>();

  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();

  var isLoading = false.obs;
  var otpError = ''.obs;

  @override
  void onClose() {
    pinController.dispose();
    pinFocusNode.dispose();
    super.onClose();
  }

  void clearPin() {
    pinController.clear();
    otpError.value = '';
    pinFocusNode.requestFocus();
  }

  Future<void> verifyOtp({String? pin}) async {
    final otp = pin ?? pinController.text;

    if (otp.length != 6) {
      otpError.value = 'Please enter the complete 6-digit code';
      return;
    }

    isLoading.value = true;
    otpError.value = '';

    try {
      final response = await _api.post(
        '/api/users/verify-login-otp',
        body: {'email': email, 'otp': otp},
        requiresAuth: false,
      );

      // ✅ Check if response data is null
      if (response.data == null) {
        otpError.value = 'No response from server. Please try again.';
        return;
      }

      final data = response.data;

      if (response.success) {
        // ✅ Check if data has required fields
        if (data['token'] == null || data['user'] == null) {
          otpError.value = 'Invalid response from server. Please try again.';
          return;
        }

        // ✅ Pehle data save karo — token cache hoga
        await _saveUserData(data);

        // ✅ Ab subscription check karo — token guaranteed available hai
        final subscriptionController = Get.find<SubscriptionController>();
        await subscriptionController.checkSubscriptionStatus();

        AppSnackbar.success(kSuccess, 'Success', 'Login successful!');

        if (subscriptionController.hasAccess) {
          Get.offAllNamed('/dashboard');
        } else {
          Get.offAll(() => const SelectPlanScreen());
        }
      } else {
        otpError.value = data['message'] ?? 'Invalid OTP. Please try again.';
        clearPin();
      }
    } catch (e) {
      print('OTP verification error: $e');
      otpError.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveUserData(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Safe token saving with null check
      final token = data['token']?.toString()?.trim() ?? '';
      final refreshToken = data['refreshToken']?.toString()?.trim() ?? '';

      if (token.isNotEmpty && refreshToken.isNotEmpty) {
        await _api.setBothTokens(token, refreshToken);
      } else {
        print('Warning: Tokens are empty');
      }

      // ✅ Safe user data saving
      if (data['user'] != null) {
        final user = data['user'];
        await prefs.setString('user_data', json.encode(user));

        final orgName = user['organizationName']?.toString() ?? '';
        if (orgName.isNotEmpty) {
          await prefs.setString('company_name', orgName);
        }

        final address = user['address']?.toString() ?? '';
        if (address.isNotEmpty) {
          await prefs.setString('company_address', address);
        }

        final firstName = user['firstName']?.toString() ?? '';
        final lastName = user['lastName']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        if (fullName.isNotEmpty) {
          await prefs.setString('user_name', fullName);
        }

        final userEmail = user['email']?.toString() ?? '';
        if (userEmail.isNotEmpty) {
          await prefs.setString('user_email', userEmail);
        }
      } else {
        print('Warning: User data is null');
      }
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }
}
