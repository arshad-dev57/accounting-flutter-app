// lib/core/companyprofile/controller/profile_controller.dart - WITH BUSINESS DETAILS

import 'dart:convert';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LedgerPro_app/Utils/signature_dialog.dart';

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
  // SAVE PROFILE
  // ════════════════════════════════════════════════════════════════
  Future<void> saveProfile() async {
    try {
      isSaving.value = true;

      // ─── BUILD REQUEST BODY ──────────────────────────────────────
      final Map<String, String> fields = {
        // Personal Info
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'country': countryController.text.trim(),

        // Address & Contact
        'address': addressController.text.trim(),
        'contactNo': contactNoController.text.trim(),
        'websiteLink': websiteController.text.trim(),
        'organizationName': orgNameController.text.trim(),

        // Business Details
        'fiscalYear': fiscalYearController.text.trim(),
        'taxRegistrationNumber': taxRegistrationController.text.trim(),
        'industry': industryController.text.trim(),
        'businessType': businessTypeController.text.trim(),
      };

      final Map<String, String> filePaths = {};
      if (businessLogoController.text.isNotEmpty && !businessLogoController.text.startsWith('http')) {
        filePaths['logo'] = businessLogoController.text;
      }
      if (signatureController.text.isNotEmpty && !signatureController.text.startsWith('http')) {
        filePaths['signature'] = signatureController.text;
      }

      final response = await _api.putMultipart('/api/profile', fields: fields, filePaths: filePaths);

      print('Update Profile Response Status: ${response.statusCode}');

      if (response.success) {
        final data = response.data;

        // ─── UPDATE OBSERVABLES ────────────────────────────────────
        organizationName.value = orgNameController.text.trim();
        firstName.value = firstNameController.text.trim();
        lastName.value = lastNameController.text.trim();
        address.value = addressController.text.trim();
        email.value = emailController.text.trim();
        contactNo.value = contactNoController.text.trim();
        phone.value = phoneController.text.trim();
        websiteLink.value = websiteController.text.trim();
        country.value = countryController.text.trim();

        // ─── UPDATE BUSINESS OBSERVABLES ───────────────────────────
        businessLogo.value = businessLogoController.text.trim();
        fiscalYear.value = fiscalYearController.text.trim();
        taxRegistrationNumber.value = taxRegistrationController.text.trim();
        signature.value = signatureController.text.trim();
        industry.value = industryController.text.trim();
        businessType.value = businessTypeController.text.trim();

        // Update personName
        personName.value = '${firstName.value} ${lastName.value}'.trim();

        _showSuccess(data['message'] ?? 'Profile updated successfully!');
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
  // SAVE BUSINESS DETAILS ONLY
  // ════════════════════════════════════════════════════════════════
  Future<void> saveBusinessDetails() async {
    try {
      isSaving.value = true;

      final Map<String, String> fields = {
        'fiscalYear': fiscalYearController.text.trim(),
        'taxRegistrationNumber': taxRegistrationController.text.trim(),
        'industry': industryController.text.trim(),
        'businessType': businessTypeController.text.trim(),
      };

      final Map<String, String> filePaths = {};
      if (businessLogoController.text.isNotEmpty && !businessLogoController.text.startsWith('http')) {
        filePaths['logo'] = businessLogoController.text;
      }
      if (signatureController.text.isNotEmpty && !signatureController.text.startsWith('http')) {
        filePaths['signature'] = signatureController.text;
      }

      final response = await _api.putMultipart('/api/profile/business', fields: fields, filePaths: filePaths);

      if (response.success) {
        final data = response.data;

        // Update observables
        businessLogo.value = businessLogoController.text.trim();
        fiscalYear.value = fiscalYearController.text.trim();
        taxRegistrationNumber.value = taxRegistrationController.text.trim();
        signature.value = signatureController.text.trim();
        industry.value = industryController.text.trim();
        businessType.value = businessTypeController.text.trim();

        _showSuccess(
          data['message'] ?? 'Business details updated successfully!',
        );
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
  // VALIDATE FORM
  // ════════════════════════════════════════════════════════════════
  bool validateForm() {
    if (orgNameController.text.trim().isEmpty) {
      _showError('Please enter organization name');
      return false;
    }
    if (firstNameController.text.trim().isEmpty) {
      _showError('Please enter first name');
      return false;
    }
    if (lastNameController.text.trim().isEmpty) {
      _showError('Please enter last name');
      return false;
    }
    if (addressController.text.trim().isEmpty) {
      _showError('Please enter address');
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      _showError('Please enter email');
      return false;
    }
    if (!emailController.text.contains('@') ||
        !emailController.text.contains('.')) {
      _showError('Please enter a valid email');
      return false;
    }
    if (contactNoController.text.trim().isEmpty) {
      _showError('Please enter contact number');
      return false;
    }
    if (contactNoController.text.trim().length < 10) {
      _showError('Please enter a valid contact number');
      return false;
    }
    return true;
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
