// lib/core/warehouse/supplier/views/suppliers_screen.dart - UPDATED WITH PRODUCTS SCREEN DESIGN

import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/core/warehouse/supplier/controller/supplier_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SupplierController());

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          // ── Fixed top header ──
          _buildTopHeader(controller),
          // ── List area ──
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.suppliers.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 40,
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: _MobileSuppliersList(
                  controller: controller,
                  onSupplierTap: (s) =>
                      _showSupplierDetails(context, s, controller),
                  onAddSupplier: () =>
                      _showAddSupplierDialog(context, controller),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSupplierDialog(context, controller),
        backgroundColor: kPrimary,
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.black, size: 24),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER (Products Screen Style)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(SupplierController controller) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suppliers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.totalSuppliers.value} suppliers',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black.withOpacity(0.55),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Compact KPIs
                  Obx(
                    () => Row(
                      children: [
                        _compactKpi(
                          'Active',
                          controller.activeCount.value.toString(),
                          Colors.green.shade800,
                        ),
                        const SizedBox(width: 10),
                        _compactKpi(
                          'Inactive',
                          controller.inactiveCount.value.toString(),
                          Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: controller.refreshAll,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 17,
                        color: Colors.black.withOpacity(0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _SearchField(controller: controller),
              ),
            ),
            // Filter chips
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Row(
                  children: controller.filters.map((filter) {
                    final isSelected =
                        controller.selectedFilter.value == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => controller.filterSuppliers(filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.black
                                : Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.black.withOpacity(0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── SUPPLIER DETAILS ──────────────────────────────────────────

  void _showSupplierDetails(
    BuildContext context,
    Map<String, dynamic> supplier,
    SupplierController controller,
  ) {
    final status = supplier['status'] ?? 'active';
    final isActive = status == 'active';
    final statusColor = isActive
        ? const Color(0xFF2ECC71)
        : const Color(0xFFE74C3C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.storefront,
                              color: kPrimary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  supplier['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  supplier['contactPerson'] ??
                                      'No contact person',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kSubText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
                      const SizedBox(height: 16),
                      _detailRow(
                        'Contact Person',
                        supplier['contactPerson'] ?? '-',
                      ),
                      _detailRow('Email', supplier['email'] ?? '-'),
                      _detailRow('Phone', supplier['phone'] ?? '-'),
                      _detailRow('GST Number', supplier['gstNumber'] ?? '-'),
                      _detailRow(
                        'Payment Terms',
                        supplier['paymentTerms'] ?? '-',
                      ),
                      _detailRow('Address', supplier['address'] ?? '-'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditSupplierDialog(
                                  context,
                                  supplier,
                                  controller,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimary,
                                side: const BorderSide(color: kPrimary),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: kText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIALOGS ────────────────────────────────────────────────────

  void _showAddSupplierDialog(
    BuildContext context,
    SupplierController controller,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final contactPersonCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final gstCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String? selectedPaymentTerms;

    final paymentTermsOptions = [
      'Net 7',
      'Net 15',
      'Net 30',
      'Net 60',
      'Net 90',
      'Due on Receipt',
      'COD',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: kPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Supplier',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _fieldLabel('Supplier Name *'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _inputDec(
                      hint: 'e.g., ABC Traders',
                      icon: Icons.storefront_outlined,
                    ),
                    style: TextStyle(fontSize: 13, color: kText),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Contact Person'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: contactPersonCtrl,
                    decoration: _inputDec(
                      hint: 'e.g., Ali Khan',
                      icon: Icons.person_outline,
                    ),
                    style: TextStyle(fontSize: 13, color: kText),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Email'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDec(
                      hint: 'supplier@example.com',
                      icon: Icons.email_outlined,
                    ),
                    style: TextStyle(fontSize: 13, color: kText),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !v.contains('@')) {
                        return 'Enter valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Phone'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDec(
                      hint: '+92 300 0000000',
                      icon: Icons.phone_outlined,
                    ),
                    style: TextStyle(fontSize: 13, color: kText),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('GST Number'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: gstCtrl,
                    decoration: _inputDec(
                      hint: 'GST-XXXXXXX',
                      icon: Icons.receipt_long_outlined,
                    ),
                    style: TextStyle(fontSize: 13, color: kText),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Payment Terms'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPaymentTerms,
                        hint: Text(
                          'Select terms',
                          style: TextStyle(
                            color: kSubText.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                        isExpanded: true,
                        dropdownColor: kCardBg,
                        items: paymentTermsOptions.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => selectedPaymentTerms = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Address (Optional)'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: _inputDec(hint: 'Street, City, Country...'),
                    style: TextStyle(fontSize: 13, color: kText),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: kSubText)),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await controller.createSupplier({
                          'name': nameCtrl.text.trim(),
                          'contactPerson': contactPersonCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'gstNumber': gstCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          if (selectedPaymentTerms != null)
                            'paymentTerms': selectedPaymentTerms,
                        });
                        if (success) {
                          Navigator.pop(context);
                          Get.snackbar(
                            'Success',
                            'Supplier created successfully',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kSuccess,
                            colorText: Colors.black,
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            'Failed to create supplier',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kDanger,
                            colorText: Colors.black,
                            margin: const EdgeInsets.all(16),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Save Supplier',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSupplierDialog(
    BuildContext context,
    Map<String, dynamic> supplier,
    SupplierController controller,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: supplier['name'] ?? '');
    final contactPersonCtrl = TextEditingController(
      text: supplier['contactPerson'] ?? '',
    );
    final emailCtrl = TextEditingController(text: supplier['email'] ?? '');
    final phoneCtrl = TextEditingController(text: supplier['phone'] ?? '');
    final gstCtrl = TextEditingController(text: supplier['gstNumber'] ?? '');
    final addressCtrl = TextEditingController(text: supplier['address'] ?? '');
    String? selectedPaymentTerms = supplier['paymentTerms'];
    String selectedStatus = supplier['status'] ?? 'active';

    final paymentTermsOptions = [
      'Net 7',
      'Net 15',
      'Net 30',
      'Net 60',
      'Net 90',
      'Due on Receipt',
      'COD',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_outlined, color: kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Edit Supplier',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _fieldLabel('Supplier Name *'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: _inputDec(icon: Icons.storefront_outlined),
                    style: TextStyle(fontSize: 13, color: kText),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Contact Person'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: contactPersonCtrl,
                    decoration: _inputDec(icon: Icons.person_outline),
                    style: TextStyle(fontSize: 13, color: kText),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Email'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDec(icon: Icons.email_outlined),
                    style: TextStyle(fontSize: 13, color: kText),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !v.contains('@')) {
                        return 'Enter valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Phone'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDec(icon: Icons.phone_outlined),
                    style: TextStyle(fontSize: 13, color: kText),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('GST Number'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: gstCtrl,
                    decoration: _inputDec(icon: Icons.receipt_long_outlined),
                    style: TextStyle(fontSize: 13, color: kText),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Payment Terms'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedPaymentTerms,
                        hint: Text(
                          'Select',
                          style: TextStyle(
                            color: kSubText.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                        isExpanded: true,
                        dropdownColor: kCardBg,
                        items: paymentTermsOptions.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => selectedPaymentTerms = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Address'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: _inputDec(),
                    style: TextStyle(fontSize: 13, color: kText),
                  ),
                  const SizedBox(height: 12),
                  _fieldLabel('Status'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        dropdownColor: kCardBg,
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text(
                              'Inactive',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => selectedStatus = v ?? 'active'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: kSubText)),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final success = await controller.updateSupplier(
                          supplier['_id'] ?? supplier['id'] ?? '',
                          {
                            'name': nameCtrl.text.trim(),
                            'contactPerson': contactPersonCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'phone': phoneCtrl.text.trim(),
                            'gstNumber': gstCtrl.text.trim(),
                            'address': addressCtrl.text.trim(),
                            'status': selectedStatus,
                            if (selectedPaymentTerms != null)
                              'paymentTerms': selectedPaymentTerms,
                          },
                        );
                        if (success) {
                          Navigator.pop(context);
                          Get.snackbar(
                            'Success',
                            'Supplier updated successfully',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kSuccess,
                            colorText: Colors.black,
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            'Failed to update supplier',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: kDanger,
                            colorText: Colors.black,
                            margin: const EdgeInsets.all(16),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Update Supplier',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    Map<String, dynamic> supplier,
    SupplierController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kDanger, size: 22),
            const SizedBox(width: 10),
            Text(
              'Delete Supplier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${supplier['name']}"?',
              style: TextStyle(fontSize: 14, color: kText),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kDanger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kDanger.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: kDanger, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If this supplier has linked products or purchases, they will be deactivated instead.',
                      style: TextStyle(fontSize: 13, color: kDanger),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kSubText)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.deleteSupplier(
                supplier['_id'] ?? supplier['id'] ?? '',
              );
              Get.snackbar(
                success ? 'Success' : 'Error',
                success
                    ? 'Supplier removed successfully'
                    : 'Failed to remove supplier',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: success ? kSuccess : kDanger,
                colorText: Colors.black,
                margin: const EdgeInsets.all(16),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: kSubText,
      ),
    ),
  );

  InputDecoration _inputDec({String hint = '', IconData? icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kSubText.withOpacity(0.5), fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, size: 16, color: kSubText) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        isDense: true,
        filled: true,
        fillColor: kCardBg,
      );
}

// ═══════════════════════════════════════════════════════════════
// SEARCH FIELD
// ═══════════════════════════════════════════════════════════════
class _SearchField extends StatefulWidget {
  final SupplierController controller;
  const _SearchField({required this.controller});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) {
        setState(() {});
        v.isEmpty
            ? widget.controller.clearSearch()
            : widget.controller.searchSuppliers(v);
      },
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'Search suppliers...',
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
        suffixIcon: _searchCtrl.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  widget.controller.clearSearch();
                  setState(() {});
                },
                child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
              )
            : null,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        isDense: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MOBILE SUPPLIERS LIST
// ═══════════════════════════════════════════════════════════════
class _MobileSuppliersList extends StatefulWidget {
  final SupplierController controller;
  final void Function(Map<String, dynamic>) onSupplierTap;
  final VoidCallback onAddSupplier;

  const _MobileSuppliersList({
    required this.controller,
    required this.onSupplierTap,
    required this.onAddSupplier,
  });

  @override
  State<_MobileSuppliersList> createState() => _MobileSuppliersListState();
}

class _MobileSuppliersListState extends State<_MobileSuppliersList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300 &&
        position.maxScrollExtent > 0) {
      widget.controller.fetchMoreSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final suppliers = widget.controller.suppliers;

      if (suppliers.isEmpty && !widget.controller.isLoading.value) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 36,
                  color: kPrimary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No suppliers yet',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap + to add your first supplier',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: widget.onAddSupplier,
                icon: const Icon(Icons.add, size: 16, color: Colors.black),
                label: const Text(
                  'Add Supplier',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => widget.controller.refreshAll(),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: suppliers.length + 1,
          itemBuilder: (context, index) {
            if (index == suppliers.length) return _buildFooter();
            final supplier = suppliers[index];
            final status = supplier['status'] ?? 'active';
            final isActive = status == 'active';
            final statusColor = isActive
                ? const Color(0xFF2ECC71)
                : const Color(0xFFE74C3C);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => widget.onSupplierTap(supplier),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.storefront,
                            color: kPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              if (supplier['contactPerson'] != null)
                                Text(
                                  supplier['contactPerson'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kSubText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Row(
                                children: [
                                  if (supplier['paymentTerms'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        supplier['paymentTerms'],
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: kPrimary,
                                        ),
                                      ),
                                    ),
                                  if (supplier['paymentTerms'] != null)
                                    const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Chevron
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildFooter() {
    if (widget.controller.isLoadingMore.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (!widget.controller.hasMore.value &&
        widget.controller.suppliers.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(
            'All suppliers loaded',
            style: TextStyle(fontSize: 12, color: kSubText.withOpacity(0.7)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
