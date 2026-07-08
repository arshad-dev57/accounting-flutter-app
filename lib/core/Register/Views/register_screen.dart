// lib/core/Register/Views/register_screen.dart

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
      backgroundColor: kBgLight,
      body: _buildMobileLayout(context, auth),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AuthController auth) {
    return Column(
      children: [
        _buildStickyHeader(context, auth),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Obx(() => _buildStepContent(auth, context)),
          ),
        ),
      ],
    );
  }

  Widget _buildStickyHeader(BuildContext context, AuthController auth) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryDark, kPrimary],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'LedgerPro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    if (auth.currentStep.value == 0 ||
                        auth.currentStep.value == 4) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: () => auth.previousStep(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() {
                final titles = [
                  'Personal Info',
                  'Contact & Business',
                  'Company Details',
                  'Create Password',
                  'All Done!',
                ];
                final subtitles = [
                  'Step 1 of 4 — Tell us who you are',
                  'Step 2 of 4 — How to reach you',
                  'Step 3 of 4 — Business information',
                  'Step 4 of 4 — Secure your account',
                  'Your account is ready',
                ];
                final step = auth.currentStep.value.clamp(0, 4);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titles[step],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitles[step],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 20),
              Obx(() => _buildProgressIndicator(auth)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(AuthController auth) {
    const totalSteps = 4;
    final step = auth.currentStep.value;

    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (i) {
            final filled = i < step;
            final active = i == step;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: filled
                      ? Colors.white
                      : active
                      ? Colors.white.withOpacity(0.5)
                      : Colors.white.withOpacity(0.22),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stepLabel('Personal', 0, step),
            const Spacer(),
            _stepLabel('Contact', 1, step),
            const Spacer(),
            _stepLabel('Business', 2, step),
            const Spacer(),
            _stepLabel('Password', 3, step),
          ],
        ),
      ],
    );
  }

  Widget _stepLabel(String label, int index, int currentStep) {
    final isDone = currentStep > index;
    final isActive = currentStep == index;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? Colors.white
                : isActive
                ? Colors.white.withOpacity(0.3)
                : Colors.transparent,
            border: Border.all(
              color: Colors.white.withOpacity(isDone || isActive ? 1 : 0.35),
              width: 1.5,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, color: kPrimary, size: 11)
              : isActive
              ? null
              : null,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(
              isDone || isActive ? 1 : 0.45,
            ),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
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
        const SizedBox(height: 28),
        _sectionCard(
          children: [
            _fieldLabel('First Name', context),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.firstNameController,
              hint: 'Enter your first name',
              icon: Icons.person_outline,
              context: context,
            ),
            const SizedBox(height: 20),
            _fieldLabel('Last Name', context),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.lastNameController,
              hint: 'Enter your last name',
              icon: Icons.person_outline,
              context: context,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          children: [
            _fieldLabel('Country', context),
            const SizedBox(height: 8),
            _countryPickerField(auth, context),
            const SizedBox(height: 20),
            _fieldLabel('Currency', context),
            const SizedBox(height: 4),
            Text(
              'Auto-selected from country — change anytime',
              style: TextStyle(fontSize: 11.5, color: kSubTextLight),
            ),
            const SizedBox(height: 10),
            _currencyDropdownField(auth, context),
          ],
        ),
        const SizedBox(height: 28),
        _primaryButton(
          label: 'Continue',
          onTap: () => auth.nextStep(),
          isLoading: auth.isLoading.value,
          context: context,
        ),
        const SizedBox(height: 16),
        _loginHint(context),
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
        const SizedBox(height: 28),
        _sectionCard(
          children: [
            _fieldLabel('Phone Number', context),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.phoneController,
              hint: '+92 300 1234567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              context: context,
            ),
            const SizedBox(height: 20),
            _fieldLabel('Email Address', context),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.emailController,
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              context: context,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          label: 'Address (Optional)',
          children: [
            _fieldLabel('Street Address', context),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.addressController,
              hint: 'Street, City, Postal Code',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              context: context,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _termsCheckbox(auth, context),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Continue',
          onTap: () => auth.nextStep(),
          isLoading: auth.isLoading.value,
          context: context,
        ),
        const SizedBox(height: 16),
        _loginHint(context),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // STEP 3 — BUSINESS DETAILS (NEW)
  // ══════════════════════════════════════════════════
  Widget _buildBusinessStep(AuthController auth, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text(
          'Business Information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: kTextLight,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'These details will appear on your invoices and reports',
          style: TextStyle(
            fontSize: 12,
            color: kSubTextLight,
          ),
        ),
        const SizedBox(height: 18),
        _sectionCard(
          children: [
            _fieldLabel('Company / Organization Name', context),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.organizationNameController,
              hint: 'e.g., ABC Traders',
              icon: Icons.business_outlined,
              context: context,
            ),
            const SizedBox(height: 20),
            _fieldLabel('Industry', context),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.industryController,
              hint: 'e.g., Retail, Manufacturing, Services',
              icon: Icons.factory_outlined,
              context: context,
            ),
            const SizedBox(height: 20),
            _fieldLabel('Business Type', context),
            const SizedBox(height: 8),
            _businessTypeDropdown(auth, context),
            const SizedBox(height: 20),
            _fieldLabel('Fiscal Year', context),
            const SizedBox(height: 8),
            _fiscalYearDropdown(auth, context),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          label: 'Registration & Tax Info',
          children: [
            _fieldLabel('Tax Registration Number', context),
            const SizedBox(height: 8),
            _inputField(
              controller: auth.taxRegistrationController,
              hint: 'e.g., NTN, GST, VAT Number',
              icon: Icons.receipt_outlined,
              context: context,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _primaryButton(
          label: 'Continue',
          onTap: () => auth.nextStep(),
          isLoading: auth.isLoading.value,
          context: context,
        ),
        const SizedBox(height: 16),
        _loginHint(context),
      ],
    );
  }

  // ── Business Type Dropdown ────────────────────────
  Widget _businessTypeDropdown(AuthController auth, BuildContext context) {
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
      () => Container(
        decoration: BoxDecoration(
          color: kBgLight,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: kBorderLight, width: 1.5),
        ),
        child: DropdownButtonFormField<String>(
          value: auth.selectedBusinessType.value.isEmpty
              ? null
              : auth.selectedBusinessType.value,
          hint: const Text(
            'Select business type',
            style: TextStyle(color: kSubTextLight, fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: kSubTextLight),
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            prefixIcon: Icon(
              Icons.business_center_outlined,
              color: kSubTextLight,
              size: 20,
            ),
          ),
          items: businessTypes
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: const TextStyle(fontSize: 13.5),
                  ),
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

  // ── Fiscal Year Dropdown ──────────────────────────
  Widget _fiscalYearDropdown(AuthController auth, BuildContext context) {
    final fiscalYears = [
      'January - December',
      'July - June',
      'April - March',
      'October - September',
      'Custom',
    ];

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: kBgLight,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: kBorderLight, width: 1.5),
        ),
        child: DropdownButtonFormField<String>(
          value: auth.selectedFiscalYear.value.isEmpty
              ? null
              : auth.selectedFiscalYear.value,
          hint: const Text(
            'Select fiscal year',
            style: TextStyle(color: kSubTextLight, fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: kSubTextLight),
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            prefixIcon: Icon(
              Icons.calendar_today_outlined,
              color: kSubTextLight,
              size: 20,
            ),
          ),
          items: fiscalYears
              .map(
                (year) => DropdownMenuItem(
                  value: year,
                  child: Text(
                    year,
                    style: const TextStyle(fontSize: 13.5),
                  ),
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
        const SizedBox(height: 28),
        _sectionCard(
          children: [
            _fieldLabel('Password', context),
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
                        color: kSubTextLight,
                        size: 20,
                      ),
                      onPressed: () => auth.isPasswordVisible.value =
                          !auth.isPasswordVisible.value,
                    ),
                    context: context,
                  ),
                  if (showStrength) ...[
                    const SizedBox(height: 10),
                    _passwordStrength(auth, context),
                  ],
                ],
              );
            }),
            const SizedBox(height: 20),
            _fieldLabel('Confirm Password', context),
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
                    color: kSubTextLight,
                    size: 20,
                  ),
                  onPressed: () => auth.isConfirmPasswordVisible.value =
                      !auth.isConfirmPasswordVisible.value,
                ),
                context: context,
              );
            }),
          ],
        ),
        const SizedBox(height: 28),
        _primaryButton(
          label: 'Create Account',
          onTap: () => auth.nextStep(),
          isLoading: auth.isLoading.value,
          context: context,
        ),
        const SizedBox(height: 16),
        _loginHint(context),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // SUCCESS STEP
  // ══════════════════════════════════════════════════
  Widget _buildSuccessStep(AuthController auth, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 28),
        Center(
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimary, kPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Account Activated!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kTextLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Welcome, ${auth.firstNameController.text}! 🎉',
                style: const TextStyle(fontSize: 14, color: kSubTextLight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionCard(
          label: 'Account Summary',
          children: [
            _infoRow(Icons.person, 'Name',
                '${auth.firstNameController.text} ${auth.lastNameController.text}'),
            _infoRowDivider(),
            _infoRow(Icons.public, 'Country', auth.countryController.text),
            _infoRowDivider(),
            _infoRow(Icons.attach_money, 'Currency',
                auth.selectedCurrencyCode.value),
            _infoRowDivider(),
            _infoRow(Icons.phone, 'Phone', auth.phoneController.text),
            _infoRowDivider(),
            _infoRow(Icons.email, 'Email', auth.emailController.text),
            if (auth.organizationNameController.text.isNotEmpty) ...[
              _infoRowDivider(),
              _infoRow(Icons.business, 'Company',
                  auth.organizationNameController.text),
            ],
            if (auth.industryController.text.isNotEmpty) ...[
              _infoRowDivider(),
              _infoRow(Icons.factory_outlined, 'Industry',
                  auth.industryController.text),
            ],
            if (auth.selectedBusinessType.value.isNotEmpty) ...[
              _infoRowDivider(),
              _infoRow(Icons.business_center_outlined, 'Business Type',
                  auth.selectedBusinessType.value),
            ],
            if (auth.selectedFiscalYear.value.isNotEmpty) ...[
              _infoRowDivider(),
              _infoRow(Icons.calendar_today_outlined, 'Fiscal Year',
                  auth.selectedFiscalYear.value),
            ],
            if (auth.taxRegistrationController.text.isNotEmpty) ...[
              _infoRowDivider(),
              _infoRow(Icons.receipt_outlined, 'Tax Registration',
                  auth.taxRegistrationController.text),
            ],
          ],
        ),
        const SizedBox(height: 28),
        _primaryButton(
          label: 'Get Started',
          onTap: () => auth.resetForm(),
          isLoading: false,
          context: context,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ══════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════

  Widget _sectionCard({
    String? label,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: kPrimary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 14),
            Divider(color: kBorderLight, height: 1),
            const SizedBox(height: 14),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kTextLight,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required BuildContext context,
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
      style: const TextStyle(fontSize: 14, color: kTextLight),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kSubTextLight, fontSize: 14),
        filled: true,
        fillColor: kBgLight,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: kBorderLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        prefixIcon: Icon(icon, color: kSubTextLight, size: 20),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _countryPickerField(AuthController auth, BuildContext context) {
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
              auth.countryController.text = selected.name;
              auth.country.value = selected.name;

              final rawCurrency = selected.currency.toString();
              final code = _extractCurrencyCode(rawCurrency);
              if (code != null) {
                auth.selectedCurrencyCode.value = code;
              }
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: kBgLight,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: kBorderLight, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.public, color: kSubTextLight, size: 20),
              const SizedBox(width: 10),
              if (country != null) ...[
                Text(
                  country.flagEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  country?.name ?? 'Select your country',
                  style: TextStyle(
                    fontSize: 14,
                    color: country != null ? kTextLight : kSubTextLight,
                    fontWeight: country != null ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: kSubTextLight,
                size: 20,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _currencyDropdownField(AuthController auth, BuildContext context) {
    final allCurrencies = _buildAllCurrencies();

    return Obx(
      () => Container(
        decoration: BoxDecoration(
          color: kBgLight,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: kBorderLight, width: 1.5),
        ),
        child: DropdownButtonFormField<String>(
          value: auth.selectedCurrencyCode.value.isEmpty
              ? null
              : auth.selectedCurrencyCode.value,
          hint: const Text(
            'Select currency',
            style: TextStyle(color: kSubTextLight, fontSize: 14),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: kSubTextLight),
          isExpanded: true,
          dropdownColor: Colors.white,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            prefixIcon: Icon(
              Icons.attach_money,
              color: kSubTextLight,
              size: 20,
            ),
          ),
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

  Widget _termsCheckbox(AuthController auth, BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: () => auth.agreeToTerms.value = !auth.agreeToTerms.value,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.scale(
              scale: 1.1,
              child: Checkbox(
                value: auth.agreeToTerms.value,
                onChanged: (v) => auth.agreeToTerms.value = v ?? false,
                activeColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                side: BorderSide(color: kBorderLight, width: 1.5),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: RichText(
                  text: TextSpan(
                    text: 'I agree to the ',
                    style: const TextStyle(
                      color: kSubTextLight,
                      fontSize: 13,
                      height: 1.5,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ' and '),
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

  Widget _passwordStrength(AuthController auth, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Strength: ',
              style: TextStyle(fontSize: 12, color: kSubTextLight),
            ),
            Obx(
              () => Text(
                auth.passwordStrengthText.value,
                style: TextStyle(
                  fontSize: 12,
                  color: auth.passwordStrengthColor.value,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Obx(
          () => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: auth.passwordStrength.value,
              minHeight: 5,
              backgroundColor: kBorderLight,
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
    required BuildContext context,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? Center(
                child: LoadingAnimationWidget.discreteCircle(
                  color: Colors.white,
                  size: 26,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _loginHint(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Already have an account? ',
          style: const TextStyle(color: kSubTextLight, fontSize: 13),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: () => Get.back(),
                child: Text(
                  'Sign in',
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimary, size: 15),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: kSubTextLight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kTextLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowDivider() => Divider(color: kBorderLight, height: 1);
}