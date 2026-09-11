// screens/add_employee_screen.dart - ADD/EDIT EMPLOYEE FORM

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:BisonsTechs_app/widgets/hr_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Map<String, dynamic>? employee;
  const AddEmployeeScreen({super.key, this.employee});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _joiningDateController = TextEditingController();
  final _salaryController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;

  // Enterprise: Bank details
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankBranchController = TextEditingController();
  // Enterprise: Emergency contact
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  // Enterprise: Pay grade
  final _payGradeController = TextEditingController();
  // Enterprise: lifecycle dates (stored as ISO strings)
  String? _probationEndDate;
  String? _confirmationDate;
  String? _contractEndDate;
  String? _terminationDate;

  // Dropdown selections
  String? _selectedDepartment;
  String? _selectedDesignation;
  String? _selectedOffice;
  String? _selectedShift;
  String? _selectedEmploymentType;
  String? _selectedEmployeeType;
  String? _selectedStatus;
  String? _selectedPayBasis;
  bool _saving = false;
  List<Map<String, dynamic>> _offices = [];

  // Date picker
  DateTime _joiningDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.employee != null;
    if (_isEditing) {
      _loadEmployeeData();
    } else {
      _selectedStatus = 'Active';
    }
    _loadOffices();
  }

  Future<void> _loadOffices() async {
    try {
      final rows = await HrApiService.instance.offices();
      if (!mounted) return;
      setState(() => _offices = rows.where((o) => o['isActive'] != false).toList());
    } catch (_) {}
  }

  void _loadEmployeeData() {
    final emp = widget.employee!;
    _nameController.text = emp['name'] ?? '';
    _emailController.text = emp['email'] ?? '';
    _phoneController.text = emp['phone'] ?? '';
    _employeeIdController.text = emp['employeeId'] ?? '';
    _selectedDepartment = emp['department'];
    _selectedDesignation = emp['designation'];
    _selectedOffice = emp['officeId']?.toString() ?? emp['office']?.toString();
    _selectedShift = emp['shift'];
    _selectedEmploymentType = emp['employmentType'];
    _selectedEmployeeType = emp['employeeType'];
    _selectedStatus = emp['status'];
    _selectedPayBasis = emp['payBasis'];
    _salaryController.text = (emp['salary'] ?? 0).toString();
    if (emp['joiningDate'] != null) {
      _joiningDate = DateTime.parse(emp['joiningDate']);
      _joiningDateController.text = DateFormat('dd MMM yyyy').format(_joiningDate);
    }
    // Enterprise / profile fields
    final profile = emp['profile'] is Map ? Map<String, dynamic>.from(emp['profile'] as Map) : <String, dynamic>{};
    _bankNameController.text = (emp['bankName'] ?? profile['bankName'] ?? '').toString();
    _bankAccountController.text = (emp['bankAccount'] ?? profile['bankAccount'] ?? '').toString();
    _bankBranchController.text = (emp['bankBranch'] ?? profile['bankBranch'] ?? '').toString();
    _emergencyContactController.text = (emp['emergencyContact'] ?? profile['emergencyContact'] ?? '').toString();
    _emergencyPhoneController.text = (emp['emergencyPhone'] ?? profile['emergencyPhone'] ?? '').toString();
    _payGradeController.text = (emp['payGrade'] ?? profile['payGrade'] ?? '').toString();
    _probationEndDate = emp['probationEndDate'] ?? profile['probationEndDate'];
    _confirmationDate = emp['confirmationDate'] ?? profile['confirmationDate'];
    _contractEndDate = emp['contractEndDate'] ?? profile['contractEndDate'];
    _terminationDate = emp['terminationDate'] ?? profile['terminationDate'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _joiningDateController.dispose();
    _salaryController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankBranchController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _payGradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      drawer: const HRDrawer(currentItem: 'add_employee'),
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfilePhotoSection(),
                    const SizedBox(height: 20),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 20),
                    _buildCompanyInfoSection(),
                    const SizedBox(height: 20),
                    _buildEmploymentSection(),
                    const SizedBox(height: 20),
                    _buildSalarySection(),
                    const SizedBox(height: 20),
                    _buildLifecycleSection(),
                    const SizedBox(height: 20),
                    _buildBankAndEmergencySection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Employee' : 'Add Employee',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _isEditing ? 'Update employee information' : 'Create a new employee',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isEditing)
                GestureDetector(
                  onTap: () {
                    // Delete employee
                    _showDeleteConfirmation();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePhotoSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimary.withValues(alpha: 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _isEditing && widget.employee!['image'] != null
                      ? Image.network(
                          widget.employee!['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildAvatarPlaceholder();
                          },
                        )
                      : _buildAvatarPlaceholder(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isEditing ? 'Change Photo' : 'Upload Photo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'JPG, PNG or GIF • Max 2MB',
            style: TextStyle(
              fontSize: 10,
              color: kSubText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: kPrimary.withValues(alpha: 0.1),
      child: Icon(
        Icons.person,
        size: 50,
        color: kPrimary.withValues(alpha: 0.5),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PERSONAL INFO SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name *',
          hint: 'Enter full name',
          icon: Icons.person_outline_rounded,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter full name' : null,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address *',
          hint: 'employee@company.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter email';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        if (!_isEditing) ...[
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passwordController,
            label: 'Password *',
            hint: 'HR will share this with the employee',
            icon: Icons.lock_outline,
            obscureText: !_showPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: kSubText,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Please set a password';
              if (value!.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm password *',
            hint: 'Re-enter password',
            icon: Icons.lock_outline,
            obscureText: !_showPassword,
            validator: (value) {
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
        const SizedBox(height: 14),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number *',
          hint: '0300-1234567',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter phone number' : null,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _employeeIdController,
          label: 'Employee ID',
          hint: 'EMP-001',
          icon: Icons.badge_outlined,
          enabled: false,
          suffix: _isEditing
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Auto',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: kSuccess,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // COMPANY INFO SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCompanyInfoSection() {
    return _buildSection(
      title: 'Company Information',
      icon: Icons.business_center_outlined,
      children: [
        _buildDropdownField(
          label: 'Department *',
          hint: 'Select department',
          value: _selectedDepartment,
          items: const ['Sales', 'IT', 'HR', 'Finance', 'Marketing', 'Operations'],
          onChanged: (value) => setState(() => _selectedDepartment = value),
          validator: (value) => value == null ? 'Please select department' : null,
        ),
        const SizedBox(height: 14),
        _buildDropdownField(
          label: 'Designation *',
          hint: 'Select designation',
          value: _selectedDesignation,
          items: const [
            'Manager',
            'Sr. Executive',
            'Executive',
            'Software Engineer',
            'Sales Executive',
            'Accountant',
            'HR Executive',
            'Intern'
          ],
          onChanged: (value) => setState(() => _selectedDesignation = value),
          validator: (value) => value == null ? 'Please select designation' : null,
        ),
        const SizedBox(height: 14),
        _buildDropdownField(
          label: 'Branch / Office *',
          hint: _offices.isEmpty ? 'Create an office first' : 'Select office',
          value: _offices.any((o) => o['id']?.toString() == _selectedOffice)
              ? _selectedOffice
              : null,
          items: _offices
              .map((o) => o['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .toList(),
          itemLabels: {
            for (final o in _offices)
              if ((o['id']?.toString() ?? '').isNotEmpty)
                o['id'].toString(): o['name']?.toString() ?? 'Office',
          },
          onChanged: (value) => setState(() => _selectedOffice = value),
          validator: (value) => value == null ? 'Please select office' : null,
        ),
        const SizedBox(height: 14),
        _buildDatePickerField(
          label: 'Joining Date *',
          date: _joiningDate,
          controller: _joiningDateController,
          onChanged: (date) {
            setState(() {
              _joiningDate = date;
              _joiningDateController.text = DateFormat('dd MMM yyyy').format(date);
            });
          },
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please select joining date' : null,
        ),
        const SizedBox(height: 14),
        _buildDropdownField(
          label: 'Assigned Shift *',
          hint: 'Select shift',
          value: _selectedShift,
          items: const ['Regular Shift (9-6)', 'Morning Shift (8-4)', 'Evening Shift (2-10)'],
          onChanged: (value) => setState(() => _selectedShift = value),
          validator: (value) => value == null ? 'Please select shift' : null,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPLOYMENT SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmploymentSection() {
    return _buildSection(
      title: 'Employment Details',
      icon: Icons.work_outline_rounded,
      children: [
        _buildDropdownField(
          label: 'Employment Type *',
          hint: 'Select type',
          value: _selectedEmploymentType,
          items: const ['Full Time', 'Part Time', 'Contract', 'Internship', 'Probation'],
          onChanged: (value) => setState(() => _selectedEmploymentType = value),
          validator: (value) => value == null ? 'Please select employment type' : null,
        ),
        const SizedBox(height: 14),
        _buildDropdownField(
          label: 'Employee Type *',
          hint: 'Select employee type',
          value: _selectedEmployeeType,
          items: const ['Office Employee', 'Field Employee', 'Salesman', 'Delivery Staff'],
          onChanged: (value) => setState(() => _selectedEmployeeType = value),
          validator: (value) => value == null ? 'Please select employee type' : null,
        ),
        const SizedBox(height: 14),
        _buildDropdownField(
          label: 'Status *',
          hint: 'Select status',
          value: _selectedStatus,
          items: const ['Active', 'Inactive', 'On Leave', 'Terminated'],
          onChanged: (value) => setState(() => _selectedStatus = value),
          validator: (value) => value == null ? 'Please select status' : null,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SALARY SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSalarySection() {
    return _buildSection(
      title: 'Salary Information',
      icon: Icons.attach_money_rounded,
      children: [
        _buildTextField(
          controller: _salaryController,
          label: 'Basic Salary *',
          hint: '0.00',
          icon: Icons.currency_rupee_rounded,
          prefixText: 'PKR ',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter salary';
            if (double.tryParse(value!) == null) return 'Please enter valid amount';
            return null;
          },
        ),
        const SizedBox(height: 14),
        _buildDropdownField(
          label: 'Pay basis',
          hint: 'Select pay basis',
          value: _selectedPayBasis,
          items: const ['Monthly', 'Daily', 'Hourly'],
          onChanged: (v) => setState(() => _selectedPayBasis = v),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _payGradeController,
          label: 'Pay grade (optional)',
          hint: 'e.g. G1, Manager Grade, BPS-17',
          icon: Icons.grade_rounded,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kPrimary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: kPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'House rent, transport & medical allowances are set in the payroll salary builder per employee.',
                  style: TextStyle(fontSize: 11, color: kSubText, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Employment lifecycle (probation, confirmation, contract, termination) ─
  Widget _buildLifecycleSection() {
    return _buildSection(
      title: 'Employment Lifecycle',
      icon: Icons.timeline_rounded,
      children: [
        _buildSimpleDatePicker('Probation end date', _probationEndDate, (d) => setState(() => _probationEndDate = d)),
        const SizedBox(height: 14),
        _buildSimpleDatePicker('Confirmation date', _confirmationDate, (d) => setState(() => _confirmationDate = d)),
        const SizedBox(height: 14),
        _buildSimpleDatePicker('Contract end date', _contractEndDate, (d) => setState(() => _contractEndDate = d)),
        const SizedBox(height: 14),
        _buildSimpleDatePicker('Termination date (if applicable)', _terminationDate, (d) => setState(() => _terminationDate = d)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline_rounded, size: 15, color: Colors.amber),
            SizedBox(width: 8),
            Expanded(child: Text('Probation period: PF waived, flagged on payslip. Termination: payslip pro-rated to last working day.', style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4))),
          ]),
        ),
      ],
    );
  }

  Widget _buildSimpleDatePicker(String label, String? value, void Function(String) onPicked) {
    return GestureDetector(
      onTap: () async {
        DateTime initial = DateTime.now();
        if (value != null && value.length >= 10) {
          try { initial = DateTime.parse(value); } catch (_) {}
        }
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPicked(DateFormat('yyyy-MM-dd').format(picked));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: kSubText),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: kSubText)),
            const SizedBox(height: 2),
            Text(value?.isNotEmpty == true ? value!.substring(0, 10) : 'Not set', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: value?.isNotEmpty == true ? Colors.black87 : Colors.grey.shade400)),
          ])),
          if (value?.isNotEmpty == true)
            GestureDetector(
              onTap: () => onPicked(''),
              child: Icon(Icons.clear, size: 16, color: kSubText),
            ),
        ]),
      ),
    );
  }

  // ── Bank & Emergency contact ─────────────────────────────────
  Widget _buildBankAndEmergencySection() {
    return _buildSection(
      title: 'Bank & Emergency Contact',
      icon: Icons.account_balance_rounded,
      children: [
        _buildTextField(
          controller: _bankNameController,
          label: 'Bank name',
          hint: 'e.g. HBL, UBL, MCB',
          icon: Icons.account_balance_rounded,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _bankAccountController,
          label: 'Account / IBAN number',
          hint: 'PK00XXXX0000000000000000',
          icon: Icons.credit_card_rounded,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _bankBranchController,
          label: 'Branch (optional)',
          hint: 'e.g. Gulberg, Lahore',
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 10),
        _buildTextField(
          controller: _emergencyContactController,
          label: 'Emergency contact name',
          hint: 'Full name',
          icon: Icons.contact_emergency_rounded,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _emergencyPhoneController,
          label: 'Emergency contact phone',
          hint: '03xx-xxxxxxx',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: const BorderSide(color: kPrimary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveEmployee,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _saving
                  ? 'Saving...'
                  : _isEditing
                      ? 'Update Employee'
                      : 'Save Employee',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                  color: kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: kPrimary),
              ),
               SizedBox(width: 10),
              Text(
                title,
                style:  TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const Spacer(),
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    bool enabled = true,
    bool obscureText = false,
    Widget? suffix,
    Widget? suffixIcon,
    String? prefixText,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 13,
        color: enabled ? Colors.black87 : kSubText,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: kSubText),
        prefixText: prefixText,
        suffix: suffix,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDanger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        labelStyle: TextStyle(
          fontSize: 12,
          color: enabled ? kSubText : Colors.grey.shade400,
        ),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        errorStyle: const TextStyle(fontSize: 10),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    Map<String, String>? itemLabels,
    required void Function(String?) onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDanger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        labelStyle:  TextStyle(fontSize: 12, color: kSubText),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        errorStyle: const TextStyle(fontSize: 10),
      ),
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
      ),
      icon: Icon(Icons.arrow_drop_down, size: 20, color: kSubText),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            itemLabels?[item] ?? item,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime date,
    required TextEditingController controller,
    required void Function(DateTime) onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: TextFormField(
        controller: controller,
        enabled: false,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
          suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kDanger),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
          labelStyle:  TextStyle(fontSize: 12, color: kSubText),
          errorStyle: const TextStyle(fontSize: 10),
        ),
        validator: validator,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final payload = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': _selectedDepartment,
        'designation': _selectedDesignation,
        'officeId': _selectedOffice,
        'shift': _selectedShift,
        'employmentType': _selectedEmploymentType,
        'employeeType': _selectedEmployeeType,
        'status': _selectedStatus,
        'salary': double.tryParse(_salaryController.text.trim()) ?? 0,
        'joiningDate': _joiningDate.toIso8601String(),
        if (!_isEditing) 'password': _passwordController.text.trim(),
        // Enterprise fields
        if (_selectedPayBasis != null) 'payBasis': _selectedPayBasis,
        if (_payGradeController.text.trim().isNotEmpty) 'payGrade': _payGradeController.text.trim(),
        if (_probationEndDate != null && _probationEndDate!.isNotEmpty) 'probationEndDate': _probationEndDate,
        if (_confirmationDate != null && _confirmationDate!.isNotEmpty) 'confirmationDate': _confirmationDate,
        if (_contractEndDate != null && _contractEndDate!.isNotEmpty) 'contractEndDate': _contractEndDate,
        if (_terminationDate != null && _terminationDate!.isNotEmpty) 'terminationDate': _terminationDate,
        if (_bankNameController.text.trim().isNotEmpty) 'bankName': _bankNameController.text.trim(),
        if (_bankAccountController.text.trim().isNotEmpty) 'bankAccount': _bankAccountController.text.trim(),
        if (_bankBranchController.text.trim().isNotEmpty) 'bankBranch': _bankBranchController.text.trim(),
        if (_emergencyContactController.text.trim().isNotEmpty) 'emergencyContact': _emergencyContactController.text.trim(),
        if (_emergencyPhoneController.text.trim().isNotEmpty) 'emergencyPhone': _emergencyPhoneController.text.trim(),
      };
      if (_isEditing && widget.employee?['id'] != null) {
        await HrApiService.instance.updateEmployee(
          widget.employee!['id'].toString(),
          payload,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee updated'),
            backgroundColor: kSuccess,
          ),
        );
        Navigator.of(context).pop(true);
        return;
      }
      await HrApiService.instance.createEmployee(payload);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Employee created'),
          content: Text(
            'Employee created. Share the email and the password you set. They will land on the employee dashboard only.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: kDanger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Employee'),
        content: const Text(
          'Are you sure you want to delete this employee?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: kSubText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Employee deleted!'),
                  backgroundColor: kDanger,
                ),
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
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}