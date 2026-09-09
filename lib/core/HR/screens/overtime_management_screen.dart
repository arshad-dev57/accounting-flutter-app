// screens/overtime_management_screen.dart - ADVANCED OVERTIME MANAGEMENT

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OvertimeManagementScreen extends StatefulWidget {
  const OvertimeManagementScreen({super.key});

  @override
  State<OvertimeManagementScreen> createState() =>
      _OvertimeManagementScreenState();
}

class _OvertimeManagementScreenState extends State<OvertimeManagementScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  String selectedView = 'Requests'; // Requests | History | Settings
  late TabController _tabController;

  // Advanced Overtime Data
  final List<Map<String, dynamic>> _overtimeRequests = [
    {
      'id': 'OT-001',
      'employeeId': 'EMP-001',
      'employeeName': 'Ahmed Khan',
      'department': 'Sales',
      'designation': 'Sales Manager',
      'date': DateTime(2026, 9, 15),
      'startTime': '06:00 PM',
      'endTime': '08:00 PM',
      'hours': 2.0,
      'rate': 1.5,
      'amount': 4500,
      'reason': 'Client meeting preparation',
      'status': 'Pending',
      'requestedOn': DateTime(2026, 9, 14),
      'approvedBy': null,
      'approvedOn': null,
    },
    {
      'id': 'OT-002',
      'employeeId': 'EMP-002',
      'employeeName': 'Sara Ali',
      'department': 'IT',
      'designation': 'Software Engineer',
      'date': DateTime(2026, 9, 16),
      'startTime': '06:00 PM',
      'endTime': '09:00 PM',
      'hours': 3.0,
      'rate': 1.5,
      'amount': 4500,
      'reason': 'Project deadline',
      'status': 'Approved',
      'requestedOn': DateTime(2026, 9, 15),
      'approvedBy': 'HR Manager',
      'approvedOn': DateTime(2026, 9, 16),
    },
    {
      'id': 'OT-003',
      'employeeId': 'EMP-003',
      'employeeName': 'Usman Raza',
      'department': 'Sales',
      'designation': 'Field Salesman',
      'date': DateTime(2026, 9, 18),
      'startTime': '07:00 PM',
      'endTime': '10:00 PM',
      'hours': 3.0,
      'rate': 2.0,
      'amount': 6000,
      'reason': 'Client meeting',
      'status': 'Rejected',
      'requestedOn': DateTime(2026, 9, 17),
      'approvedBy': 'HR Manager',
      'approvedOn': DateTime(2026, 9, 18),
      'rejectionReason': 'Exceeds weekly limit',
    },
    {
      'id': 'OT-004',
      'employeeId': 'EMP-004',
      'employeeName': 'Fatima Noor',
      'department': 'HR',
      'designation': 'HR Executive',
      'date': DateTime(2026, 9, 20),
      'startTime': '06:30 PM',
      'endTime': '08:30 PM',
      'hours': 2.0,
      'rate': 1.5,
      'amount': 3000,
      'reason': 'Employee onboarding',
      'status': 'Pending',
      'requestedOn': DateTime(2026, 9, 19),
      'approvedBy': null,
      'approvedOn': null,
    },
    {
      'id': 'OT-005',
      'employeeId': 'EMP-005',
      'employeeName': 'Ali Raza',
      'department': 'Finance',
      'designation': 'Accountant',
      'date': DateTime(2026, 9, 22),
      'startTime': '06:00 PM',
      'endTime': '09:00 PM',
      'hours': 3.0,
      'rate': 1.5,
      'amount': 4500,
      'reason': 'Month-end closing',
      'status': 'Approved',
      'requestedOn': DateTime(2026, 9, 20),
      'approvedBy': 'Finance Manager',
      'approvedOn': DateTime(2026, 9, 21),
    },
  ];

  // Overtime Settings
  Map<String, dynamic> overtimeSettings = {
    'autoApproval': false,
    'maxDailyHours': 4.0,
    'maxWeeklyHours': 12.0,
    'defaultRate': 1.5,
    'weekendRate': 2.0,
    'holidayRate': 2.5,
    'minHoursForOvertime': 1.0,
    'requireApproval': true,  
    'autoCalculate': true,
  };

  // Monthly Overtime Summary
  final Map<String, dynamic> _monthlySummary = {
    'totalHours': 32.5,
    'totalAmount': 48750,
    'employeesWithOT': 8,
    'totalRequests': 12,
    'approved': 9,
    'pending': 2,
    'rejected': 1,
  };

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
    final filteredData = _getFilteredOvertime();

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          _buildTabBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _buildRequestsView(filteredData),
                  _buildHistoryView(),
                  _buildSettingsView(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? Container(
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
                onPressed: () => _showRequestOvertimeDialog(context),
                backgroundColor: kPrimary,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            )
          : null,
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
                      'Overtime Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_monthlySummary['totalHours']}h • ${_monthlySummary['pending']} pending',
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
                onTap: () => _showExportOptions(),
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
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
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
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pending_actions_rounded, size: 16),
                const SizedBox(width: 4),
                const Text('Requests'),
                if (_monthlySummary['pending'] > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: kDanger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_monthlySummary['pending']}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 16),
                SizedBox(width: 4),
                Text('History'),
              ],
            ),
          ),
          const Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_rounded, size: 16),
                SizedBox(width: 4),
                Text('Settings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REQUESTS VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRequestsView(List<Map<String, dynamic>> data) {
    return Column(
      children: [
        _buildFilterAndSummary(),
        const SizedBox(height: 8),
        Expanded(
          child: data.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildOvertimeCard(item, context),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterAndSummary() {
    final filters = ['All', 'Pending', 'Approved', 'Rejected'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Summary Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _summaryChip(
                  'Total Hours',
                  '${_monthlySummary['totalHours']}h',
                  kPrimary,
                ),
                _summaryChip(
                  'Total Amount',
                  'PKR ${_monthlySummary['totalAmount']}',
                  kSuccess,
                ),
                _summaryChip(
                  'Employees',
                  '${_monthlySummary['employeesWithOT']}',
                  Colors.blue,
                ),
                _summaryChip(
                  'Pending',
                  '${_monthlySummary['pending']}',
                  kWarning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : _getStatusColor(filter),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            filter,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : kSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 7,
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
  // OVERTIME CARD - Advanced
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOvertimeCard(Map<String, dynamic> item, BuildContext context) {
    final status = item['status'] as String;
    final statusData = _getStatusData(status);
    final isPending = status == 'Pending';

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
          color: isPending
              ? kWarning.withValues(alpha: 0.2)
              : statusData['color'].withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showOvertimeDetail(item, context);
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
                        Icons.access_time_rounded,
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
                                  item['employeeName'] as String,
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
                            '${item['designation']} • ${item['department']}',
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
                // Details Row
                Row(
                  children: [
                    _detailChip(
                      Icons.calendar_today_rounded,
                      DateFormat('dd MMM yyyy').format(item['date']),
                    ),
                    const SizedBox(width: 6),
                    _detailChip(
                      Icons.timer_rounded,
                      '${item['startTime']} - ${item['endTime']}',
                    ),
                    const SizedBox(width: 6),
                    _detailChip(
                      Icons.hourglass_bottom_rounded,
                      '${item['hours']}h',
                      color: kPrimary,
                    ),
                    const Spacer(),
                    if (item['rate'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kSuccess.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: kSuccess.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          '${item['rate']}x',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: kSuccess,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Reason
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['reason'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: kSubText,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'PKR ${item['amount']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
                // Action Buttons (for pending)
                if (isPending) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showOvertimeDetail(item, context);
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _handleApproveOvertime(item);
                          },
                          icon: const Icon(
                            Icons.check_rounded,
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
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showRejectDialog(item);
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: kDanger,
                          ),
                          label: Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kDanger,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: kDanger.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                // Approved/Rejected Info
                if (!isPending) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusData['color'].withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: statusData['color'].withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          status == 'Approved'
                              ? Icons.verified_rounded
                              : Icons.cancel_rounded,
                          size: 12,
                          color: statusData['color'],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status == 'Approved'
                              ? 'Approved by ${item['approvedBy']} on ${DateFormat('dd MMM').format(item['approvedOn'])}'
                              : 'Rejected - ${item['rejectionReason'] ?? 'No reason provided'}',
                          style: TextStyle(
                            fontSize: 9,
                            color: statusData['color'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color ?? kSubText),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: color ?? kSubText,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HISTORY VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHistoryView() {
    final historyData = _overtimeRequests
        .where((item) => item['status'] != 'Pending')
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search history...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    icon: const Icon(Icons.arrow_drop_down, size: 20),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                    items: List.generate(12, (index) {
                      final date = DateTime(DateTime.now().year, index + 1, 1);
                      return DropdownMenuItem(
                        value: DateFormat('MMMM yyyy').format(date),
                        child: Text(DateFormat('MMM yyyy').format(date)),
                      );
                    }),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedMonth = v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: historyData.isEmpty
              ? _buildEmptyState('No history found')
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: historyData.length,
                  itemBuilder: (context, index) {
                    final item = historyData[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getStatusData(item['status'])['color']
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item['status'] == 'Approved'
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 16,
                                color: _getStatusData(item['status'])['color'],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['employeeName'],
                                    style:  TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: kText,
                                    ),
                                  ),
                                  Text(
                                    '${DateFormat('dd MMM').format(item['date'])} • ${item['hours']}h • PKR ${item['amount']}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: kSubText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusData(item['status'])['color']
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _getStatusData(item['status'])['color']
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Text(
                                item['status'],
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: _getStatusData(item['status'])['color'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SETTINGS VIEW - Advanced
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSettingsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Overtime Rules Card
          _settingsCard(
            icon: Icons.gavel_rounded,
            title: 'Overtime Rules',
            children: [
              _settingsSwitch(
                'Auto Approval',
                overtimeSettings['autoApproval'],
                'Automatically approve overtime requests',
                (value) {
                  setState(() {
                    overtimeSettings['autoApproval'] = value;
                  });
                },
              ),
              _settingsSwitch(
                'Require Approval',
                overtimeSettings['requireApproval'],
                'Require manager approval for overtime',
                (value) {
                  setState(() {
                    overtimeSettings['requireApproval'] = value;
                  });
                },
              ),
              _settingsSwitch(
                'Auto Calculate',
                overtimeSettings['autoCalculate'],
                'Automatically calculate overtime from attendance',
                (value) {
                  setState(() {
                    overtimeSettings['autoCalculate'] = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rate Configuration
          _settingsCard(
            icon: Icons.percent_rounded,
            title: 'Overtime Rates',
            children: [
              _settingsSlider(
                'Default Rate',
                overtimeSettings['defaultRate'],
                1.0,
                3.0,
                '${overtimeSettings['defaultRate']}x',
                (value) {
                  setState(() {
                    overtimeSettings['defaultRate'] = value;
                  });
                },
              ),
              _settingsSlider(
                'Weekend Rate',
                overtimeSettings['weekendRate'],
                1.0,
                3.0,
                '${overtimeSettings['weekendRate']}x',
                (value) {
                  setState(() {
                    overtimeSettings['weekendRate'] = value;
                  });
                },
              ),
              _settingsSlider(
                'Holiday Rate',
                overtimeSettings['holidayRate'],
                1.0,
                3.0,
                '${overtimeSettings['holidayRate']}x',
                (value) {
                  setState(() {
                    overtimeSettings['holidayRate'] = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Limits Card
          _settingsCard(
            icon: Icons.linear_scale_rounded,
            title: 'Overtime Limits',
            children: [
              _settingsSlider(
                'Maximum Daily Hours',
                overtimeSettings['maxDailyHours'],
                1.0,
                8.0,
                '${overtimeSettings['maxDailyHours']}h',
                (value) {
                  setState(() {
                    overtimeSettings['maxDailyHours'] = value;
                  });
                },
              ),
              _settingsSlider(
                'Maximum Weekly Hours',
                overtimeSettings['maxWeeklyHours'],
                1.0,
                24.0,
                '${overtimeSettings['maxWeeklyHours']}h',
                (value) {
                  setState(() {
                    overtimeSettings['maxWeeklyHours'] = value;
                  });
                },
              ),
              _settingsSlider(
                'Minimum Hours for OT',
                overtimeSettings['minHoursForOvertime'],
                0.5,
                4.0,
                '${overtimeSettings['minHoursForOvertime']}h',
                (value) {
                  setState(() {
                    overtimeSettings['minHoursForOvertime'] = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Overtime settings saved!'),
                    backgroundColor: kSuccess,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: kPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style:  TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _settingsSwitch(
    String label,
    bool value,
    String subtitle,
    void Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:  TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: kSubText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: kPrimary,
            activeTrackColor: kPrimary.withValues(alpha: 0.3),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _settingsSlider(
    String label,
    double value,
    double min,
    double max,
    String display,
    void Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style:  TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min) * 4 ~/ 1,
            onChanged: onChanged,
            activeColor: kPrimary,
            inactiveColor: kPrimary.withValues(alpha: 0.15),
            label: display,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REQUEST OVERTIME DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showRequestOvertimeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController();
    final startTimeController = TextEditingController(text: '06:00 PM');
    final endTimeController = TextEditingController(text: '08:00 PM');
    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    double rate = 1.5;
    bool isWeekend = false;
    bool isHoliday = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
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
                            Icons.access_time_rounded,
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
                                'Request Overtime',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Submit an overtime request',
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
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDatePickerField(
                              label: 'Date *',
                              date: selectedDate,
                              controller: dateController,
                              onChanged: (date) {
                                setState(() {
                                  selectedDate = date;
                                  dateController.text =
                                      DateFormat('dd MMM yyyy').format(date);
                                  // Check if weekend
                                  isWeekend = date.weekday == 6 ||
                                      date.weekday == 7;
                                });
                              },
                              context: context,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimePickerField(
                                    label: 'Start Time *',
                                    controller: startTimeController,
                                    hint: '06:00 PM',
                                    icon: Icons.play_arrow_rounded,
                                    onChanged: (time) {
                                      setState(() {
                                        startTimeController.text = time;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTimePickerField(
                                    label: 'End Time *',
                                    controller: endTimeController,
                                    hint: '08:00 PM',
                                    icon: Icons.stop_rounded,
                                    onChanged: (time) {
                                      setState(() {
                                        endTimeController.text = time;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Rate *',
                              value: rate.toString(),
                              items: ['1.0', '1.5', '2.0', '2.5', '3.0'],
                              onChanged: (v) {
                                setState(() {
                                  rate = double.parse(v!);
                                });
                              },
                              suffix: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isWeekend
                                      ? 'Weekend'
                                      : isHoliday
                                          ? 'Holiday'
                                          : 'Regular',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: isWeekend
                                        ? Colors.orange
                                        : isHoliday
                                            ? Colors.purple
                                            : kPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: reasonController,
                              label: 'Reason *',
                              hint: 'Enter reason for overtime',
                              icon: Icons.description_outlined,
                              maxLines: 3,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter reason' : null,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: kPrimary.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: kPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Overtime requests require approval from your manager. Approved overtime will be included in payroll.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: kSubText,
                                        height: 1.3,
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
                  ),
                  // Footer Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
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
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Overtime request submitted!'),
                                    backgroundColor: kSuccess,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Submit Request',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OVERTIME DETAIL DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showOvertimeDetail(Map<String, dynamic> item, BuildContext context) {
    final status = item['status'] as String;
    final statusData = _getStatusData(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.75,
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
                              color: statusData['color'].withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              size: 26,
                              color: statusData['color'],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['employeeName'] as String,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item['designation']} • ${item['department']}',
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
                              color: statusData['color'].withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusData['color'].withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              statusData['label'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusData['color'],
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
                      _detailRow('Request ID', item['id']),
                      _detailRow('Date', DateFormat('dd MMM yyyy').format(item['date'])),
                      _detailRow('Time', '${item['startTime']} - ${item['endTime']}'),
                      _detailRow('Hours', '${item['hours']} hours'),
                      _detailRow('Rate', '${item['rate']}x'),
                      _detailRow('Amount', 'PKR ${item['amount']}',
                          valueColor: kPrimary),
                      _detailRow('Status', item['status'],
                          valueColor: statusData['color']),
                      if (item['approvedBy'] != null) ...[
                        _detailRow('Approved By', item['approvedBy']),
                        _detailRow('Approved On',
                            DateFormat('dd MMM yyyy').format(item['approvedOn'])),
                      ],
                      if (item['rejectionReason'] != null) ...[
                        _detailRow('Rejection Reason', item['rejectionReason'],
                            valueColor: kDanger),
                      ],
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kSubText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['reason'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: kText,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
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

  // ═══════════════════════════════════════════════════════════════
  // REJECT DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showRejectDialog(Map<String, dynamic> item) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.cancel_rounded, color: kDanger),
            const SizedBox(width: 8),
            const Text('Reject Overtime'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee: ${item['employeeName']}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${DateFormat('dd MMM yyyy').format(item['date'])}',
              style: TextStyle(fontSize: 12, color: kSubText),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'Enter reason for rejection',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
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
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a rejection reason'),
                    backgroundColor: kDanger,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _handleRejectOvertime(item, reasonController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reject',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: kSubText),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        labelStyle:  TextStyle(fontSize: 12, color: kSubText),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    Widget? suffix,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 18),
        suffix: suffix,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        labelStyle:  TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select rate' : null,
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime date,
    required TextEditingController controller,
    required void Function(DateTime) onChanged,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2027),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
          labelStyle:  TextStyle(fontSize: 12, color: kSubText),
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Please select date' : null,
      ),
    );
  }

  Widget _buildTimePickerField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required void Function(String) onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          final timeString = DateFormat('hh:mm a').format(
            DateTime(2024, 1, 1, picked.hour, picked.minute),
          );
          controller.text = timeString;
          onChanged(timeString);
        }
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
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: kSubText),
          suffixIcon: const Icon(Icons.access_time, size: 18),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
          labelStyle:  TextStyle(fontSize: 12, color: kSubText),
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Please select time' : null,
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kText,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState([String message = 'No overtime requests found']) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 64,
            color: kSubText.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to request overtime',
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

  // ═══════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _getFilteredOvertime() {
    var filtered = _overtimeRequests;

    if (_selectedFilter != 'All') {
      filtered = filtered
          .where((item) => item['status'] == _selectedFilter)
          .toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b['date'].compareTo(a['date']));

    return filtered;
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'Pending':
        return {
          'label': 'PENDING',
          'color': kWarning,
        };
      case 'Approved':
        return {
          'label': 'APPROVED',
          'color': kSuccess,
        };
      case 'Rejected':
        return {
          'label': 'REJECTED',
          'color': kDanger,
        };
      default:
        return {
          'label': 'UNKNOWN',
          'color': Colors.grey,
        };
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return kWarning;
      case 'Approved':
        return kSuccess;
      case 'Rejected':
        return kDanger;
      default:
        return kSubText;
    }
  }

  void _handleApproveOvertime(Map<String, dynamic> item) {
    setState(() {
      item['status'] = 'Approved';
      item['approvedBy'] = 'HR Manager';
      item['approvedOn'] = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text('✅ Overtime approved!'),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _handleRejectOvertime(Map<String, dynamic> item, String reason) {
    setState(() {
      item['status'] = 'Rejected';
      item['rejectionReason'] = reason;
      item['approvedBy'] = 'HR Manager';
      item['approvedOn'] = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
        content: Text('❌ Overtime rejected!'),
        backgroundColor: kDanger,
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
              'Export Overtime Data',
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
              'Download overtime report as PDF',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📄 Overtime exported as PDF!'),
                    backgroundColor: kSuccess,
                  ),
                );
              },
            ),
            _exportOption(
              Icons.table_chart_rounded,
              'Export as Excel',
              'Download overtime report as Excel',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📊 Overtime exported as Excel!'),
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