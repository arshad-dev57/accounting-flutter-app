// lib/core/companyprofile/controller/profile_controller.dart - WITH BUSINESS DETAILS

import 'dart:convert';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:BisonsTechs_app/Utils/signature_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:BisonsTechs_app/Services/permission_service.dart';

class ProfileController extends GetxController {
  // Observable variables
  var isLoading = false.obs;
  var isSaving = false.obs;
  var isEditing = false.obs;

  // ─── PROFILE DATA ──────────────────────────────────────────────
  var organizationName = ''.obs;
  var personName = ''.obs;
  var firstName = ''.obs;
  var lastName = ''.obs;
  var address = ''.obs;
  var email = ''.obs;
  var contactNo = ''.obs;
  var phone = ''.obs;
  var websiteLink = ''.obs;
  var country = ''.obs;

  // ─── BUSINESS DETAILS ──────────────────────────────────────────
  var businessLogo = ''.obs;
  var fiscalYear = ''.obs;
  var taxRegistrationNumber = ''.obs;
  var signature = ''.obs;
  var industry = ''.obs;
  var businessType = ''.obs;

  // ─── FORM CONTROLLERS ──────────────────────────────────────────
  late TextEditingController orgNameController;
  late TextEditingController personNameController;
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController addressController;
  late TextEditingController emailController;
  late TextEditingController contactNoController;
  late TextEditingController phoneController;
  late TextEditingController websiteController;
  late TextEditingController countryController;

  // ─── BUSINESS FORM CONTROLLERS ─────────────────────────────────
  late TextEditingController businessLogoController;
  late TextEditingController fiscalYearController;
  late TextEditingController taxRegistrationController;
  late TextEditingController signatureController;
  late TextEditingController industryController;
  late TextEditingController businessTypeController;

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

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    loadProfile();
    loadBusinessLogoFromPrefs();
  }

  void _initializeControllers() {
    orgNameController = TextEditingController();
    personNameController = TextEditingController();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    addressController = TextEditingController();
    emailController = TextEditingController();
    contactNoController = TextEditingController();
    phoneController = TextEditingController();
    websiteController = TextEditingController();
    countryController = TextEditingController();

    // ─── BUSINESS CONTROLLERS ─────────────────────────────────────
    businessLogoController = TextEditingController();
    fiscalYearController = TextEditingController();
    taxRegistrationController = TextEditingController();
    signatureController = TextEditingController();
    industryController = TextEditingController();
    businessTypeController = TextEditingController();
  }

  // ─── LOAD BUSINESS LOGO FROM SHARED PREFERENCES ─────────────────
  Future<void> loadBusinessLogoFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        final businessDetails = userData['businessDetails'] as Map<String, dynamic>?;
        
        if (businessDetails != null && businessDetails['logo'] != null) {
          final logo = businessDetails['logo'] as String;
          if (logo.isNotEmpty) {
            businessLogo.value = logo;
            businessLogoController.text = logo;
            print('✅ [ProfileController] Business logo loaded from SharedPreferences: $logo');
          }
        }
      }
    } catch (e) {
      print('❌ [ProfileController] Error loading business logo from SharedPreferences: $e');
    }
  }

  // ─── IMAGE PICKER METHODS ──────────────────────────────────────
  Future<void> pickBusinessLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      businessLogoController.text = image.path;
      businessLogo.value = image.path;
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

  // ════════════════════════════════════════════════════════════════
  // LOAD PROFILE
  // ════════════════════════════════════════════════════════════════
  Future<void> loadProfile() async {
    try {
      isLoading.value = true;

      final response = await _api.get('/api/profile');

      print('Profile API Response Status: ${response.statusCode}');

      if (response.success) {
        final data = response.data;
        if (data['success'] == true) {
          final profile = data['data'];

          // ─── MAIN PROFILE ────────────────────────────────────────
          organizationName.value = profile['organizationName'] ?? '';
          personName.value = profile['personName'] ?? '';
          firstName.value = profile['firstName'] ?? '';
          lastName.value = profile['lastName'] ?? '';
          address.value = profile['address'] ?? '';
          email.value = profile['email'] ?? '';
          contactNo.value = profile['contactNo'] ?? '';
          phone.value = profile['phone'] ?? '';
          websiteLink.value = profile['websiteLink'] ?? '';
          country.value = profile['country'] ?? '';

          // ─── BUSINESS DETAILS ────────────────────────────────────
          final businessDetails = profile['businessDetails'] ?? {};
          businessLogo.value = businessDetails['logo'] ?? '';
          fiscalYear.value = businessDetails['fiscalYear'] ?? '';
          taxRegistrationNumber.value =
              businessDetails['taxRegistrationNumber'] ?? '';
          signature.value = businessDetails['signature'] ?? '';
          industry.value = businessDetails['industry'] ?? '';
          businessType.value = businessDetails['businessType'] ?? '';

          // ─── UPDATE CONTROLLERS ──────────────────────────────────
          orgNameController.text = organizationName.value;
          personNameController.text = personName.value;
          firstNameController.text = firstName.value;
          lastNameController.text = lastName.value;
          addressController.text = address.value;
          emailController.text = email.value;
          contactNoController.text = contactNo.value;
          phoneController.text = phone.value;
          websiteController.text = websiteLink.value;
          countryController.text = country.value;

          // ─── BUSINESS CONTROLLERS ─────────────────────────────────
          businessLogoController.text = businessLogo.value;
          fiscalYearController.text = fiscalYear.value;
          taxRegistrationController.text = taxRegistrationNumber.value;
          signatureController.text = signature.value;
          industryController.text = industry.value;
          businessTypeController.text = businessType.value;
        } else {
          _showError(data['message'] ?? 'Failed to load profile');
        }
      } else {
        _showError(
          response.message ?? 'Failed to load profile. Please try again.',
        );
      }
    } catch (e) {
      print('Error loading profile: $e');
      _showError('error. Server Down. Please try again later.');
    } finally {
      isLoading.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SAVE PROFILE - PARTIAL UPDATE (only changed fields)
  // ════════════════════════════════════════════════════════════════
  Future<void> saveProfile() async {
    try {
      isSaving.value = true;

      // ─── BUILD REQUEST BODY - ONLY CHANGED FIELDS ─────────────────
      final Map<String, String> fields = {};

      // Personal Info - only add if changed and not empty
      if (firstNameController.text.trim() != firstName.value &&
          firstNameController.text.trim().isNotEmpty) {
        fields['firstName'] = firstNameController.text.trim();
      }
      if (lastNameController.text.trim() != lastName.value &&
          lastNameController.text.trim().isNotEmpty) {
        fields['lastName'] = lastNameController.text.trim();
      }
      if (emailController.text.trim() != email.value &&
          emailController.text.trim().isNotEmpty) {
        fields['email'] = emailController.text.trim();
      }
      if (phoneController.text.trim() != phone.value &&
          phoneController.text.trim().isNotEmpty) {
        fields['phone'] = phoneController.text.trim();
      }
      if (countryController.text.trim() != country.value &&
          countryController.text.trim().isNotEmpty) {
        fields['country'] = countryController.text.trim();
      }

      // Address & Contact - only add if changed and not empty
      if (addressController.text.trim() != address.value &&
          addressController.text.trim().isNotEmpty) {
        fields['address'] = addressController.text.trim();
      }
      if (contactNoController.text.trim() != contactNo.value &&
          contactNoController.text.trim().isNotEmpty) {
        fields['contactNo'] = contactNoController.text.trim();
      }
      if (websiteController.text.trim() != websiteLink.value &&
          websiteController.text.trim().isNotEmpty) {
        fields['websiteLink'] = websiteController.text.trim();
      }
      if (orgNameController.text.trim() != organizationName.value &&
          orgNameController.text.trim().isNotEmpty) {
        fields['organizationName'] = orgNameController.text.trim();
      }

      // Business Details - only add if changed and not empty
      if (fiscalYearController.text.trim() != fiscalYear.value &&
          fiscalYearController.text.trim().isNotEmpty) {
        fields['fiscalYear'] = fiscalYearController.text.trim();
      }
      if (taxRegistrationController.text.trim() != taxRegistrationNumber.value &&
          taxRegistrationController.text.trim().isNotEmpty) {
        fields['taxRegistrationNumber'] = taxRegistrationController.text.trim();
      }
      if (industryController.text.trim() != industry.value &&
          industryController.text.trim().isNotEmpty) {
        fields['industry'] = industryController.text.trim();
      }
      if (businessTypeController.text.trim() != businessType.value &&
          businessTypeController.text.trim().isNotEmpty) {
        fields['businessType'] = businessTypeController.text.trim();
      }

      // File uploads - always include if new local file
      final Map<String, String> filePaths = {};
      if (businessLogoController.text.isNotEmpty &&
          !businessLogoController.text.startsWith('http')) {
        filePaths['logo'] = businessLogoController.text;
      }
      if (signatureController.text.isNotEmpty &&
          !signatureController.text.startsWith('http')) {
        filePaths['signature'] = signatureController.text;
      }

      // Validate email format if email is being updated
      if (fields.containsKey('email')) {
        if (!fields['email']!.contains('@') ||
            !fields['email']!.contains('.')) {
          _showError('Please enter a valid email');
          isSaving.value = false;
          return;
        }
      }

      // Validate contact number format if being updated
      if (fields.containsKey('contactNo')) {
        if (fields['contactNo']!.length < 10) {
          _showError('Please enter a valid contact number');
          isSaving.value = false;
          return;
        }
      }

      // If no fields to update, just exit edit mode
      if (fields.isEmpty && filePaths.isEmpty) {
        _showError('No changes to save');
        isSaving.value = false;
        return;
      }

      final response = await _api.putMultipart(
        '/api/profile',
        fields: fields,
        filePaths: filePaths,
      );

      print('Update Profile Response Status: ${response.statusCode}');

      if (response.success) {
        final data = response.data;

        // ─── UPDATE OBSERVABLES (only for fields that were sent) ─────
        if (fields.containsKey('organizationName')) {
          organizationName.value = orgNameController.text.trim();
        }
        if (fields.containsKey('firstName')) {
          firstName.value = firstNameController.text.trim();
        }
        if (fields.containsKey('lastName')) {
          lastName.value = lastNameController.text.trim();
        }
        if (fields.containsKey('address')) {
          address.value = addressController.text.trim();
        }
        if (fields.containsKey('email')) {
          email.value = emailController.text.trim();
        }
        if (fields.containsKey('contactNo')) {
          contactNo.value = contactNoController.text.trim();
        }
        if (fields.containsKey('phone')) {
          phone.value = phoneController.text.trim();
        }
        if (fields.containsKey('websiteLink')) {
          websiteLink.value = websiteController.text.trim();
        }
        if (fields.containsKey('country')) {
          country.value = countryController.text.trim();
        }

        // ─── UPDATE BUSINESS OBSERVABLES ───────────────────────────
        if (filePaths.containsKey('logo')) {
          businessLogo.value = businessLogoController.text.trim();
        }
        if (fields.containsKey('fiscalYear')) {
          fiscalYear.value = fiscalYearController.text.trim();
        }
        if (fields.containsKey('taxRegistrationNumber')) {
          taxRegistrationNumber.value = taxRegistrationController.text.trim();
        }
        if (filePaths.containsKey('signature')) {
          signature.value = signatureController.text.trim();
        }
        if (fields.containsKey('industry')) {
          industry.value = industryController.text.trim();
        }
        if (fields.containsKey('businessType')) {
          businessType.value = businessTypeController.text.trim();
        }

        // Update personName if name fields changed
        if (fields.containsKey('firstName') || fields.containsKey('lastName')) {
          personName.value = '${firstName.value} ${lastName.value}'.trim();
        }

        _showSuccess(data['message'] ?? 'Profile updated successfully!');
        
        // Update SharedPreferences with new profile data
        await _updateSharedPreferencesUserData();
        
        toggleEdit(); // Exit edit mode
      } else {
        _showError(
          response.message ?? 'Failed to update profile. Please try again.',
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      _showError('error. Server Down. Please try again later.');
    } finally {
      isSaving.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SAVE BUSINESS DETAILS ONLY - PARTIAL UPDATE
  // ════════════════════════════════════════════════════════════════
  Future<void> saveBusinessDetails() async {
    try {
      isSaving.value = true;

      // ─── BUILD REQUEST BODY - ONLY CHANGED FIELDS ─────────────────
      final Map<String, String> fields = {};

      if (fiscalYearController.text.trim() != fiscalYear.value &&
          fiscalYearController.text.trim().isNotEmpty) {
        fields['fiscalYear'] = fiscalYearController.text.trim();
      }
      if (taxRegistrationController.text.trim() != taxRegistrationNumber.value &&
          taxRegistrationController.text.trim().isNotEmpty) {
        fields['taxRegistrationNumber'] = taxRegistrationController.text.trim();
      }
      if (industryController.text.trim() != industry.value &&
          industryController.text.trim().isNotEmpty) {
        fields['industry'] = industryController.text.trim();
      }
      if (businessTypeController.text.trim() != businessType.value &&
          businessTypeController.text.trim().isNotEmpty) {
        fields['businessType'] = businessTypeController.text.trim();
      }

      // File uploads - always include if new local file
      final Map<String, String> filePaths = {};
      if (businessLogoController.text.isNotEmpty &&
          !businessLogoController.text.startsWith('http')) {
        filePaths['logo'] = businessLogoController.text;
      }
      if (signatureController.text.isNotEmpty &&
          !signatureController.text.startsWith('http')) {
        filePaths['signature'] = signatureController.text;
      }

      // If no fields to update, just exit edit mode
      if (fields.isEmpty && filePaths.isEmpty) {
        _showError('No changes to save');
        isSaving.value = false;
        return;
      }

      final response = await _api.putMultipart(
        '/api/profile/business',
        fields: fields,
        filePaths: filePaths,
      );

      if (response.success) {
        final data = response.data;

        // Update observables (only for fields that were sent)
        if (filePaths.containsKey('logo')) {
          businessLogo.value = businessLogoController.text.trim();
        }
        if (fields.containsKey('fiscalYear')) {
          fiscalYear.value = fiscalYearController.text.trim();
        }
        if (fields.containsKey('taxRegistrationNumber')) {
          taxRegistrationNumber.value = taxRegistrationController.text.trim();
        }
        if (filePaths.containsKey('signature')) {
          signature.value = signatureController.text.trim();
        }
        if (fields.containsKey('industry')) {
          industry.value = industryController.text.trim();
        }
        if (fields.containsKey('businessType')) {
          businessType.value = businessTypeController.text.trim();
        }

        _showSuccess(
          data['message'] ?? 'Business details updated successfully!',
        );
        
        // Update SharedPreferences with new business details
        await _updateSharedPreferencesUserData();
        
        toggleEdit();
      } else {
        _showError(response.message ?? 'Failed to update business details.');
      }
    } catch (e) {
      print('Error saving business details: $e');
      _showError('error. Server Down. Please try again later.');
    } finally {
      isSaving.value = false;
    }
  }

  // ════════════════════════════════════════════════════════════════
  // UPDATE SHARED PREFERENCES USER DATA
  // ════════════════════════════════════════════════════════════════
  Future<void> _updateSharedPreferencesUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing user data
      final existingUserDataString = prefs.getString('user_data');
      Map<String, dynamic> userData = {};
      
      if (existingUserDataString != null) {
        userData = json.decode(existingUserDataString) as Map<String, dynamic>;
      }
      
      // Update user data with current profile values
      userData['organizationName'] = organizationName.value;
      userData['firstName'] = firstName.value;
      userData['lastName'] = lastName.value;
      userData['address'] = address.value;
      userData['email'] = email.value;
      userData['contactNo'] = contactNo.value;
      userData['phone'] = phone.value;
      userData['websiteLink'] = websiteLink.value;
      userData['country'] = country.value;
      
      // Update business details
      if (userData['businessDetails'] == null) {
        userData['businessDetails'] = {};
      }
      userData['businessDetails']['logo'] = businessLogo.value;
      userData['businessDetails']['fiscalYear'] = fiscalYear.value;
      userData['businessDetails']['taxRegistrationNumber'] = taxRegistrationNumber.value;
      userData['businessDetails']['signature'] = signature.value;
      userData['businessDetails']['industry'] = industry.value;
      userData['businessDetails']['businessType'] = businessType.value;
      
      // Save updated user data
      await prefs.setString('user_data', json.encode(userData));
      print('✅ [ProfileController] User data updated in SharedPreferences');
      
      // Update PermissionService user data if available
      try {
        final permissionService = Get.find<PermissionService>();
        if (permissionService.user.value != null) {
          final updatedUserData = UserData(
            id: permissionService.user.value!.id,
            firstName: firstName.value,
            lastName: lastName.value,
            email: email.value,
            role: permissionService.user.value!.role,
            permissions: permissionService.user.value!.permissions,
          );
          await permissionService.saveUserData(updatedUserData);
          print('✅ [ProfileController] PermissionService user data updated');
        }
      } catch (e) {
        print('⚠️ [ProfileController] Could not update PermissionService: $e');
      }
      
    } catch (e) {
      print('❌ [ProfileController] Error updating SharedPreferences: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // TOGGLE EDIT MODE
  // ════════════════════════════════════════════════════════════════
  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      // Reset controllers to original values when canceling
      _resetControllers();
    }
  }

  void _resetControllers() {
    orgNameController.text = organizationName.value;
    personNameController.text = personName.value;
    firstNameController.text = firstName.value;
    lastNameController.text = lastName.value;
    addressController.text = address.value;
    emailController.text = email.value;
    contactNoController.text = contactNo.value;
    phoneController.text = phone.value;
    websiteController.text = websiteLink.value;
    countryController.text = country.value;

    businessLogoController.text = businessLogo.value;
    fiscalYearController.text = fiscalYear.value;
    taxRegistrationController.text = taxRegistrationNumber.value;
    signatureController.text = signature.value;
    industryController.text = industry.value;
    businessTypeController.text = businessType.value;
  }

  // ════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════
  void _showError(String message) {
    AppSnackbar.error(
      kDanger,
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
    orgNameController.dispose();
    personNameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    emailController.dispose();
    contactNoController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    countryController.dispose();
    businessLogoController.dispose();
    fiscalYearController.dispose();
    taxRegistrationController.dispose();
    signatureController.dispose();
    industryController.dispose();
    businessTypeController.dispose();
    super.onClose();
  }
}
