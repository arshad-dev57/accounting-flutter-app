// lib/core/changepassword/controller/change_password_controller.dart

import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';

class ChangePasswordController extends GetxController {
  ChangePasswordController({this.isForgotFlow = false});

  /// Forgot-password (email + OTP) must not ask for the current password.
  final bool isForgotFlow;

  // Observable variables
  var isLoading = false.obs;
  var isOldPasswordVisible = false.obs;
  var isNewPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;

  // Form controllers
  late TextEditingController oldPasswordController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;

  // Error messages
  var oldPasswordError = ''.obs;
  var newPasswordError = ''.obs;
  var confirmPasswordError = ''.obs;

  final ApiClient _api = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
  }

  void _initializeControllers() {
    oldPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  // Clear errors when typing
  void clearOldPasswordError() {
    if (oldPasswordError.value.isNotEmpty) {
      oldPasswordError.value = '';
    }
  }

  void clearNewPasswordError() {
    if (newPasswordError.value.isNotEmpty) {
      newPasswordError.value = '';
    }
  }

  void clearConfirmPasswordError() {
    if (confirmPasswordError.value.isNotEmpty) {
      confirmPasswordError.value = '';
    }
  }

  // Toggle password visibility
  void toggleOldPasswordVisibility() {
    isOldPasswordVisible.value = !isOldPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // Validate form
  bool _validateForm() {
    bool isValid = true;

    if (!isForgotFlow) {
      if (oldPasswordController.text.isEmpty) {
        oldPasswordError.value = 'Please enter current password';
        isValid = false;
      } else if (oldPasswordController.text.length < 6) {
        oldPasswordError.value = 'Password must be at least 6 characters';
        isValid = false;
      } else {
        oldPasswordError.value = '';
      }
    } else {
      oldPasswordError.value = '';
    }

    // New password validation
    if (newPasswordController.text.isEmpty) {
      newPasswordError.value = 'Please enter new password';
      isValid = false;
    } else if (newPasswordController.text.length < 6) {
      newPasswordError.value = 'Password must be at least 6 characters';
      isValid = false;
    } else if (!isForgotFlow &&
        newPasswordController.text == oldPasswordController.text) {
      newPasswordError.value = 'New password cannot be same as old password';
      isValid = false;
    } else {
      newPasswordError.value = '';
    }

    // Confirm password validation
    if (confirmPasswordController.text.isEmpty) {
      confirmPasswordError.value = 'Please confirm new password';
      isValid = false;
    } else if (confirmPasswordController.text != newPasswordController.text) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    } else {
      confirmPasswordError.value = '';
    }

    return isValid;
  }

  Future<void> changePassword() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final response = isForgotFlow
          ? await _resetPassword()
          : await _api.post(
              '/api/users/change-password',
              body: {
                'currentPassword': oldPasswordController.text,
                'newPassword': newPasswordController.text,
              },
            );

      if (response.success) {
        final data = response.data;
        _showSuccess(
          (data is Map ? data['message'] : null) ??
              (isForgotFlow
                  ? 'Password reset successfully!'
                  : 'Password changed successfully!'),
        );
        _clearForm();
        await _clearResetToken();
        await _api.clearToken();

        Get.offAll(() => const LoginScreen());
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final data = response.data;
        _showError(
          (data is Map ? data['message'] : null) ??
              response.message ??
              (isForgotFlow
                  ? 'Unable to reset password'
                  : 'Invalid current password'),
        );
      } else {
        _showError(
          isForgotFlow
              ? 'Failed to reset password. Please try again.'
              : 'Failed to change password. Please try again.',
        );
      }
    } catch (e) {
      print('Error changing password: $e');
      _showError('Error. Server Down. Please try again later.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<ApiResponse> _resetPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final resetToken =
        prefs.getString('reset_token') ?? prefs.getString('auth_token') ?? '';

    if (resetToken.isEmpty) {
      return ApiResponse(
        statusCode: 401,
        data: null,
        success: false,
        message: 'Reset session expired. Please request a new OTP.',
      );
    }

    await _api.setToken(resetToken);
    return _api.post(
      '/api/users/reset-password',
      body: {
        'newPassword': newPasswordController.text,
        'confirmPassword': confirmPasswordController.text,
      },
    );
  }

  Future<void> _clearResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reset_token');
  }

  void _clearForm() {
    oldPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    oldPasswordError.value = '';
    newPasswordError.value = '';
    confirmPasswordError.value = '';
  }

  void _showError(String message) {
    AppSnackbar.error(
      Colors.red,
      'Error',
      message,
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccess(String message) {
    AppSnackbar.success(
      Colors.green,
      'Success',
      message,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void onClose() {
    try {
      oldPasswordController.dispose();
    } catch (_) {}
    try {
      newPasswordController.dispose();
    } catch (_) {}
    try {
      confirmPasswordController.dispose();
    } catch (_) {}
    super.onClose();
  }
}
