
import 'dart:io';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/currency_controller.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/companyprofile/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bg = Color(0xFFF5F5F7);
  static const Color _cardBg = Colors.white;
  static const Color _textPrimary = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF8E8E9A);
  static const Color _divider = Color(0xFFF0F0F5);


  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: _bg,
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: 44,
            ),
          );
        }
        return CustomScrollView(
          slivers: [
            // ── AppBar ──
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: _bg,
              surfaceTintColor: Colors.transparent,
              leading: GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.chevron_left_rounded,
                    color: _textPrimary, size: 28),
              ),
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
              actions: [
                Obx(() => _buildEditAction(controller)),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // ── Avatar + Name block ──
                      _buildAvatarSection(controller),

                      const SizedBox(height: 16),

                      // ── Quick action cards (like screenshot's "New" / "My Recent Order") ──
                      _buildQuickActions(controller),

                      const SizedBox(height: 20),

                      _buildSectionHeader('Organization Information'),
                      _buildMenuCard([
                        _buildMenuItem(
                          icon: Icons.business_center_rounded,
                          label: 'Organization Name',
                          value: controller.organizationName.value.isEmpty
                              ? 'Not set'
                              : controller.organizationName.value,
                          isEditing: controller.isEditing.value,
                          controller: controller.orgNameController,
                          hint: 'Enter organization name',
                        ),
                        _buildMenuDivider(),
                        _buildMenuItem(
                          icon: Icons.person_rounded,
                          label: 'Contact Person',
                          value: controller.personName.value.isEmpty
                              ? 'Not set'
                              : controller.personName.value,
                          isEditing: controller.isEditing.value,
                          controller: controller.firstNameController,
                          hint: 'First name',
                        ),
                        _buildMenuDivider(),
                        _buildMenuItem(
                          icon: Icons.location_on_rounded,
                          label: 'Country',
                          value: controller.country.value.isEmpty
                              ? 'Not set'
                              : controller.country.value,
                          isEditing: controller.isEditing.value,
                          controller: controller.countryController,
                          hint: 'Country',
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Contact section ──
                      _buildSectionHeader('Contact Details'),
                      _buildMenuCard([
                        _buildMenuItem(
                          icon: Icons.email_rounded,
                          label: 'Email Address',
                          value: controller.emailController.text.isEmpty
                              ? 'Not set'
                              : controller.emailController.text,
                          isEditing: controller.isEditing.value,
                          controller: controller.emailController,
                          hint: 'company@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        _buildMenuDivider(),
                        _buildMenuItem(
                          icon: Icons.phone_rounded,
                          label: 'Contact Number',
                          value: controller.contactNoController.text.isEmpty
                              ? 'Not set'
                              : controller.contactNoController.text,
                          isEditing: controller.isEditing.value,
                          controller: controller.contactNoController,
                          hint: '+92 300 0000000',
                          keyboardType: TextInputType.phone,
                        ),
                        _buildMenuDivider(),
                        _buildMenuItem(
                          icon: Icons.language_rounded,
                          label: 'Website',
                          value: controller.websiteController.text.isEmpty
                              ? 'Not set'
                              : controller.websiteController.text,
                          isEditing: controller.isEditing.value,
                          controller: controller.websiteController,
                          hint: 'https://yourcompany.com',
                          keyboardType: TextInputType.url,
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Business section ──
                      _buildSectionHeader('Business Details'),
                      _buildMenuCard([
                        _buildMenuItem(
                          icon: Icons.factory_rounded,
                          label: 'Industry',
                          value: controller.industryController.text.isEmpty
                              ? 'Not set'
                              : controller.industryController.text,
                          isEditing: controller.isEditing.value,
                          controller: controller.industryController,
                          hint: 'e.g., Retail, Manufacturing',
                        ),
                        _buildMenuDivider(),
                        _buildDropdownItem(
                          icon: Icons.schema_rounded,
                          label: 'Business Type',
                          value: controller.businessType.value,
                          items: controller.businessTypes,
                          enabled: controller.isEditing.value,
                          onChanged: (v) {
                            if (v != null) {
                              controller.businessTypeController.text = v;
                              controller.businessType.value = v;
                            }
                          },
                        ),
                        _buildMenuDivider(),
                        _buildDropdownItem(
                          icon: Icons.calendar_month_rounded,
                          label: 'Fiscal Year',
                          value: controller.fiscalYear.value,
                          items: controller.fiscalYears,
                          enabled: controller.isEditing.value,
                          onChanged: (v) {
                            if (v != null) {
                              controller.fiscalYearController.text = v;
                              controller.fiscalYear.value = v;
                            }
                          },
                        ),
                        _buildMenuDivider(),
                        _buildMenuItem(
                          icon: Icons.receipt_long_rounded,
                          label: 'Tax Registration (NTN/GST)',
                          value: controller.taxRegistrationController.text.isEmpty
                              ? 'Not set'
                              : controller.taxRegistrationController.text,
                          isEditing: controller.isEditing.value,
                          controller: controller.taxRegistrationController,
                          hint: 'NTN / GST / VAT Number',
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Currency section ──
                      _buildSectionHeader('Currency Settings'),
                      _buildCurrencyCard(),

                      const SizedBox(height: 20),

                      // ── Media section ──
                      _buildSectionHeader('Business Media'),
                      _buildMenuCard([
                        _buildMediaRow(
                          icon: Icons.image_rounded,
                          label: 'Business Logo',
                          subtitle: 'Appears on invoices & reports',
                          path: controller.businessLogo,
                          enabled: controller.isEditing.value,
                          onTap: controller.pickBusinessLogo,
                        ),
                        _buildMenuDivider(),
                        _buildMediaRow(
                          icon: Icons.draw_rounded,
                          label: 'Authorized Signature',
                          subtitle: 'Used on official documents',
                          path: controller.signature,
                          enabled: controller.isEditing.value,
                          onTap: () =>
                              _showSignatureOptions(context, controller),
                        ),
                      ]),

                      const SizedBox(height: 100),
                    ],
                  ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        if (!controller.isEditing.value) return const SizedBox.shrink();
        return _buildBottomSaveBar(controller);
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AVATAR SECTION  (like screenshot: circle avatar, name, email, edit badge)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAvatarSection(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Avatar with edit badge
          Stack(
            children: [
              Obx(() {
                final logo = controller.businessLogo.value;
                return Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimary.withOpacity(0.12),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: logo.isNotEmpty
                      ? ClipOval(
                          child: logo.startsWith('http')
                              ? Image.network(logo, fit: BoxFit.cover)
                              : Image.file(File(logo), fit: BoxFit.cover),
                        )
                      : Center(
                          child: Text(
                            controller.organizationName.value.isEmpty
                                ? 'LP'
                                : controller.organizationName.value
                                    .substring(
                                        0,
                                        controller.organizationName.value
                                                    .length >
                                                2
                                            ? 2
                                            : controller
                                                .organizationName.value.length)
                                    .toUpperCase(),
                            style: TextStyle(
                              color: kPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                );
              }),
              // Edit badge
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: controller.toggleEdit,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Organization name
          Obx(() => Text(
                controller.organizationName.value.isEmpty
                    ? 'Your Organization'
                    : controller.organizationName.value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -0.3,
                ),
              )),
          const SizedBox(height: 4),
          // Email
          Text(
            controller.emailController.text.isEmpty
                ? 'No email set'
                : controller.emailController.text,
            style: const TextStyle(
              fontSize: 13,
              color: _textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK ACTION CARDS  (like screenshot: "New discounts" / "My Recent Order")
  // ═══════════════════════════════════════════════════════════════

  Widget _buildQuickActions(ProfileController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Connect / Upgrade prompt card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ERP',
                          style: TextStyle(
                            color: kPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: _textPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.north_east_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Obx(() => Text(
                        controller.businessType.value.isEmpty
                            ? 'Set up your\nbusiness profile'
                            : 'Manage your\nbusiness settings',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Currency / stats card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.attach_money_rounded,
                            color: Colors.white, size: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.more_horiz_rounded,
                          color: Colors.white54, size: 18),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Active Currency',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(() {
                    final ctrl = Get.find<CurrencyController>();
                    return Text(
                      '${ctrl.currencySymbol.value} ${ctrl.currencyCode.value}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SECTION HEADER  (like screenshot: "Personal Information")
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: _textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MENU CARD  (white card, list of rows — like screenshot)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMenuCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return const Divider(height: 1, color: _divider, indent: 56);
  }

  // ── Row item: icon + label + value (or text field when editing) ──
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimary, size: 16),
          ),
          const SizedBox(width: 12),
          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                isEditing
                    ? TextFormField(
                        controller: controller,
                        maxLines: maxLines,
                        keyboardType: keyboardType,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w400,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 4),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: kPrimary, width: 1.5),
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          color: value == 'Not set'
                              ? Colors.grey.shade400
                              : _textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ],
            ),
          ),
          // Chevron (view mode only)
          if (!isEditing)
            const Icon(Icons.chevron_right_rounded,
                color: _textSecondary, size: 20),
        ],
      ),
    );
  }

  // ── Dropdown item ──
  Widget _buildDropdownItem({
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required bool enabled,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                enabled
                    ? DropdownButtonFormField<String>(
                        value: value.isNotEmpty ? value : null,
                        isExpanded: true,
                        isDense: true,
                        hint: Text('Select...',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade400)),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        dropdownColor: Colors.white,
                        items: items
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(fontSize: 13)),
                                ))
                            .toList(),
                        onChanged: onChanged,
                      )
                    : Text(
                        value.isEmpty ? 'Not set' : value,
                        style: TextStyle(
                          fontSize: 14,
                          color: value.isEmpty
                              ? Colors.grey.shade400
                              : _textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ],
            ),
          ),
          if (!enabled)
            const Icon(Icons.chevron_right_rounded,
                color: _textSecondary, size: 20),
        ],
      ),
    );
  }

  // ── Media row (logo / signature preview inline) ──
  Widget _buildMediaRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required RxString path,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kPrimary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _textSecondary,
                    )),
              ],
            ),
          ),
          Obx(() {
            final p = path.value;
            if (p.isNotEmpty) {
              return GestureDetector(
                onTap: enabled ? onTap : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _divider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: p.startsWith('http')
                        ? Image.network(p, fit: BoxFit.cover)
                        : Image.file(File(p), fit: BoxFit.cover),
                  ),
                ),
              );
            }
            return enabled
                ? GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Upload',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : const Icon(Icons.chevron_right_rounded,
                    color: _textSecondary, size: 20);
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CURRENCY CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCurrencyCard() {
    final currencyCtrl = Get.find<CurrencyController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.currency_exchange_rounded,
                    color: kPrimary, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Default Currency',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() => DropdownButtonFormField<String>(
                          value: currencyCtrl.currencyCode.value,
                          isExpanded: true,
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 14,
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 0, vertical: 4),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          dropdownColor: Colors.white,
                          items: CurrencyController.currencies
                              .map((c) => DropdownMenuItem(
                                    value: c.code,
                                    child: Text(c.displayLabel,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (code) async {
                            if (code == null) return;
                            await currencyCtrl.setCurrency(code);
                            AppSnackbar.success(
                              kSuccess,
                              'Currency Updated',
                              'Now using ${currencyCtrl.currencySymbol.value}',
                            );
                          },
                        )),
                  ],
                ),
              ),
              Obx(() => Text(
                    currencyCtrl.currencySymbol.value,
                    style: TextStyle(
                      fontSize: 22,
                      color: kPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EDIT ACTION BUTTON  (top right)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEditAction(ProfileController controller) {
    if (controller.isEditing.value) {
      return GestureDetector(
        onTap: controller.toggleEdit,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.red.shade400,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: controller.toggleEdit,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.settings_rounded, color: kPrimary, size: 18),
      ),
    );
  }

  Widget _buildBottomSaveBar(ProfileController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () {
                      if (controller.validateForm()) {
                        controller.saveProfile();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kPrimary.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          )),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SIGNATURE BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════

  void _showSignatureOptions(
      BuildContext context, ProfileController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Signature',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.draw_rounded, color: kPrimary, size: 20),
                ),
                title: const Text('Draw Signature',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Use your finger to draw',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: _textSecondary),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.drawSignature(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B59B6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_rounded,
                      color: Color(0xFF9B59B6), size: 20),
                ),
                title: const Text('Upload from Gallery',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Select an image file',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: _textSecondary),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.pickSignatureFromGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}