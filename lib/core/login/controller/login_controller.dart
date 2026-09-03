// lib/core/login/controller/login_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/changepassword/screen/otp_screen.dart';
import 'package:BisonsTechs_app/core/loginOtp/screen/login_otp_screen.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/settings/controller/pdf_report_settings_controller.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Services/notification_service.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/location_query.dart';
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
    ensureFreshControllers();
  }

  /// Get.offAll can dispose the previous Login route while this controller
  /// is still reused. Always bind a live pair of text controllers.
  void ensureFreshControllers() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    emailError.value = '';
    passwordError.value = '';
  }

  @override
  void onClose() {
    // Text controllers are owned for the life of the login UI. Get.offAll can
    // close this controller while a new LoginScreen still holds the instance.
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

        // ✅ FIX: Update currency after login
        await _updateCurrencyFromUser(data['user']);

        // ✅ Notification Service Setup (mobile only)
        if (!kIsWeb) {
          try {
            final userData = data['user'] as Map<String, dynamic>?;
            if (userData != null && userData['_id'] != null) {
              final userId = userData['_id'].toString();

              await NotificationService.instance.login(userId, token: data['token']?.toString());

            } else {
            }
          } catch (e) {
            // Don't block login on notification error
          }
        } else {
        }

        if (subscriptionController.hasAccess) {
          final fy = Get.isRegistered<FiscalYearController>()
              ? Get.find<FiscalYearController>()
              : Get.put(FiscalYearController(), permanent: true);
          await fy.ensureFiscalYearsLoaded(force: true);
          subscriptionController.goToAppHome();
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
          return;
        }
      }

      // If no currency in user data, check SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString('app_currency_code');
      if (savedCode != null && savedCode.isNotEmpty) {
        await currencyController.loadFromPrefs();
      } else {
        // Use default currency
        await currencyController.loadFromPrefs();
      }
    } catch (e) {
      debugPrint('Error: $e');
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

        final userId = userData['_id']?.toString() ?? userData['id']?.toString() ?? '';
        if (userId.isNotEmpty) {
          await prefs.setString('auth_user_id', userId);
        }

        // ✅ Save user data in format expected by PermissionService
        final permissionService = Get.find<PermissionService>();
        final permissionsList = userData['permissions'] as List<dynamic>?;
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
          id: userData['_id']?.toString() ?? userData['id']?.toString() ?? '',
          firstName: userData['firstName']?.toString() ?? '',
          lastName: userData['lastName']?.toString() ?? '',
          email: userData['email']?.toString() ?? '',
          role: (userData['role']?.toString().trim().isNotEmpty ?? false)
              ? userData['role'].toString()
              : 'user',
          permissions: userPermissions,
        );

        await permissionService.saveUserData(userDataForPermissions);

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

        await PdfReportSettingsController.persistFromLogin(
          data['pdfReportSettings'] ?? userData['pdfReportSettings'],
        );

        await hydrateLocationsAfterAuth(userData);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void forgotPassword() {
    Get.to(() => const OtpScreen());
  }
}
