// lib/core/login/controller/login_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/changepassword/screen/otp_screen.dart';
import 'package:LedgerPro_app/core/dashboard/Screens/dashbaord_screen.dart';
import 'package:LedgerPro_app/core/loginOtp/screen/login_otp_screen.dart';
import 'package:LedgerPro_app/core/plans/controllers/subscription_controller.dart';
import 'package:LedgerPro_app/core/plans/views/Subscription_plans.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:LedgerPro_app/Services/notification_Service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      print('🔍 [LOGIN] Starting login request');
      print('🔍 [LOGIN] Email: ${emailController.text.trim()}');

      final response = await _api.post(
        '/api/users/login',
        body: {
          'email': emailController.text.trim(),
          'password': passwordController.text,
        },
        requiresAuth: false,
      );

      print('🔍 [LOGIN] API Response received');
      print('🔍 [LOGIN] Response statusCode: ${response.statusCode}');
      print('🔍 [LOGIN] Response success: ${response.success}');
      print('🔍 [LOGIN] Response message: ${response.message}');
      print('🔍 [LOGIN] Response data: ${response.data}');
      print('🔍 [LOGIN] Response isFiscalYearError: ${response.isFiscalYearError}');

      final data = response.data;

      // ✅ FIX: Check if data is null before accessing
      if (data == null) {
        print('❌ [LOGIN] Data is null');
        AppSnackbar.error(
          kDanger,
          'Error',
          'No response from server. Please try again.',
        );
        return false;
      }

      if (response.success) {
        print('✅ [LOGIN] Login successful');
        print('🔍 [LOGIN] Data keys: ${data.keys.toList()}');

        // ✅ Check if requiresOtp exists
        if (data['requiresOtp'] == true) {
          print('🔍 [LOGIN] OTP required');
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

        // ✅ FIX: Update currency after login
        await _updateCurrencyFromUser(data['user']);

        // ✅ Notification Service Setup (mobile only)
        if (!kIsWeb) {
          try {
            print('🔔🔔🔔 [LoginController] NOTIFICATION SETUP START 🔔🔔🔔');
            final userData = data['user'] as Map<String, dynamic>?;
            if (userData != null && userData['_id'] != null) {
              final userId = userData['_id'].toString();
              print('🔔 [LoginController] Setting up notification service for user: $userId');
              
              print('🔔 [LoginController] Calling NotificationService.login()...');
              await NotificationService.instance.login(userId);
              
              print('🔔 [LoginController] Calling verifyDeviceRegistration()...');
              await NotificationService.instance.verifyDeviceRegistration();
              
              print('✅ [LoginController] Notification service setup completed');
              print('🔔🔔🔔 [LoginController] NOTIFICATION SETUP END 🔔🔔🔔');
            } else {
              print('⚠️ [LoginController] User data or user ID is null, skipping notification setup');
            }
          } catch (e) {
            print('❌ [LoginController] Notification service setup error: $e');
            print('❌ [LoginController] Error type: ${e.runtimeType}');
            // Don't block login on notification error
          }
        } else {
          print('🔔 [LoginController] Running on web, skipping notification setup');
        }

        if (subscriptionController.hasAccess) {
          Get.offAllNamed('/dashboard');
        } else {
          Get.offAll(() => const SelectPlanScreen());
        }
        return true;
      } else {
        print('❌ [LOGIN] Login failed');
        print('❌ [LOGIN] Error message: ${data['message']}');
        AppSnackbar.error(
          kDanger,
          'Error',
          data['message'] ?? 'Invalid email or password',
        );
        return false;
      }
    } catch (e) {
      print('❌ [LOGIN] Exception caught: $e');
      print('❌ [LOGIN] Exception type: ${e.runtimeType}');
      AppSnackbar.error(
        kDanger,
        'Error',
        'Error. Server Down. Please try again later.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ NEW: Update currency from user data
  Future<void> _updateCurrencyFromUser(Map<String, dynamic>? userData) async {
    if (userData == null) return;

    try {
      final currencyController = Get.find<CurrencyController>();

      // Check if businessDetails has currency
      final businessDetails =
          userData['businessDetails'] as Map<String, dynamic>?;
      if (businessDetails != null) {
        final code = businessDetails['currencyCode'] as String?;
        final symbol = businessDetails['currencySymbol'] as String?;

        if (code != null &&
            code.isNotEmpty &&
            symbol != null &&
            symbol.isNotEmpty) {
          // Currency exists in user data, update controller
          await currencyController.updateFromUserData(userData);
          print('✅ Currency updated from user data: $code ($symbol)');
          return;
        }
      }

      // If no currency in user data, check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('app_currency_code');
      if (savedCode != null && savedCode.isNotEmpty) {
        await currencyController.loadFromPrefs();
        print('✅ Currency loaded from preferences: $savedCode');
      } else {
        // Use default currency
        await currencyController.loadFromPrefs();
        print('✅ Using default currency');
      }
    } catch (e) {
      print('❌ Error updating currency: $e');
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
        final userData = data['user'] as Map<String, dynamic>;
        await prefs.setString('user_data', json.encode(userData));

        // ✅ Load currency from user data
        await _updateCurrencyFromUser(userData);

        if (userData['organizationName'] != null &&
            userData['organizationName'].toString().isNotEmpty) {
          await prefs.setString('company_name', userData['organizationName']);
        } else {
          await prefs.setString('company_name', '');
        }

        if (userData['address'] != null &&
            userData['address'].toString().isNotEmpty) {
          await prefs.setString('company_address', userData['address']);
        }

        if (userData['firstName'] != null && userData['lastName'] != null) {
          await prefs.setString(
            'user_name',
            '${userData['firstName']} ${userData['lastName']}',
          );
        }

        if (userData['email'] != null) {
          await prefs.setString('user_email', userData['email']);
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
