import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/Users/controller/user_management_controller.dart';
import 'package:country_picker_pro/country_picker_pro.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field_continued/country_picker_dialog.dart';
import 'package:intl_phone_field_continued/intl_phone_field.dart';

class UserFormScreen extends StatefulWidget {
  final String? userId;

  const UserFormScreen({super.key, this.userId});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  late final UserManagementController _controller;
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  final Rxn<Country> _selectedCountry = Rxn<Country>();
  final RxString _phoneCountryIso = 'PK'.obs;
  final RxString _fullPhoneNumber = ''.obs;
  final RxBool _isSaving = false.obs;
  final RxBool _obscurePassword = true.obs;

  String _selectedRole = 'user';
  String? _selectedRoleId;
  bool _isActive = true;
  String _countryName = 'Pakistan';

  bool get isEditMode => widget.userId != null;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : Get.put(UserManagementController());

    if (isEditMode) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    final user = _controller.users.firstWhereOrNull(
      (u) => u.id == widget.userId,
    );
    if (user == null) return;

    setState(() {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _selectedRole = user.role;
      _selectedRoleId = user.roleId;
      _isActive = user.isActive;
    });

    final phone = (user.phone ?? '').trim();
    if (phone.isNotEmpty) {
      _fullPhoneNumber.value = phone.startsWith('+') ? phone : '+$phone';
      // Keep local digits in the field when possible
      final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length > 10) {
        _phoneController.text = digits.substring(digits.length - 10);
      } else {
        _phoneController.text = digits;
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_isSaving.value) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCountry.value == null && !isEditMode) {
      Get.snackbar(
        'Error',
        'Please select a country',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kDanger,
        colorText: Colors.white,
      );
      return;
    }

    final phoneToSave = _fullPhoneNumber.value.trim().isNotEmpty
        ? _fullPhoneNumber.value.trim()
        : _phoneController.text.trim();

    if (phoneToSave.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a phone number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kDanger,
        colorText: Colors.white,
      );
      return;
    }

    _isSaving.value = true;
    bool success;
    try {
      if (isEditMode) {
        success = await _controller.updateUser(
          id: widget.userId!,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: phoneToSave,
          country: _countryName.trim(),
          role: _selectedRole,
          roleId: _selectedRoleId,
          isActive: _isActive,
        );
      } else {
        success = await _controller.createUser(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: phoneToSave,
          country: _countryName.trim(),
          role: _selectedRole,
          roleId: _selectedRoleId,
        );
      }
    } finally {
      _isSaving.value = false;
    }

    if (success) {
      if (isEditMode) {
        Get.back();
        Get.snackbar(
          'Success',
          'User updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        final email = _emailController.text.trim().toLowerCase();
        final created = _controller.users.firstWhereOrNull(
          (u) => u.email.toLowerCase() == email,
        );
        Get.back();
        _showSetPermissionsPrompt(created?.id, _firstNameController.text.trim());
      }
    } else {
      Get.snackbar(
        'Error',
        isEditMode ? 'Failed to update user' : 'Failed to create user',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kDanger,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          isEditMode ? 'Edit User' : 'Add New User',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          Obx(() {
            final saving = _isSaving.value;
            return TextButton(
              onPressed: saving ? null : _saveUser,
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: kPrimary,
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    hintText: 'Enter first name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hintText: 'Enter last name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'Enter email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!GetUtils.isEmail(value.trim())) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('Country'),
                  const SizedBox(height: 8),
                  _countryPickerField(),
                  const SizedBox(height: 16),
                  _fieldLabel('Phone Number'),
                  const SizedBox(height: 8),
                  _phoneNumberField(),
                ],
              ),
              const SizedBox(height: 20),
              if (!isEditMode) ...[
                _buildSectionTitle('Security'),
                const SizedBox(height: 12),
                _buildCard(
                  children: [
                    Obx(
                      () => _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hintText: 'Enter password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword.value,
                        suffix: IconButton(
                          onPressed: () =>
                              _obscurePassword.value = !_obscurePassword.value,
                          icon: Icon(
                            _obscurePassword.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              _buildSectionTitle('Role & Access'),
              const SizedBox(height: 12),
              _buildCard(
                children: [
                  _buildRoleDropdown(),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    title: 'Active Status',
                    subtitle: 'User can access the system',
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Obx(() {
                final saving = _isSaving.value;
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: saving ? null : _saveUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      disabledBackgroundColor: kPrimary.withValues(alpha: 0.7),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditMode ? 'Update User' : 'Create User',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetPermissionsPrompt(String? userId, String firstName) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'User created',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        content: Text(
          userId == null
              ? '$firstName was added. Open Team Members and tap “Set permissions” on their card to choose modules.'
              : '$firstName was added successfully.\n\nNext: choose which modules and screens they can open (Sales, Accounting, etc.).',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Later', style: TextStyle(color: Colors.grey.shade600)),
          ),
          if (userId != null)
            ElevatedButton(
              onPressed: () {
                Get.back();
                Get.toNamed('/admin/users/access/$userId');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Set permissions'),
            ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _countryPickerField() {
    return Obx(() {
      final country = _selectedCountry.value;
      return GestureDetector(
        onTap: () {
          CountrySelector(
            context: context,
            appBarTitle: 'Select Country',
            showPhoneCode: false,
            showSearchBox: true,
            searchBarAutofocus: true,
            listType: ListType.list,
            onSelect: (Country selected) {
              _selectedCountry.value = selected;
              _countryName = selected.name;
              _phoneCountryIso.value = selected.countryCode;
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.public, color: Colors.grey.shade500, size: 20),
              const SizedBox(width: 10),
              if (country != null) ...[
                Text(country.flagEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  country?.name ??
                      (isEditMode ? _countryName : 'Select country'),
                  style: TextStyle(
                    fontSize: 14,
                    color: country != null || isEditMode
                        ? const Color(0xFF2D3748)
                        : Colors.grey.shade400,
                    fontWeight: country != null
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _phoneNumberField() {
    return Obx(
      () => IntlPhoneField(
        key: ValueKey(_phoneCountryIso.value),
        controller: _phoneController,
        initialCountryCode: _phoneCountryIso.value,
        disableLengthCheck: false,
        showDropdownIcon: true,
        dropdownIcon: Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey.shade400,
          size: 20,
        ),
        flagsButtonPadding: const EdgeInsets.only(left: 12, right: 4),
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        dropdownTextStyle: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: '300 1234567',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
        ),
        pickerDialogStyle: PickerDialogStyle(
          backgroundColor: Colors.white,
          countryCodeStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
          countryNameStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          searchFieldInputDecoration: InputDecoration(
            hintText: 'Search country',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
          ),
        ),
        onChanged: (phone) {
          final complete = phone.completeNumber.trim();
          _fullPhoneNumber.value =
              complete.isNotEmpty ? (complete.startsWith('+') ? complete : '+$complete') : '';
        },
        onCountryChanged: (country) {
          _phoneCountryIso.value = country.code;
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    IconData? icon,
    Widget? suffix,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.grey.shade500, size: 20)
                : null,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Role'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey.shade400,
              ),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'manager', child: Text('Manager')),
                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
              ],
              onChanged: (value) {
                setState(() => _selectedRole = value ?? 'user');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: kPrimary,
          ),
        ],
      ),
    );
  }
}
