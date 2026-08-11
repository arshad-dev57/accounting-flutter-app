// lib/core/loginOtp/controller/login_otp_controller.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Services/notification_Service.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/settings/controller/pdf_report_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginOtpController extends GetxController {
  final String email;
  LoginOtpController({required this.email});

  final ApiClient _api = Get.find<ApiClient>();

  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();

  var isLoading = false.obs;
  var isResending = false.obs;
  var otpError = ''.obs;

  // OTP expiry countdown (5 minutes = 300 seconds)
  var expirySeconds = 300.obs;
  // Resend cooldown (60 seconds after each send)
  var resendCooldown = 0.obs;

  Timer? _expiryTimer;
  Timer? _resendTimer;

  @override
  void onInit() {
    super.onInit();
    _startExpiryTimer();
    _startResendCooldown();
  }

  @override
  void onClose() {
    _expiryTimer?.cancel();
    _resendTimer?.cancel();
    pinController.dispose();
    pinFocusNode.dispose();
    super.onClose();
  }

  void _startExpiryTimer() {
    expirySeconds.value = 300;
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (expirySeconds.value > 0) {
        expirySeconds.value--;
      } else {
        timer.cancel();
        otpError.value = 'OTP expired. Please request a new code.';
      }
    });
  }

  void _startResendCooldown() {
    resendCooldown.value = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value > 0) {
        resendCooldown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  String get expiryTimerText {
    final m = expirySeconds.value ~/ 60;
    final s = expirySeconds.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get resendButtonText {
    if (resendCooldown.value > 0) {
      final s = resendCooldown.value;
      return 'Resend in 00:${s.toString().padLeft(2, '0')}';
    }
    return 'Resend Code';
  }

  bool get canResend => resendCooldown.value == 0 && !isResending.value;

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

      // ✅ PRINT THE RESPONSE FOR LOGIN/OTP VERIFICATION
      print('🔐 VERIFY OTP API RESPONSE: ${json.encode(data)}');

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

        // ✅ Notification Service Setup (mobile only)
        if (!kIsWeb) {
          try {
            print(
              '🔔🔔🔔 [LoginOtpController] NOTIFICATION SETUP START 🔔🔔🔔',
            );
            final userData = data['user'] as Map<String, dynamic>?;
            if (userData != null && userData['id'] != null) {
              final userId = userData['id'].toString();
              print(
                '🔔 [LoginOtpController] Setting up notification service for user: $userId',
              );

              print(
                '🔔 [LoginOtpController] Calling NotificationService.login()...',
              );
              await NotificationService.instance.login(userId);

              print(
                '🔔 [LoginOtpController] Calling verifyDeviceRegistration()...',
              );
              await NotificationService.instance.verifyDeviceRegistration();

              print(
                '✅ [LoginOtpController] Notification service setup completed',
              );
              print(
                '🔔🔔🔔 [LoginOtpController] NOTIFICATION SETUP END 🔔🔔🔔',
              );
            } else {
              print(
                '⚠️ [LoginOtpController] User data or user ID is null, skipping notification setup',
              );
            }
          } catch (e) {
            print(
              '❌ [LoginOtpController] Notification service setup error: $e',
            );
            print('❌ [LoginOtpController] Error type: ${e.runtimeType}');
            // Don't block login on notification error
          }
        } else {
          print(
            '🔔 [LoginOtpController] Running on web, skipping notification setup',
          );
        }

        if (subscriptionController.hasAccess) {
          Get.offAllNamed('/dashboard');
        } else {
          Get.offAll(() => const SelectPlanScreen());
        }
      } else {
        final msg = data['message'] ?? 'Invalid OTP. Please try again.';
        otpError.value = msg;
        AppSnackbar.error(kDanger, 'Invalid Code', msg);
        clearPin();
      }
    } catch (e) {
      print('OTP verification error: $e');
      const msg = 'Something went wrong. Please try again.';
      otpError.value = msg;
      AppSnackbar.error(kDanger, 'Error', msg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResend) return;

    isResending.value = true;
    otpError.value = '';

    try {
      final response = await _api.post(
        '/api/users/resend-login-otp',
        body: {'email': email},
        requiresAuth: false,
      );

      if (response.success) {
        AppSnackbar.success(
          kSuccess,
          'Code Sent',
          'A new OTP has been sent to $email',
        );
        clearPin();
        _startExpiryTimer();
        _startResendCooldown();
      } else {
        final msg =
            response.data?['message'] ?? 'Failed to resend. Please try again.';
        AppSnackbar.error(kDanger, 'Error', msg);
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Failed to resend. Please try again.');
    } finally {
      isResending.value = false;
    }
  }

  Future<void> _saveUserData(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ Safe token saving with null check
      final token = data['token']?.toString().trim() ?? '';
      final refreshToken = data['refreshToken']?.toString().trim() ?? '';

      if (token.isNotEmpty && refreshToken.isNotEmpty) {
        await _api.setBothTokens(token, refreshToken);
      } else {
        print('Warning: Tokens are empty');
      }

      // ✅ Safe user data saving
      if (data['user'] != null) {
        final user = data['user'];
        await prefs.setString('user_data', json.encode(user));

        // ✅ Save user data in format expected by PermissionService
        final permissionService = Get.find<PermissionService>();
        final permissionsList = user['permissions'] as List<dynamic>?;
        final userPermissions =
            permissionsList?.map((p) {
              if (p is Map<String, dynamic>) {
                return UserPermission(
                  id: p['id']?.toString() ?? '',
                  page: p['page']?.toString() ?? '',
                  canView: p['canView'] ?? true,
                  canCreate: p['canCreate'] ?? false,
                  canEdit: p['canEdit'] ?? false,
                  canDelete: p['canDelete'] ?? false,
                );
              }
              return UserPermission(id: '', page: p.toString(), canView: true);
            }).toList() ??
            [];

        final userDataForPermissions = UserData(
          id: user['_id']?.toString() ?? user['id']?.toString() ?? '',
          firstName: user['firstName']?.toString() ?? '',
          lastName: user['lastName']?.toString() ?? '',
          email: user['email']?.toString() ?? '',
          role: user['role']?.toString() ?? 'user',
          permissions: userPermissions,
        );

        await permissionService.saveUserData(userDataForPermissions);
        print('✅ [OTP] User data saved for PermissionService');

        // Sync/load currency dynamically from database payload
        Get.find<CurrencyController>().updateFromUserData(user);

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

        // Restore PDF branding after logout cleared local prefs
        await PdfReportSettingsController.persistFromLogin(
          data['pdfReportSettings'] ?? user['pdfReportSettings'],
        );
      } else {
        print('Warning: User data is null');
      }
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }
}
