// screens/payroll_generation_screen.dart - PAYROLL GENERATION

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PayrollGenerationScreen extends StatefulWidget {
  const PayrollGenerationScreen({super.key});

  @override
  State<PayrollGenerationScreen> createState() =>
      _PayrollGenerationScreenState();
}

class _PayrollGenerationScreenState extends State<PayrollGenerationScreen>
    with SingleTickerProviderStateMixin {
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  String _selectedStatus = 'All';
  bool isGenerating = false;
  late TabController _tabController;

  // Sample payroll data
  final List<Map<String, dynamic>> _payrollData = [
    {
      'id': 'PAY-001',
      'employeeId': 'EMP-001',
      'employeeName': 'Ahmed Khan',
      'department': 'Sales',
      'designation': 'Sales Manager',
      'basicSalary': 120000,
      'allowances': {
        'house': 30000,
        'transport': 10000,
        'medical': 5000,
      },
      'commission': 30000,
      'overtime': 4500,
      'earnings': {
        'bonus': 5000,
        'other': 0,
      },
      'deductions': {
        'absent': 0,
        'late': 0,
        'loan': 15000,
        'tax': 5000,
        'other': 0,
      },
      'attendance': {
        'present': 22,
        'late': 0,
        'absent': 0,
        'leave': 0,
        'holiday': 4,
        'weeklyOff': 4,
      },
      'status': 'DRAFT',
      'generatedOn': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': 'PAY-002',
      'employeeId': 'EMP-002',
      'employeeName': 'Sara Ali',
      'department': 'IT',
      'designation': 'Software Engineer',
      'basicSalary': 80000,
      'allowances': {
        'house': 20000,
        'transport': 8000,
        'medical': 5000,
      },
      'commission': 0,
      'overtime': 3000,
      'earnings': {
        'bonus': 0,
        'other': 2000,
      },
      'deductions': {
        'absent': 3000,
        'late': 500,
        'loan': 0,
        'tax': 3000,
        'other': 0,
      },
      'attendance': {
        'present': 20,
        'late': 2,
        'absent': 1,
        'leave': 1,
        'holiday': 4,
        'weeklyOff': 4,
      },
      'status': 'REVIEW',
      'generatedOn': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': 'PAY-003',
      'employeeId': 'EMP-003',
      'employeeName': 'Usman Raza',
      'department': 'Sales',
      'designation': 'Field Salesman',
      'basicSalary': 60000,
      'allowances': {
        'house': 15000,
        'transport': 10000,
        'medical': 5000,
      },
      'commission': 45000,
      'overtime': 2000,
      'earnings': {
        'bonus': 3000,
        'other': 0,
      },
      'deductions': {
        'absent': 0,
        'late': 0,
        'loan': 0,
        'tax': 2000,
        'other': 0,
      },
      'attendance': {
        'present': 22,
        'late': 0,
        'absent': 0,
        'leave': 0,
        'holiday': 4,
        'weeklyOff': 4,
      },
      'status': 'APPROVED',
      'generatedOn': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'id': 'PAY-004',
      'employeeId': 'EMP-004',
      'employeeName': 'Fatima Noor',
      'department': 'HR',
      'designation': 'HR Executive',
      'basicSalary': 70000,
      'allowances': {
        'house': 17500,
        'transport': 7000,
        'medical': 5000,
      },
      'commission': 0,
      'overtime': 1500,
      'earnings': {
        'bonus': 2000,
        'other': 0,
      },
      'deductions': {
        'absent': 0,
        'late': 0,
        'loan': 5000,
        'tax': 2500,
        'other': 0,
      },
      'attendance': {
        'present': 21,
        'late': 1,
        'absent': 0,
        'leave': 1,
        'holiday': 4,
        'weeklyOff': 4,
      },
      'status': 'PAID',
      'generatedOn': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'id': 'PAY-005',
      'employeeId': 'EMP-005',
      'employeeName': 'Ali Raza',
      'department': 'Finance',
      'designation': 'Accountant',
      'basicSalary': 65000,
      'allowances': {
        'house': 16250,
        'transport': 6500,
        'medical': 5000,
      },
      'commission': 0,
      'overtime': 0,
      'earnings': {
        'bonus': 0,
        'other': 0,
      },
      'deductions': {
        'absent': 4500,
        'late': 0,
        'loan': 0,
        'tax': 2200,
        'other': 0,
      },
      'attendance': {
        'present': 18,
        'late': 0,
        'absent': 2,
        'leave': 2,
        'holiday': 4,
        'weeklyOff': 4,
      },
      'status': 'DRAFT',
      'generatedOn': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredPayroll();

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          _buildMonthSelector(),
          _buildTabBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 8),
                  _buildStatusFilter(),
                  const SizedBox(height: 8),
                  Expanded(child: _buildPayrollList(filteredData)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _generatePayroll,
          backgroundColor: kPrimary,
          elevation: 0,
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(BuildContext context) {
    final totalAmount = _payrollData.fold<double>(
      0,
      (sum, p) => sum + _calculateNetSalary(p),
    );

    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payroll',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Total: ${NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0).format(totalAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {});
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _showExportOptions();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.download_outlined,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTH SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMonthSelector() {
    final months = List.generate(12, (index) {
      final date = DateTime(DateTime.now().year, index + 1, 1);
      return DateFormat('MMMM yyyy').format(date);
    });

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final currentIdx = months.indexOf(_selectedMonth);
              if (currentIdx > 0) {
                setState(() {
                  _selectedMonth = months[currentIdx - 1];
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kBgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child:  Icon(Icons.chevron_left, size: 18, color: kSubText),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: kBgLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _selectedMonth,
                  style:  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              final currentIdx = months.indexOf(_selectedMonth);
              if (currentIdx < months.length - 1) {
                setState(() {
                  _selectedMonth = months[currentIdx + 1];
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kBgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child:  Icon(Icons.chevron_right, size: 18, color: kSubText),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _selectedStatus = ['All', 'DRAFT', 'REVIEW'][index] ;
          });
        },
        indicatorColor: kPrimary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: kPrimary,
        unselectedLabelColor: kSubText,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Draft'),
          Tab(text: 'Review'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SUMMARY CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSummaryCards() {
    final total = _payrollData.length;
    final draft = _payrollData.where((p) => p['status'] == 'DRAFT').length;
    final review = _payrollData.where((p) => p['status'] == 'REVIEW').length;
    final paid = _payrollData.where((p) => p['status'] == 'PAID').length;

    return Container(
      padding: const EdgeInsets.all(8),
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
      child: Row(
        children: [
          _summaryCard('Total', '$total', kPrimary),
          _summaryCard('Draft', '$draft', kWarning),
          _summaryCard('Review', '$review', Colors.blue),
          _summaryCard('Paid', '$paid', kSuccess),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
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
                fontSize: 8,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS FILTER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatusFilter() {
    final filters = ['All', 'DRAFT', 'REVIEW', 'APPROVED', 'PAID'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedStatus == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? kPrimary
                        : Colors.grey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : kSubText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAYROLL LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPayrollList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attach_money_rounded,
              size: 64,
              color: kSubText.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No payroll records found',
              style: TextStyle(
                fontSize: 14,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate payroll for $_selectedMonth',
              style: TextStyle(
                fontSize: 12,
                color: kSubText,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final payroll = data[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildPayrollCard(payroll, context),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAYROLL CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPayrollCard(Map<String, dynamic> payroll, BuildContext context) {
    final status = payroll['status'] as String;
    final statusData = _getStatusData(status);
    final netSalary = _calculateNetSalary(payroll);

    return Container(
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
        border: Border.all(
          color: statusData['color'].withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showPayrollDetail(payroll, context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusData['color'].withValues(alpha: 0.2),
                            statusData['color'].withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusData['color'].withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: statusData['color'],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  payroll['employeeName'] as String,
                                  style:  TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: kText,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusData['color']
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: statusData['color']
                                        .withValues(alpha: 0.15),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: statusData['color'],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusData['label'],
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: statusData['color'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${payroll['designation']} • ${payroll['department']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: kSubText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 10),
                // Stats Row
                Row(
                  children: [
                    _statItem(
                      Icons.work_history_rounded,
                      'Work Days',
                      '${payroll['attendance']['present']}/${payroll['attendance']['present'] + payroll['attendance']['absent']}',
                    ),
                    _statItem(
                      Icons.attach_money_rounded,
                      'Basic',
                      NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0)
                          .format(payroll['basicSalary']),
                    ),
                    _statItem(
                      Icons.trending_up_rounded,
                      'Net Salary',
                      NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0)
                          .format(netSalary),
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showPayrollDetail(payroll, context);
                        },
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: kSubText,
                        ),
                        label: Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 11,
                            color: kText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (status == 'DRAFT') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _approvePayroll(payroll);
                          },
                          icon: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Review',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                    if (status == 'REVIEW') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _approvePayroll(payroll);
                          },
                          icon: const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                    if (status == 'APPROVED' || status == 'PAID') ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showPayslip(payroll, context);
                          },
                          icon: Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 14,
                            color: kPrimary,
                          ),
                          label: Text(
                            'Payslip',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: kPrimary.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: highlight ? kPrimary : kSubText),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: highlight ? kPrimary : kText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAYROLL DETAIL DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showPayrollDetail(Map<String, dynamic> payroll, BuildContext context) {
    final netSalary = _calculateNetSalary(payroll);
    final grossSalary = _calculateGrossSalary(payroll);
    final totalDeductions = _calculateTotalDeductions(payroll);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                              color: kPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.attach_money_rounded,
                              size: 26,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  payroll['employeeName'] as String,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${payroll['designation']} • ${payroll['department']}',
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
                              color: _getStatusData(payroll['status'])
                                      ['color']
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusData(payroll['status'])
                                        ['color']
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              payroll['status'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _getStatusData(payroll['status'])
                                    ['color'],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 16),
                      // Attendance Summary
                      Text(
                        'Attendance Summary',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            _attendanceItem('Present',
                                '${payroll['attendance']['present']}'),
                            _attendanceItem('Late',
                                '${payroll['attendance']['late']}'),
                            _attendanceItem('Absent',
                                '${payroll['attendance']['absent']}'),
                            _attendanceItem('Leave',
                                '${payroll['attendance']['leave']}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Earnings
                      Text(
                        'Earnings',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kSuccess.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: kSuccess.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            _earningsRow('Basic Salary',
                                payroll['basicSalary'].toDouble()),
                            _earningsRow('House Allowance',
                                payroll['allowances']['house'].toDouble()),
                            _earningsRow('Transport Allowance',
                                payroll['allowances']['transport'].toDouble()),
                            _earningsRow('Medical Allowance',
                                payroll['allowances']['medical'].toDouble()),
                            if (payroll['commission'] > 0)
                              _earningsRow('Commission',
                                  payroll['commission'].toDouble()),
                            if (payroll['overtime'] > 0)
                              _earningsRow('Overtime',
                                  payroll['overtime'].toDouble()),
                            if (payroll['earnings']['bonus'] > 0)
                              _earningsRow('Bonus',
                                  payroll['earnings']['bonus'].toDouble()),
                            Divider(
                              height: 1,
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                            _earningsRow(
                              'Gross Salary',
                              grossSalary,
                              bold: true,
                              color: kSuccess,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Deductions
                      Text(
                        'Deductions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kDanger.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: kDanger.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (payroll['deductions']['absent'] > 0)
                              _earningsRow('Absent Deduction',
                                  payroll['deductions']['absent'].toDouble(),
                                  color: kDanger),
                            if (payroll['deductions']['late'] > 0)
                              _earningsRow('Late Deduction',
                                  payroll['deductions']['late'].toDouble(),
                                  color: kDanger),
                            if (payroll['deductions']['loan'] > 0)
                              _earningsRow('Loan Deduction',
                                  payroll['deductions']['loan'].toDouble(),
                                  color: kDanger),
                            if (payroll['deductions']['tax'] > 0)
                              _earningsRow('Tax Deduction',
                                  payroll['deductions']['tax'].toDouble(),
                                  color: kDanger),
                            Divider(
                              height: 1,
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                            _earningsRow(
                              'Total Deductions',
                              totalDeductions,
                              bold: true,
                              color: kDanger,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Net Salary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimary.withValues(alpha: 0.08),
                              kPrimary.withValues(alpha: 0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kPrimary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              'Net Salary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kText,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                      symbol: 'PKR ', decimalDigits: 0)
                                  .format(netSalary),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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

  Widget _attendanceItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _earningsRow(String label, double amount,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? kText : kSubText,
            ),
          ),
          Text(
            NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0)
                .format(amount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (bold ? kText : kSubText),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PAYSLIP PREVIEW
  // ═══════════════════════════════════════════════════════════════

  void _showPayslip(Map<String, dynamic> payroll, BuildContext context) {
    final netSalary = _calculateNetSalary(payroll);
    final grossSalary = _calculateGrossSalary(payroll);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            maxWidth: 400,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            'Payslip',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_selectedMonth • ${payroll['employeeName']}',
                            style: TextStyle(fontSize: 12, color: kSubText),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kPrimary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'BisonsTechs Pvt Ltd',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: kPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Payroll for $_selectedMonth',
                              style: TextStyle(
                                fontSize: 12,
                                color: kSubText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusData(payroll['status'])
                                        ['color']
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Status: ${payroll['status']}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusData(payroll['status'])
                                      ['color'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Employee Info
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _payslipRow('Employee',
                                    payroll['employeeName']),
                                _payslipRow('Employee ID', payroll['id']),
                                _payslipRow('Department',
                                    payroll['department']),
                                _payslipRow('Designation',
                                    payroll['designation']),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _payslipRow('Month', _selectedMonth),
                                _payslipRow('Generated',
                                    DateFormat('dd MMM yyyy').format(DateTime.now())),
                                _payslipRow('Status', payroll['status'],
                                    color: _getStatusData(payroll['status'])
                                        ['color']),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 16),
                      // Earnings
                      Text(
                        'Earnings',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kSuccess.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: kSuccess.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            _payslipEarningRow('Basic Salary',
                                payroll['basicSalary'].toDouble()),
                            _payslipEarningRow('House Allowance',
                                payroll['allowances']['house'].toDouble()),
                            _payslipEarningRow('Transport Allowance',
                                payroll['allowances']['transport'].toDouble()),
                            _payslipEarningRow('Medical Allowance',
                                payroll['allowances']['medical'].toDouble()),
                            if (payroll['commission'] > 0)
                              _payslipEarningRow('Commission',
                                  payroll['commission'].toDouble()),
                            if (payroll['overtime'] > 0)
                              _payslipEarningRow('Overtime',
                                  payroll['overtime'].toDouble()),
                            if (payroll['earnings']['bonus'] > 0)
                              _payslipEarningRow('Bonus',
                                  payroll['earnings']['bonus'].toDouble()),
                            Divider(
                              height: 1,
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                            _payslipEarningRow(
                              'Gross Salary',
                              grossSalary,
                              bold: true,
                              color: kSuccess,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Deductions
                      Text(
                        'Deductions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kDanger.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: kDanger.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (payroll['deductions']['absent'] > 0)
                              _payslipEarningRow('Absent Deduction',
                                  payroll['deductions']['absent'].toDouble(),
                                  color: kDanger),
                            if (payroll['deductions']['late'] > 0)
                              _payslipEarningRow('Late Deduction',
                                  payroll['deductions']['late'].toDouble(),
                                  color: kDanger),
                            if (payroll['deductions']['loan'] > 0)
                              _payslipEarningRow('Loan Deduction',
                                  payroll['deductions']['loan'].toDouble(),
                                  color: kDanger),
                            if (payroll['deductions']['tax'] > 0)
                              _payslipEarningRow('Tax Deduction',
                                  payroll['deductions']['tax'].toDouble(),
                                  color: kDanger),
                            Divider(
                              height: 1,
                              color: Colors.grey.withValues(alpha: 0.1),
                            ),
                            _payslipEarningRow(
                              'Total Deductions',
                              _calculateTotalDeductions(payroll),
                              bold: true,
                              color: kDanger,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Net Salary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kPrimary.withValues(alpha: 0.08),
                              kPrimary.withValues(alpha: 0.02),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kPrimary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              'Net Salary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kText,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                      symbol: 'PKR ', decimalDigits: 0)
                                  .format(netSalary),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'This is a computer generated payslip',
                          style: TextStyle(
                            fontSize: 9,
                            color: kSubText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payslip downloaded as PDF!'),
                              backgroundColor: kSuccess,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _payslipRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color ?? kText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _payslipEarningRow(String label, double amount,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? kText : kSubText,
            ),
          ),
          Text(
            NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0)
                .format(amount),
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: color ?? (bold ? kText : kSubText),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _getFilteredPayroll() {
    var filtered = _payrollData;

    if (_selectedStatus != 'All') {
      filtered = filtered
          .where((p) => p['status'] == _selectedStatus)
          .toList();
    }

    return filtered;
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'DRAFT':
        return {
          'label': 'DRAFT',
          'color': kWarning,
        };
      case 'REVIEW':
        return {
          'label': 'REVIEW',
          'color': Colors.blue,
        };
      case 'APPROVED':
        return {
          'label': 'APPROVED',
          'color': kSuccess,
        };
      case 'PAID':
        return {
          'label': 'PAID',
          'color': Colors.green,
        };
      default:
        return {
          'label': 'UNKNOWN',
          'color': Colors.grey,
        };
    }
  }

  double _calculateNetSalary(Map<String, dynamic> payroll) {
    return _calculateGrossSalary(payroll) - _calculateTotalDeductions(payroll);
  }

  double _calculateGrossSalary(Map<String, dynamic> payroll) {
    double total = payroll['basicSalary'].toDouble();
    total += payroll['allowances']['house'].toDouble();
    total += payroll['allowances']['transport'].toDouble();
    total += payroll['allowances']['medical'].toDouble();
    total += payroll['commission'].toDouble();
    total += payroll['overtime'].toDouble();
    total += payroll['earnings']['bonus'].toDouble();
    total += payroll['earnings']['other'].toDouble();
    return total;
  }

  double _calculateTotalDeductions(Map<String, dynamic> payroll) {
    double total = 0;
    total += payroll['deductions']['absent'].toDouble();
    total += payroll['deductions']['late'].toDouble();
    total += payroll['deductions']['loan'].toDouble();
    total += payroll['deductions']['tax'].toDouble();
    total += payroll['deductions']['other'].toDouble();
    return total;
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void _generatePayroll() {
    setState(() {
      isGenerating = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
          content: Text('✅ Payroll generated successfully!'),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  void _approvePayroll(Map<String, dynamic> payroll) {
    setState(() {
      final currentStatus = payroll['status'];
      if (currentStatus == 'DRAFT') {
        payroll['status'] = 'REVIEW';
      } else if (currentStatus == 'REVIEW') {
        payroll['status'] = 'APPROVED';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          payroll['status'] == 'REVIEW'
              ? '✅ Payroll sent for review!'
              : '✅ Payroll approved!',
        ),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
             Text(
              'Export Payroll',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 16),
            _exportOption(
              Icons.picture_as_pdf_rounded,
              'Export as PDF',
              'Download payroll report as PDF',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📄 Payroll exported as PDF!'),
                    backgroundColor: kSuccess,
                  ),
                );
              },
            ),
            _exportOption(
              Icons.table_chart_rounded,
              'Export as Excel',
              'Download payroll report as Excel',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📊 Payroll exported as Excel!'),
                    backgroundColor: kSuccess,
                  ),
                );
              },
            ),
            _exportOption(
              Icons.print_rounded,
              'Print Payroll',
              'Print payroll report',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🖨️ Print request sent!'),
                    backgroundColor: kSuccess,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(IconData icon, String title, String subtitle,
      VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: kSubText,
        ),
      ),
      onTap: onTap,
    );
  }
}