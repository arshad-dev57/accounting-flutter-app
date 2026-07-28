// lib/core/Register/Views/register_screen.dart

import 'dart:io';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/core/Register/controller/registercontroller.dart';
import 'package:country_picker_pro/country_picker_pro.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class RegistrationScreen extends StatelessWidget {
  RegistrationScreen({super.key});

  final Rx<Country?> _selectedCountry = Rx<Country?>(null);
  static List<AppCurrency>? _allCurrencies;

  static List<AppCurrency> _buildAllCurrencies() {
    if (_allCurrencies != null) return _allCurrencies!;
    final Map<String, AppCurrency> currencyMap = {};
    final countryProvider = CountryProvider();
    final allCountries = countryProvider.getAll();
    for (final country in allCountries) {
      final rawCurrency = country.currency.toString();
      final code = _extractCurrencyCode(rawCurrency);
      final name = _extractCurrencyName(rawCurrency);
      final symbol = _extractCurrencySymbol(rawCurrency);
      if (code != null && name != null && symbol != null) {
        if (!currencyMap.containsKey(code)) {
          currencyMap[code] = AppCurrency(
            code: code,
            symbol: symbol,
            name: name,
          );
        }
      }
    }
    for (final currency in CurrencyController.currencies) {
      if (!currencyMap.containsKey(currency.code)) {
        currencyMap[currency.code] = currency;
      }
    }
    _allCurrencies = currencyMap.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    return _allCurrencies!;
  }

  static String? _extractCurrencyCode(String s) {
    final m = RegExp(r'\(([A-Z]{3})\)').firstMatch(s);
    return m?.group(1);
  }

  static String? _extractCurrencyName(String s) {
    final m = RegExp(r'^(.+?)\s*\(').firstMatch(s);
    return m?.group(1)?.trim();
  }

  static String? _extractCurrencySymbol(String s) {
    final m = RegExp(r'\([A-Z]{3}\)\s*(.+)$').firstMatch(s);
    return m?.group(1)?.trim();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.put(AuthController());
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Obx(() {
          final step = auth.currentStep.value;
          if (step == 0 || step == 4) {
            return IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
              onPressed: () => Get.back(),
            );
          }
          return IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            onPressed: () => auth.previousStep(),
          );
        }),
        title: const Text(
          'Register',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderTitle(auth),
              const SizedBox(height: 32),
              Obx(() => _buildProgressBar(auth)),
              const SizedBox(height: 8),
              Obx(() => _buildStepLabels(auth)),
              const SizedBox(height: 32),
              Obx(() => _buildStepContent(auth, context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTitle(AuthController auth) {
    return Obx(() {
      final titles = [
        'Create an account',
        'Contact Info',
        'Business Details',
        'Create Password',
        'All Done!',
      ];
      final subtitles = [
        'Please enter your personal details.',
        'How can we reach you?',
        'Tell us about your business.',
        'Secure your new account.',
        'Welcome aboard!',
      ];
      final step = auth.currentStep.value.clamp(0, 4);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titles[step],
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: kTextLight,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitles[step],
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildProgressBar(AuthController auth) {
    const totalSteps = 4;
    final step = auth.currentStep.value;
    return Row(
      children: List.generate(totalSteps, (i) {
        final filled = i < step;
        final active = i == step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < totalSteps - 1 ? 5 : 0),
            height: 5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: filled
                  ? kPrimary
                  : active
                  ? kPrimary.withOpacity(0.4)
                  : const Color(0xFFDDE3EE),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepLabels(AuthController auth) {
    final step = auth.currentStep.value;
    final labels = ['Personal', 'Contact', 'Business', 'Password'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isDone = step > i;
        final isActive = step == i;
        return Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? kPrimary
                      : isActive
                      ? kPrimary.withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: isDone || isActive
                        ? kPrimary
                        : const Color(0xFFBDC8DC),
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 9)
                    : null,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: isDone || isActive
                        ? kPrimary
                        : const Color(0xFFAAB8CC),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepContent(AuthController auth, BuildContext context) {
    switch (auth.currentStep.value) {
      case 0:
        return _buildPersonalStep(auth, context);
      case 1:
        return _buildContactStep(auth, context);
      case 2:
        return _buildBusinessStep(auth, context);
      case 3:
        return _buildPasswordStep(auth, context);
      case 4:
        return _buildSuccessStep(auth, context);
      default:
        return _buildPersonalStep(auth, context);
    }
  }

  // ══════════════════════════════════════════════════
  // STEP 1 — PERSONAL
  // ══════════════════════════════════════════════════
  Widget _buildPersonalStep(AuthController auth, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputCard(
          children: [
            _fieldLabel('First Name'),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.firstNameController,
              hint: 'Enter your first name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 18),
            _fieldLabel('Last Name'),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.lastNameController,
              hint: 'Enter your last name',
              icon: Icons.person_outline,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _inputCard(
          children: [
            _fieldLabel('Country'),
            const SizedBox(height: 8),
            _countryPickerField(auth),
            const SizedBox(height: 18),
            _fieldLabel('Currency'),
            const SizedBox(height: 4),
            Text(
              'Auto-selected from country — change anytime',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            _currencyDropdownField(auth),
          ],
        ),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Continue',
          onTap: () => auth.nextStep(),
          isLoading: auth.isLoading.value,
        ),
        const SizedBox(height: 14),
        _loginHint(),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // STEP 2 — CONTACT
  // ══════════════════════════════════════════════════
  Widget _buildContactStep(AuthController auth, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputCard(
          children: [
            _fieldLabel('Phone Number'),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.phoneController,
              hint: '+92 300 1234567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 18),
            _fieldLabel('Email Address'),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.emailController,
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _inputCard(
          label: 'Address (Optional)',
          children: [
            _fieldLabel('Street Address'),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.addressController,
              hint: 'Street, City, Postal Code',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _termsCheckbox(auth),
        const SizedBox(height: 22),
        _primaryButton(
          label: 'Continue',
          onTap: () => auth.nextStep(),
          isLoading: auth.isLoading.value,
        ),
        const SizedBox(height: 14),
        _loginHint(),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // STEP 3 — BUSINESS
  // ══════════════════════════════════════════════════
  Widget _buildBusinessStep(AuthController auth, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputCard(
          children: [
            _fieldLabel('Company / Organization Name'),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.organizationNameController,
              hint: 'e.g., ABC Traders',
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 18),
            _fieldLabel('Industry'),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.industryController,
              hint: 'e.g., Retail, Manufacturing',
              icon: Icons.factory_outlined,
            ),
            const SizedBox(height: 18),
            _fieldLabel('Business Type'),
            const SizedBox(height: 8),
            _businessTypeDropdown(auth),
            const SizedBox(height: 18),
            _fieldLabel('Fiscal Year'),
            const SizedBox(height: 8),
            _fiscalYearDropdown(auth),
          ],
        ),
        const SizedBox(height: 14),
        _inputCard(
          label: 'Registration & Tax Info',
          children: [
            _fieldLabel('Tax Registration Number'),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.taxRegistrationController,
              hint: 'e.g., NTN, GST, VAT Number',
              icon: Icons.receipt_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _inputCard(
          label: 'Branding (Optional)',
          children: [
            _fieldLabel('Business Logo'),
            const SizedBox(height: 8),
            Obx(() => _buildImageBox(
              label: 'Upload Logo',
              icon: Icons.image_outlined,
              path: auth.logo.value,
              onTap: auth.pickLogo,
            )),
            const SizedBox(height: 18),
            _fieldLabel('Signature'),
            const SizedBox(height: 8),
            Obx(() => _buildImageBox(
              label: 'Draw Signature',
              icon: Icons.draw_outlined,
              path: auth.signature.value,
              onTap: () => auth.drawSignature(Get.context!),
            )),
          ],
        ),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Continue',
          onTap: () => auth.nextStep(),
          isLoading: auth.isLoading.value,
        ),
        const SizedBox(height: 14),
        _loginHint(),
      ],
    );
  }

  Widget _businessTypeDropdown(AuthController auth) {
    final businessTypes = [
      'Sole Proprietorship',
      'Partnership',
      'Limited Liability Company (LLC)',
      'Corporation',
      'Non-Profit Organization',
      'Cooperative',
      'Franchise',
      'Other',
    ];
    return Obx(
      () => _dropdownContainer(
        child: DropdownButtonFormField<String>(
          value: auth.selectedBusinessType.value.isEmpty
              ? null
              : auth.selectedBusinessType.value,
          hint: _dropdownHint('Select business type'),
          icon: _dropdownIcon(),
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: _dropdownDecoration(Icons.business_center_outlined),
          items: businessTypes
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t, style: const TextStyle(fontSize: 13.5)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) auth.selectedBusinessType.value = v;
          },
        ),
      ),
    );
  }

  Widget _fiscalYearDropdown(AuthController auth) {
    final fiscalYears = [
      'January - December',
      'July - June',
      'April - March',
      'October - September',
      'Custom',
    ];
    return Obx(
      () => _dropdownContainer(
        child: DropdownButtonFormField<String>(
          value: auth.selectedFiscalYear.value.isEmpty
              ? null
              : auth.selectedFiscalYear.value,
          hint: _dropdownHint('Select fiscal year'),
          icon: _dropdownIcon(),
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: _dropdownDecoration(Icons.calendar_today_outlined),
          items: fiscalYears
              .map(
                (y) => DropdownMenuItem(
                  value: y,
                  child: Text(y, style: const TextStyle(fontSize: 13.5)),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) auth.selectedFiscalYear.value = v;
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // STEP 4 — PASSWORD
  // ══════════════════════════════════════════════════
  Widget _buildPasswordStep(AuthController auth, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputCard(
          children: [
            _fieldLabel('Password'),
            const SizedBox(height: 8),
            Obx(() {
              final isVisible = auth.isPasswordVisible.value;
              final showStrength = auth.passwordStrength.value > 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _inputField(
                    controller: auth.passwordController,
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    obscure: !isVisible,
                    suffix: IconButton(
                      icon: Icon(
                        isVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: () =>
                          auth.isPasswordVisible.value = !isVisible,
                    ),
                  ),
                  if (showStrength) ...[
                    const SizedBox(height: 10),
                    _passwordStrength(auth),
                  ],
                ],
              );
            }),
            const SizedBox(height: 18),
            _fieldLabel('Confirm Password'),
            const SizedBox(height: 8),
            Obx(() {
              final isVisible = auth.isConfirmPasswordVisible.value;
              return _inputField(
                controller: auth.confirmPasswordController,
                hint: 'Re-enter your password',
                icon: Icons.lock_outline,
                obscure: !isVisible,
                suffix: IconButton(
                  icon: Icon(
                    isVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () =>
                      auth.isConfirmPasswordVisible.value = !isVisible,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Create Account',
          onTap: () => auth.nextStep(),
          isLoading: auth.isLoading.value,
        ),
        const SizedBox(height: 14),
        _loginHint(),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // SUCCESS STEP
  // ══════════════════════════════════════════════════
  Widget _buildSuccessStep(AuthController auth, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, kPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Activated!',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome, ${auth.firstNameController.text}! 🎉',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _inputCard(
          label: 'Account Summary',
          children: [
            _infoRow(
              Icons.person,
              'Name',
              '${auth.firstNameController.text} ${auth.lastNameController.text}',
            ),
            _infoRowDivider(),
            _infoRow(Icons.public, 'Country', auth.countryController.text),
            _infoRowDivider(),
            _infoRow(
              Icons.attach_money,
              'Currency',
              auth.selectedCurrencyCode.value,
            ),
            _infoRowDivider(),
            _infoRow(Icons.phone, 'Phone', auth.phoneController.text),
            _infoRowDivider(),
            _infoRow(Icons.email, 'Email', auth.emailController.text),
            if (auth.organizationNameController.text.isNotEmpty) ...[
              _infoRowDivider(),
              _infoRow(
                Icons.business,
                'Company',
                auth.organizationNameController.text,
              ),
            ],
            if (auth.selectedBusinessType.value.isNotEmpty) ...[
              _infoRowDivider(),
              _infoRow(
                Icons.business_center_outlined,
                'Business Type',
                auth.selectedBusinessType.value,
              ),
            ],
            if (auth.selectedFiscalYear.value.isNotEmpty) ...[
              _infoRowDivider(),
              _infoRow(
                Icons.calendar_today_outlined,
                'Fiscal Year',
                auth.selectedFiscalYear.value,
              ),
            ],
            if (auth.taxRegistrationController.text.isNotEmpty) ...[
              _infoRowDivider(),
              _infoRow(
                Icons.receipt_outlined,
                'Tax Reg.',
                auth.taxRegistrationController.text,
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Get Started',
          onTap: () => auth.resetForm(),
          isLoading: false,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════

  void _showSignatureOptions(BuildContext context) {
    final auth = Get.find<AuthController>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.draw_outlined, color: kPrimary),
                title: const Text('Draw Signature'),
                onTap: () {
                  Navigator.pop(context);
                  auth.drawSignature(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined, color: kPrimary),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  auth.pickSignatureFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageBox({
    required String label,
    required IconData icon,
    required String path,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
            style: BorderStyle.solid, // Dash borders need a package, let's stick to solid
          ),
        ),
        child: path.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(
                  File(path),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.grey.shade400, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Removed white card wrapper to match flat design
  Widget _inputCard({String? label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ...children,
      ],
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _countryPickerField(AuthController auth) {
    return Obx(() {
      final country = _selectedCountry.value;
      return GestureDetector(
        onTap: () {
          CountrySelector(
            context: Get.context!,
            appBarTitle: 'Select Country',
            showPhoneCode: false,
            showSearchBox: true,
            searchBarAutofocus: true,
            listType: ListType.list,
            onSelect: (Country selected) {
              _selectedCountry.value = selected;
              auth.countryController.text = selected.name;
              auth.country.value = selected.name;
              final code = _extractCurrencyCode(selected.currency.toString());
              if (code != null) auth.selectedCurrencyCode.value = code;
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.public, color: Colors.grey.shade400, size: 19),
              const SizedBox(width: 10),
              if (country != null) ...[
                Text(country.flagEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  country?.name ?? 'Select your country',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: country != null
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
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _currencyDropdownField(AuthController auth) {
    final allCurrencies = _buildAllCurrencies();
    return Obx(
      () => _dropdownContainer(
        child: DropdownButtonFormField<String>(
          value: auth.selectedCurrencyCode.value.isEmpty
              ? null
              : auth.selectedCurrencyCode.value,
          hint: _dropdownHint('Select currency'),
          icon: _dropdownIcon(),
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: _dropdownDecoration(Icons.attach_money),
          items: allCurrencies
              .map(
                (c) => DropdownMenuItem(
                  value: c.code,
                  child: Text(
                    c.displayLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) auth.selectedCurrencyCode.value = v;
          },
        ),
      ),
    );
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: child,
    );
  }

  Widget _dropdownHint(String text) =>
      Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 13.5));

  Widget _dropdownIcon() =>
      Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400);

  InputDecoration _dropdownDecoration(IconData icon) => InputDecoration(
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
  );

  Widget _termsCheckbox(AuthController auth) {
    return Obx(
      () => GestureDetector(
        onTap: () => auth.agreeToTerms.value = !auth.agreeToTerms.value,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 1.0,
              child: Checkbox(
                value: auth.agreeToTerms.value,
                onChanged: (v) => auth.agreeToTerms.value = v ?? false,
                activeColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                side: BorderSide(color: Colors.blue.shade100, width: 1.5),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordStrength(AuthController auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Strength: ',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
            Obx(
              () => Text(
                auth.passwordStrengthText.value,
                style: TextStyle(
                  fontSize: 11.5,
                  color: auth.passwordStrengthColor.value,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Obx(
          () => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: auth.passwordStrength.value,
              minHeight: 5,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(
                auth.passwordStrengthColor.value,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54, // large height
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), // fully rounded
          ),
        ),
        child: isLoading
            ? Center(
                child: LoadingAnimationWidget.discreteCircle(
                  color: Colors.white,
                  size: 24,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _loginHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () => Get.back(),
          child: Text(
            'Log in',
            style: TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimary, size: 14),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3748),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowDivider() => Divider(color: Colors.grey.shade100, height: 1);
}
