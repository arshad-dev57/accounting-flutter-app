// lib/core/Register/controller/registercontroller.dart

import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/currency_controller.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/settings/controller/pdf_report_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:BisonsTechs_app/Utils/signature_dialog.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var user = Rxn<Map<String, dynamic>>();

  // ─── TEXT CONTROLLERS ──────────────────────────────────────────
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController countryController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late TextEditingController addressController;
  late TextEditingController organizationNameController;

  // ─── NEW BUSINESS DETAILS CONTROLLERS ─────────────────────────
  late TextEditingController industryController;
  late TextEditingController taxRegistrationController;
  late TextEditingController logoController; // Optional: for logo upload
  late TextEditingController
  signatureController; // Optional: for signature upload

  // ─── OBSERVABLES ──────────────────────────────────────────────
  var isPasswordVisible = false.obs;
  var isConfirmPasswordVisible = false.obs;
  var agreeToTerms = false.obs;
  var currentStep = 0.obs;
  var passwordStrength = 0.0.obs;
  var passwordStrengthText = ''.obs;
  var passwordStrengthColor = Colors.red.obs;

  var firstName = ''.obs;
  var lastName = ''.obs;
  var email = ''.obs;
  var phone = ''.obs;
  var fullPhoneNumber = ''.obs;
  var phoneCountryIso = 'PK'.obs;
  var country = ''.obs;
  var selectedCurrencyCode = ''.obs;
  var selectedCurrencyName = ''.obs;
  var selectedCurrencySymbol = ''.obs;
  var password = ''.obs;
  var confirmPassword = ''.obs;
  var address = ''.obs;
  var organizationName = ''.obs;

  // ─── NEW BUSINESS OBSERVABLES ──────────────────────────────────
  var industry = ''.obs;
  var taxRegistrationNumber = ''.obs;
  var selectedBusinessType = ''.obs;
  var selectedFiscalYear = ''.obs;
  var logo = ''.obs;
  var signature = ''.obs;

  // ─── DROPDOWN OPTIONS ──────────────────────────────────────────
  final List<String> businessTypes = [
    'Sole Proprietorship',
    'Partnership',
    'Limited Liability Company (LLC)',
    'Corporation',
    'Non-Profit Organization',
    'Cooperative',
    'Franchise',
    'Other',
  ];

  final List<String> fiscalYears = [
    'January - December',
    'July - June',
    'April - March',
    'October - September',
    'Custom',
  ];

  final ApiClient _api = Get.find<ApiClient>();
  late final FiscalYearController _fiscalYearController;

  @override
  void onInit() {
    super.onInit();
    _initControllers();
    _setupListeners();
    _fiscalYearController = Get.isRegistered<FiscalYearController>()
        ? Get.find<FiscalYearController>()
        : Get.put(FiscalYearController(), permanent: true);
    checkLoginStatus();
  }

  void _initControllers() {
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    countryController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    addressController = TextEditingController();
    organizationNameController = TextEditingController();

    // ─── NEW BUSINESS CONTROLLERS ────────────────────────────────
    industryController = TextEditingController();
    taxRegistrationController = TextEditingController();
    logoController = TextEditingController();
    signatureController = TextEditingController();
  }

  void _setupListeners() {
    firstNameController.addListener(
      () => firstName.value = firstNameController.text,
    );
    lastNameController.addListener(
      () => lastName.value = lastNameController.text,
    );
    emailController.addListener(() => email.value = emailController.text);
    phoneController.addListener(() => phone.value = phoneController.text);
    countryController.addListener(() => country.value = countryController.text);
    passwordController.addListener(() {
      password.value = passwordController.text;
      checkPasswordStrength(passwordController.text);
    });
    confirmPasswordController.addListener(
      () => confirmPassword.value = confirmPasswordController.text,
    );
    addressController.addListener(() => address.value = addressController.text);
    organizationNameController.addListener(
      () => organizationName.value = organizationNameController.text,
    );

    industryController.addListener(
      () => industry.value = industryController.text,
    );
    taxRegistrationController.addListener(
      () => taxRegistrationNumber.value = taxRegistrationController.text,
    );
  }

  Map<String, DateTime> _calculateFiscalYearDates(String periodType) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (periodType) {
      case 'January - December':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
      case 'July - June':
        if (now.month >= 7) {
          startDate = DateTime(now.year, 7, 1);
          endDate = DateTime(now.year + 1, 6, 30);
        } else {
          startDate = DateTime(now.year - 1, 7, 1);
          endDate = DateTime(now.year, 6, 30);
        }
        break;
      case 'April - March':
        if (now.month >= 4) {
          startDate = DateTime(now.year, 4, 1);
          endDate = DateTime(now.year + 1, 3, 31);
        } else {
          startDate = DateTime(now.year - 1, 4, 1);
          endDate = DateTime(now.year, 3, 31);
        }
        break;
      case 'October - September':
        if (now.month >= 10) {
          startDate = DateTime(now.year, 10, 1);
          endDate = DateTime(now.year + 1, 9, 30);
        } else {
          startDate = DateTime(now.year - 1, 10, 1);
          endDate = DateTime(now.year, 9, 30);
        }
        break;
      case 'Custom':
      default:
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
    }

    return {'startDate': startDate, 'endDate': endDate};
  }

  // Create initial fiscal year after registration only if backend did not
  Future<void> _createInitialFiscalYear() async {
    if (selectedFiscalYear.value.isEmpty) return;

    try {
      await _fiscalYearController.fetchFiscalYears();
      if (_fiscalYearController.fiscalYears.isNotEmpty) {
        print('✅ Fiscal year already created during registration');
        return;
      }

      final dates = _calculateFiscalYearDates(selectedFiscalYear.value);
      final startYear = dates['startDate']!.year;
      final endYear = dates['endDate']!.year;
      final name =
          startYear == endYear ? 'FY $startYear' : 'FY $startYear-$endYear';

      final success = await _fiscalYearController.createFiscalYear(
        name: name,
        startDate: dates['startDate']!,
        endDate: dates['endDate']!,
        periodType: selectedFiscalYear.value,
      );

      if (success) {
        print('✅ Initial fiscal year created successfully');
      }
    } catch (e) {
      print('❌ Failed to create initial fiscal year: $e');
    }
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    countryController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    organizationNameController.dispose();
    industryController.dispose();
    taxRegistrationController.dispose();
    logoController.dispose();
    signatureController.dispose();
    super.onClose();
  }

  Future<void> pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      logoController.text = image.path;
      logo.value = image.path;
    }
  }

  Future<void> drawSignature(BuildContext context) async {
    final String? path = await showSignatureDialog(context);
    if (path != null) {
      signatureController.text = path;
      signature.value = path;
    }
  }

  Future<void> pickSignatureFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      signatureController.text = image.path;
      signature.value = image.path;
    }
  }

  Future<bool> register() async {
    print("🚀 Register function started at step: ${currentStep.value}");

    if (currentStep.value == 0) {
      if (firstNameController.text.trim().isEmpty) {
        AppSnackbar.error(kDanger, 'Error', 'Please enter first name');
        return false;
      }
      if (lastNameController.text.trim().isEmpty) {
        AppSnackbar.error(kDanger, 'Error', 'Please enter last name');
        return false;
      }
      if (countryController.text.trim().isEmpty) {
        AppSnackbar.error(kDanger, 'Error', 'Please select country');
        return false;
      }
      if (selectedCurrencyCode.value.isEmpty) {
        AppSnackbar.error(kDanger, 'Error', 'Please select currency');
        return false;
      }
      currentStep.value = 1;
      return true;
    }

    // ─── STEP 1: CONTACT INFO ────────────────────────────────────
    if (currentStep.value == 1) {
      if (phoneController.text.trim().isEmpty) {
        AppSnackbar.error(kDanger, 'Error', 'Please enter phone number');
        return false;
      }
      if (fullPhoneNumber.value.trim().isEmpty) {
        AppSnackbar.error(
          kDanger,
          'Error',
          'Please enter a valid phone number',
        );
        return false;
      }
      if (emailController.text.trim().isEmpty ||
          !emailController.text.contains('@')) {
        AppSnackbar.error(kDanger, 'Error', 'Please enter valid email');
        return false;
      }

      if (!agreeToTerms.value) {
        AppSnackbar.error(
          kDanger,
          'Error',
          'Please agree to terms and conditions',
        );
        return false;
      }
      currentStep.value = 2;
      return true;
    }

    // ─── STEP 2: BUSINESS DETAILS ────────────────────────────────
    if (currentStep.value == 2) {
      // Business details are optional, so no validation needed
      currentStep.value = 3;
      return true;
    }

    // ─── STEP 3: PASSWORD ────────────────────────────────────────
    if (currentStep.value == 3) {
      if (passwordController.text.length < 6) {
        AppSnackbar.error(
          kDanger,
          'Error',
          'Password must be at least 6 characters',
        );
        return false;
      }
      if (passwordController.text != confirmPasswordController.text) {
        AppSnackbar.error(kDanger, 'Error', 'Passwords do not match');
        return false;
      }

      isLoading.value = true;

      try {
        // ─── BUILD BUSINESS DETAILS ──────────────────────────────
        final businessDetails = {
          'logo': logoController.text.trim(),
          'fiscalYear': selectedFiscalYear.value,
          'taxRegistrationNumber': taxRegistrationController.text.trim(),
          'signature': signatureController.text.trim(),
          'industry': industryController.text.trim(),
          'businessType': selectedBusinessType.value,
        };

        // ─── API REQUEST ──────────────────────────────────────────
        final dates = _calculateFiscalYearDates(selectedFiscalYear.value);
        final currentYear = DateTime.now().year;
        final startYear = dates['startDate']!.year;
        final endYear = dates['endDate']!.year;
        final fyName = startYear == endYear
            ? 'FY $startYear'
            : 'FY $startYear-$endYear';

        final Map<String, String> fields = {
          'firstName': firstNameController.text.trim(),
          'lastName': lastNameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'country': countryController.text.trim(),
          'phone': fullPhoneNumber.value.trim(),
          'address': addressController.text.trim(),
          'organizationName': organizationNameController.text.trim(),
          'fiscalYear': selectedFiscalYear.value,
          'fiscalYearStartDate': dates['startDate']!.toIso8601String(),
          'fiscalYearEndDate': dates['endDate']!.toIso8601String(),
          'fiscalYearName':
              selectedFiscalYear.value.isNotEmpty ? fyName : 'FY $currentYear',
          'taxRegistrationNumber': taxRegistrationController.text.trim(),
          'industry': industryController.text.trim(),
          'businessType': selectedBusinessType.value,
          'websiteLink': '',
          'contactNo': fullPhoneNumber.value.trim(),
        };

        final Map<String, String> filePaths = {};
        if (logoController.text.isNotEmpty) {
          filePaths['logo'] = logoController.text;
        }
        if (signatureController.text.isNotEmpty) {
          filePaths['signature'] = signatureController.text;
        }

        final response = await _api.postMultipart(
          '/api/users/register',
          fields: fields,
          filePaths: filePaths,
          requiresAuth: false,
        );

        final data = response.data;

        if (response.success) {
          print("✅ Registration successful");

          await _saveAuthData(
            data['token']?.toString() ?? '',
            Map<String, dynamic>.from(data['user'] as Map),
            refreshToken: data['refreshToken']?.toString(),
            companyOwner: true,
            pdfReportSettings: data['pdfReportSettings'],
          );

          await Get.find<CurrencyController>().setCurrency(
            selectedCurrencyCode.value,
          );
          await Get.find<CurrencyController>().updateFromUserData(
            Map<String, dynamic>.from(data['user'] as Map),
          );

          final subscriptionController = Get.find<SubscriptionController>();
          subscriptionController.updateFromUserData(data['user']);

          // Create initial fiscal year if selected
          await _createInitialFiscalYear();

          currentStep.value = 4;
          AppSnackbar.success(
            kSuccess,
            'Success',
            'Account created successfully!',
          );

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
            data['message'] ?? 'Registration failed',
          );
          return false;
        }
      } catch (e) {
        print('❌ Registration error: $e');
        AppSnackbar.error(kDanger, 'Error', 'error. Please try again.');
        return false;
      } finally {
        isLoading.value = false;
      }
    }

    return false;
  }

  // ════════════════════════════════════════════════════════════════
  // LOGIN FUNCTION
  // ════════════════════════════════════════════════════════════════
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      AppSnackbar.error(kDanger, 'Error', 'Please enter email and password');
      return false;
    }

    isLoading.value = true;

    try {
      final response = await _api.post(
        '/api/users/login',
        body: {'email': email.trim(), 'password': password},
        requiresAuth: false,
      );

      final data = response.data;

      if (response.success) {
        await _saveAuthData(
          data['token']?.toString() ?? '',
          Map<String, dynamic>.from(data['user'] as Map),
          refreshToken: data['refreshToken']?.toString(),
          companyOwner: true,
        );

        final subscriptionController = Get.find<SubscriptionController>();
        subscriptionController.updateFromUserData(data['user']);

        AppSnackbar.success(kSuccess, 'Success', 'Login successful!');

        if (subscriptionController.hasAccess) {
          Get.offAllNamed('/dashboard');
        } else {
          Get.offAll(() => const SelectPlanScreen());
        }

        return true;
      } else {
        AppSnackbar.error(kDanger, 'Error', data['message'] ?? 'Login failed');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      AppSnackbar.error(kDanger, 'Error', 'error. Please try again.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // OTHER METHODS
  // ════════════════════════════════════════════════════════════════

  Future<void> checkLoginStatus() async {
    final token = await _api.getToken();
    if (token != null && token.isNotEmpty) {
      await getCurrentUser();
    }
  }

  Future<void> _saveAuthData(
    String token,
    Map<String, dynamic> userData, {
    String? refreshToken,
    bool companyOwner = false,
    dynamic pdfReportSettings,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _api.setBothTokens(token, refreshToken);
    } else if (token.isNotEmpty) {
      await _api.setToken(token);
    }

    // Company owner (self-register) always has full admin access.
    final roleRaw = userData['role']?.toString().trim() ?? '';
    final role = roleRaw.isNotEmpty
        ? roleRaw
        : (companyOwner ? 'admin' : 'user');
    userData['role'] = role;

    await prefs.setString('user_data', json.encode(userData));
    user.value = userData;
    isLoggedIn.value = true;

    final permissionService = Get.isRegistered<PermissionService>()
        ? Get.find<PermissionService>()
        : Get.put(PermissionService(), permanent: true);

    final permissionsList = userData['permissions'] as List<dynamic>?;
    final userPermissions = permissionsList
            ?.map((p) {
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
            })
            .toList() ??
        [];

    await permissionService.saveUserData(
      UserData(
        id: userData['_id']?.toString() ?? userData['id']?.toString() ?? '',
        firstName: userData['firstName']?.toString() ?? '',
        lastName: userData['lastName']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        role: role,
        permissions: userPermissions,
      ),
    );

    final orgName = userData['organizationName']?.toString() ?? '';
    await prefs.setString('company_name', orgName);

    final address = userData['address']?.toString() ?? '';
    if (address.isNotEmpty) {
      await prefs.setString('company_address', address);
    }

    final firstName = userData['firstName']?.toString() ?? '';
    final lastName = userData['lastName']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) {
      await prefs.setString('user_name', fullName);
    }

    final userEmail = userData['email']?.toString() ?? '';
    if (userEmail.isNotEmpty) {
      await prefs.setString('user_email', userEmail);
    }

    if (userData['businessDetails'] != null) {
      await prefs.setString(
        'business_details',
        json.encode(userData['businessDetails']),
      );
    }

    await PdfReportSettingsController.persistFromLogin(
      pdfReportSettings ?? userData['pdfReportSettings'],
    );
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await _api.clearToken();
    await prefs.remove('user_data');
    await prefs.remove('user');
    user.value = null;
    isLoggedIn.value = false;
    if (Get.isRegistered<PermissionService>()) {
      await PermissionService.to.clearUserData();
    }
  }

  Future<void> getCurrentUser() async {
    try {
      final response = await _api.get('/api/users/me');

      if (response.success) {
        final data = response.data;
        user.value = data['user'];
        isLoggedIn.value = true;

        final subscriptionController = Get.find<SubscriptionController>();
        subscriptionController.updateFromUserData(data['user']);

        Get.find<CurrencyController>().updateFromUserData(data['user']);

        // Initialize fiscal year controller and fetch fiscal years
        await _fiscalYearController.fetchFiscalYears();
      } else {
        await _clearAuthData();
      }
    } catch (e) {
      print('Get user error: $e');
    }
  }

  Future<void> logout() async {
    await _clearAuthData();
    Get.offAllNamed('/login');
    AppSnackbar.success(
      kWarning,
      'Logged Out',
      'You have been logged out successfully',
    );
  }

  void checkPasswordStrength(String pwd) {
    double strength = 0;
    if (pwd.length >= 8) strength += 0.3;
    if (pwd.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (pwd.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (pwd.contains(RegExp(r'[!@#\$%^&*]'))) strength += 0.3;
    strength = strength.clamp(0.0, 1.0);

    passwordStrength.value = strength;

    if (strength >= 0.7) {
      passwordStrengthText.value = 'Strong';
      passwordStrengthColor.value = Colors.green;
    } else if (strength >= 0.4) {
      passwordStrengthText.value = 'Medium';
      passwordStrengthColor.value = Colors.orange;
    } else {
      passwordStrengthText.value = 'Weak';
      passwordStrengthColor.value = Colors.red;
    }
  }

  void nextStep() {
    if (currentStep.value < 4) register();
  }

  void previousStep() {
    if (currentStep.value > 0) currentStep.value--;
  }

  void goToStep(int step) {
    if (step <= currentStep.value + 1) currentStep.value = step;
  }

  void resetForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    phoneController.clear();
    countryController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    addressController.clear();
    organizationNameController.clear();
    industryController.clear();
    taxRegistrationController.clear();
    logoController.clear();
    signatureController.clear();
    selectedBusinessType.value = '';
    selectedFiscalYear.value = '';
    agreeToTerms.value = false;
    selectedCurrencyCode.value = '';
    selectedCurrencyName.value = '';
    selectedCurrencySymbol.value = '';
    fullPhoneNumber.value = '';
    phoneCountryIso.value = 'PK';
    currentStep.value = 0;
    passwordStrength.value = 0;
    passwordStrengthText.value = '';
  }

  bool isStepActive(int step) => currentStep.value >= step;
  bool isStepDone(int step) => currentStep.value > step;

  IconData getStepIcon(int step) {
    if (isStepDone(step)) return Icons.check;
    switch (step) {
      case 0:
        return Icons.person_outline;
      case 1:
        return Icons.phone_outlined;
      case 2:
        return Icons.business_outlined;
      case 3:
        return Icons.lock_outline;
      case 4:
        return Icons.check_circle_outline;
      default:
        return Icons.circle_outlined;
    }
  }

  Color getStepColor(int step) {
    if (isStepDone(step)) return const Color(0xFF1AB4F5);
    if (isStepActive(step)) return const Color(0xFF1AB4F5);
    return const Color(0xFF7A8FA6);
  }
}
