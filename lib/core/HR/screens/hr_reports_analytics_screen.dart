// screens/hr_reports_analytics_screen.dart - HR REPORTS & ANALYTICS

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HRReportsAnalyticsScreen extends StatefulWidget {
  const HRReportsAnalyticsScreen({super.key});

  @override
  State<HRReportsAnalyticsScreen> createState() =>
      _HRReportsAnalyticsScreenState();
}

class _HRReportsAnalyticsScreenState extends State<HRReportsAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = 'This Month';
  String _selectedChartType = 'Attendance';
  late TabController _tabController;
  String _selectedDepartment = 'All';

  // Analytics Data
  final Map<String, dynamic> _analyticsData = {
    'totalEmployees': 125,
    'newHires': 8,
    'terminations': 2,
    'turnoverRate': 1.6,
    'avgAttendance': 92.5,
    'avgLate': 8.4,
    'avgAbsent': 4.2,
    'totalLeaves': 156,
    'avgOvertime': 2.8,
    'totalPayroll': 4850000,
    'avgSalary': 38800,
  };

  // Monthly Attendance Data
  final List<Map<String, dynamic>> _attendanceData = [
    {'month': 'Jan', 'present': 85, 'absent': 5, 'late': 10},
    {'month': 'Feb', 'present': 88, 'absent': 4, 'late': 8},
    {'month': 'Mar', 'present': 82, 'absent': 8, 'late': 10},
    {'month': 'Apr', 'present': 90, 'absent': 3, 'late': 7},
    {'month': 'May', 'present': 87, 'absent': 6, 'late': 7},
    {'month': 'Jun', 'present': 92, 'absent': 3, 'late': 5},
    {'month': 'Jul', 'present': 94, 'absent': 2, 'late': 4},
    {'month': 'Aug', 'present': 91, 'absent': 4, 'late': 5},
    {'month': 'Sep', 'present': 95, 'absent': 2, 'late': 3},
    {'month': 'Oct', 'present': 89, 'absent': 5, 'late': 6},
    {'month': 'Nov', 'present': 93, 'absent': 3, 'late': 4},
    {'month': 'Dec', 'present': 90, 'absent': 4, 'late': 6},
  ];

  // Department-wise Data
  final List<Map<String, dynamic>> _departmentData = [
    {'name': 'Sales', 'employees': 45, 'attendance': 94, 'leaves': 28},
    {'name': 'IT', 'employees': 32, 'attendance': 96, 'leaves': 18},
    {'name': 'HR', 'employees': 18, 'attendance': 92, 'leaves': 12},
    {'name': 'Finance', 'employees': 15, 'attendance': 90, 'leaves': 10},
    {'name': 'Marketing', 'employees': 10, 'attendance': 88, 'leaves': 8},
    {'name': 'Operations', 'employees': 5, 'attendance': 85, 'leaves': 4},
  ];

  // Leave Utilization Data
  final List<Map<String, dynamic>> _leaveData = [
    {'type': 'Casual', 'used': 45, 'total': 120, 'color': Colors.blue},
    {'type': 'Sick', 'used': 28, 'total': 80, 'color': Colors.orange},
    {'type': 'Annual', 'used': 56, 'total': 100, 'color': Colors.green},
    {'type': 'Emergency', 'used': 12, 'total': 30, 'color': Colors.purple},
    {'type': 'Unpaid', 'used': 15, 'total': 40, 'color': Colors.red},
  ];

  // Overtime Data
  final List<Map<String, dynamic>> _overtimeData = [
    {'month': 'Jan', 'hours': 120, 'employees': 15},
    {'month': 'Feb', 'hours': 135, 'employees': 18},
    {'month': 'Mar', 'hours': 110, 'employees': 14},
    {'month': 'Apr', 'hours': 155, 'employees': 20},
    {'month': 'May', 'hours': 145, 'employees': 19},
    {'month': 'Jun', 'hours': 130, 'employees': 16},
    {'month': 'Jul', 'hours': 165, 'employees': 22},
    {'month': 'Aug', 'hours': 140, 'employees': 17},
    {'month': 'Sep', 'hours': 160, 'employees': 21},
  ];

  // Recent Activities
  final List<Map<String, dynamic>> _recentActivities = [
    {
      'type': 'employee',
      'title': 'New Employee Added',
      'description': 'Ali Ahmed joined as Software Engineer',
      'time': '2 hours ago',
      'icon': Icons.person_add_rounded,
      'color': kSuccess,
    },
    {
      'type': 'leave',
      'title': 'Leave Approved',
      'description': 'Sara Ali\'s annual leave approved',
      'time': '3 hours ago',
      'icon': Icons.beach_access_rounded,
      'color': Colors.blue,
    },
    {
      'type': 'attendance',
      'title': 'Attendance Submitted',
      'description': 'Monthly attendance for Sep 2026 submitted',
      'time': '5 hours ago',
      'icon': Icons.fingerprint_rounded,
      'color': kPrimary,
    },
    {
      'type': 'payroll',
      'title': 'Payroll Generated',
      'description': 'Payroll for September 2026 generated',
      'time': '1 day ago',
      'icon': Icons.attach_money_rounded,
      'color': kSuccess,
    },
    {
      'type': 'leave',
      'title': 'Leave Request Pending',
      'description': 'Usman Raza requested emergency leave',
      'time': '2 days ago',
      'icon': Icons.warning_rounded,
      'color': kWarning,
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
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          _buildPeriodSelector(),
          _buildTabBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _buildOverviewView(),
                  _buildChartsView(),
                  _buildReportsView(),
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
          onPressed: () => _showExportOptions(context),
          backgroundColor: kPrimary,
          elevation: 0,
          child: const Icon(Icons.download_rounded, color: Colors.white, size: 24),
        ),
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
                      'HR Analytics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_analyticsData['totalEmployees']} employees • ${_selectedPeriod}',
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
                onTap: () => _showFilterOptions(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
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
  // PERIOD SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'This Week', 'This Month', 'This Quarter', 'This Year', 'Custom'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periods.map((period) {
            final isSelected = _selectedPeriod == period;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPeriod = period;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? kPrimary
                          : Colors.grey.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: kPrimary.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      if (isSelected) const SizedBox(width: 4),
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: 11,
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
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dashboard_rounded, size: 16),
                SizedBox(width: 4),
                Text('Overview'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.show_chart_rounded, size: 16),
                SizedBox(width: 4),
                Text('Charts'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_rounded, size: 16),
                SizedBox(width: 4),
                Text('Reports'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OVERVIEW VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOverviewView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // KPI Cards
          _buildKPICards(),
          const SizedBox(height: 12),
          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: 12),
          // Department Summary
          _buildDepartmentSummary(),
          const SizedBox(height: 12),
          // Recent Activity
          _buildRecentActivity(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // KPI CARDS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildKPICards() {
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
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        padding: EdgeInsets.zero,
        children: [
          _kpiCard(
            'Employees',
            '${_analyticsData['totalEmployees']}',
            '${_analyticsData['newHires']} new',
            Icons.people_rounded,
            kPrimary,
            Colors.blue.shade50,
          ),
          _kpiCard(
            'Attendance',
            '${_analyticsData['avgAttendance']}%',
            '${_analyticsData['avgLate']}% late',
            Icons.fingerprint_rounded,
            kSuccess,
            Colors.green.shade50,
          ),
          _kpiCard(
            'Absenteeism',
            '${_analyticsData['avgAbsent']}%',
            '${_analyticsData['totalLeaves']} leaves',
            Icons.person_off_rounded,
            kDanger,
            Colors.red.shade50,
          ),
          _kpiCard(
            'Payroll',
            'PKR ${(_analyticsData['totalPayroll'] / 1000000).toStringAsFixed(1)}M',
            'Avg PKR ${_analyticsData['avgSalary']}',
            Icons.attach_money_rounded,
            Colors.purple,
            Colors.purple.shade50,
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, String subtitle, IconData icon,
      Color color, Color bgColor) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: kSubText,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 6,
              fontWeight: FontWeight.w400,
              color: kSubText,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK STATS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildQuickStats() {
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
           Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickStatItem(
                'Turnover',
                '${_analyticsData['turnoverRate']}%',
                '${_analyticsData['terminations']} terminations',
                Icons.trending_down_rounded,
                kWarning,
              ),
              _quickStatItem(
                'Overtime',
                '${_analyticsData['avgOvertime']}h',
                'Per employee',
                Icons.access_time_rounded,
                Colors.blue,
              ),
              _quickStatItem(
                'Leaves',
                '${_analyticsData['totalLeaves']}',
                'This month',
                Icons.beach_access_rounded,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickStatItem(String label, String value, String subtitle,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
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
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 7,
                color: kSubText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DEPARTMENT SUMMARY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDepartmentSummary() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Department Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              Text(
                '${_departmentData.length} depts',
                style: TextStyle(
                  fontSize: 11,
                  color: kSubText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._departmentData.map((dept) {
            final progress = (dept['attendance'] as int) / 100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        dept['name'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${dept['employees']} emp',
                        style: TextStyle(
                          fontSize: 9,
                          color: kSubText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${dept['attendance']}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: dept['attendance'] >= 90 ? kSuccess : kWarning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        dept['attendance'] >= 90 ? kSuccess : kWarning,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RECENT ACTIVITY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRecentActivity() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // View all
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._recentActivities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kBgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: activity['color'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activity['icon'],
                        size: 16,
                        color: activity['color'],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kText,
                            ),
                          ),
                          Text(
                            activity['description'],
                            style: TextStyle(
                              fontSize: 10,
                              color: kSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      activity['time'],
                      style: TextStyle(
                        fontSize: 9,
                        color: kSubText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CHARTS VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildChartsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildChartSelector(),
          const SizedBox(height: 12),
          if (_selectedChartType == 'Attendance')
            _buildAttendanceChart(),
          if (_selectedChartType == 'Leaves')
            _buildLeaveChart(),
          if (_selectedChartType == 'Overtime')
            _buildOvertimeChart(),
          if (_selectedChartType == 'Department')
            _buildDepartmentChart(),
          const SizedBox(height: 12),
          _buildInsightsCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChartSelector() {
    final chartTypes = ['Attendance', 'Leaves', 'Overtime', 'Department'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chartTypes.map((type) {
            final isSelected = _selectedChartType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedChartType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? kPrimary
                          : Colors.grey.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: kPrimary.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getChartIcon(type),
                        size: 14,
                        color: isSelected ? Colors.white : kSubText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
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
    );
  }

  IconData _getChartIcon(String type) {
    switch (type) {
      case 'Attendance':
        return Icons.fingerprint_rounded;
      case 'Leaves':
        return Icons.beach_access_rounded;
      case 'Overtime':
        return Icons.access_time_rounded;
      case 'Department':
        return Icons.business_center_rounded;
      default:
        return Icons.show_chart_rounded;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ATTENDANCE CHART
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAttendanceChart() {
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
           Text(
            'Attendance Trend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monthly attendance breakdown for ${_selectedPeriod}',
            style: TextStyle(
              fontSize: 10,
              color: kSubText,
            ),
          ),
          const SizedBox(height: 16),
          // Bar Chart
          SizedBox(
            height: 150,
            child: Row(
              children: _attendanceData.map((data) {
                final present = (data['present'] as int) / 100;
                final late = (data['late'] as int) / 100;
                final absent = (data['absent'] as int) / 100;
                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Present
                            Container(
                              width: 12,
                              height: present * 120,
                              decoration: BoxDecoration(
                                color: kSuccess,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(2),
                                ),
                              ),
                            ),
                            // Late
                            Container(
                              width: 12,
                              height: late * 120,
                              decoration: BoxDecoration(
                                color: kWarning,
                              ),
                            ),
                            // Absent
                            Container(
                              width: 12,
                              height: absent * 120,
                              decoration: BoxDecoration(
                                color: kDanger,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['month'],
                        style: TextStyle(
                          fontSize: 8,
                          color: kSubText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot('Present', kSuccess),
              const SizedBox(width: 12),
              _legendDot('Late', kWarning),
              const SizedBox(width: 12),
              _legendDot('Absent', kDanger),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE CHART
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLeaveChart() {
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
           Text(
            'Leave Utilization',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Used vs Available leaves by type',
            style: TextStyle(
              fontSize: 10,
              color: kSubText,
            ),
          ),
          const SizedBox(height: 16),
          ..._leaveData.map((data) {
            final used = (data['used'] as int) / (data['total'] as int);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: data['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data['type'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${data['used']}/${data['total']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: used,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(data['color']),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
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
                    'Total leaves used: ${_leaveData.fold(0, (sum, d) => sum + (d['used'] as int))} out of ${_leaveData.fold(0, (sum, d) => sum + (d['total'] as int))}',
                    style: TextStyle(
                      fontSize: 10,
                      color: kSubText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OVERTIME CHART
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOvertimeChart() {
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
           Text(
            'Overtime Analysis',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monthly overtime hours and employees',
            style: TextStyle(
              fontSize: 10,
              color: kSubText,
            ),
          ),
          const SizedBox(height: 16),
          // Overtime Chart
          SizedBox(
            height: 120,
            child: Row(
              children: _overtimeData.map((data) {
                final height = (data['hours'] as int) / 200;
                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 14,
                              height: height * 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    kPrimary,
                                    kPrimary.withValues(alpha: 0.6),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['month'],
                        style: TextStyle(
                          fontSize: 8,
                          color: kSubText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${data['hours']}h',
                        style: TextStyle(
                          fontSize: 7,
                          color: kPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: kPrimary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _overtimeStat(
                  'Total Hours',
                  '${_overtimeData.fold(0, (sum, d) => sum + (d['hours'] as int))}h',
                  kPrimary,
                ),
                _overtimeStat(
                  'Avg Monthly',
                  '${(_overtimeData.fold(0, (sum, d) => sum + (d['hours'] as int)) / _overtimeData.length).toStringAsFixed(1)}h',
                  Colors.blue,
                ),
                _overtimeStat(
                  'Employees',
                  '${_overtimeData.fold(0, (sum, d) => sum + (d['employees'] as int))}',
                  kSuccess,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overtimeStat(String label, String value, Color color) {
    return Column(
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
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DEPARTMENT CHART
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDepartmentChart() {
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
           Text(
            'Department Breakdown',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Employees distribution by department',
            style: TextStyle(
              fontSize: 10,
              color: kSubText,
            ),
          ),
          const SizedBox(height: 16),
          ..._departmentData.map((dept) {
            final percentage = (dept['employees'] as int) /
                _analyticsData['totalEmployees'] *
                100;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getDepartmentColor(dept['name']),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dept['name'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${dept['employees']} emp',
                        style: TextStyle(
                          fontSize: 10,
                          color: kSubText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _getDepartmentColor(dept['name']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getDepartmentColor(dept['name']),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getDepartmentColor(String name) {
    switch (name) {
      case 'Sales':
        return Colors.blue;
      case 'IT':
        return Colors.green;
      case 'HR':
        return Colors.purple;
      case 'Finance':
        return Colors.orange;
      case 'Marketing':
        return Colors.pink;
      case 'Operations':
        return Colors.teal;
      default:
        return kPrimary;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // INSIGHTS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInsightsCard() {
    final insights = [
      {
        'icon': Icons.trending_up_rounded,
        'title': 'Attendance is up 5%',
        'description': 'Compared to last month, attendance has improved significantly',
        'color': kSuccess,
      },
      {
        'icon': Icons.warning_rounded,
        'title': 'High absenteeism in Sales',
        'description': 'Sales department has 10% absenteeism rate',
        'color': kWarning,
      },
      {
        'icon': Icons.celebration_rounded,
        'title': 'Lowest turnover rate',
        'description': 'Current turnover rate is 1.6%, lowest in 2 years',
        'color': kSuccess,
      },
    ];

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
           Text(
            'AI Insights',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) {
            return Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: (insight['color'] as Color).withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (insight['color'] as Color).withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (insight['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      insight['icon'] as IconData,
                      size: 16,
                      color: insight['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                        Text(
                          insight['description'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: kSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REPORTS VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildReportsView() {
    final reports = [
      {
        'title': 'Monthly Attendance Report',
        'description': 'Detailed attendance breakdown by employee',
        'icon': Icons.fingerprint_rounded,
        'color': kPrimary,
        'date': 'Sep 2026',
      },
      {
        'title': 'Leave Summary Report',
        'description': 'Leave utilization by department',
        'icon': Icons.beach_access_rounded,
        'color': Colors.blue,
        'date': 'Sep 2026',
      },
      {
        'title': 'Payroll Summary Report',
        'description': 'Salary breakdown and deductions',
        'icon': Icons.attach_money_rounded,
        'color': kSuccess,
        'date': 'Sep 2026',
      },
      {
        'title': 'Employee Turnover Report',
        'description': 'Hiring and termination trends',
        'icon': Icons.trending_up_rounded,
        'color': kWarning,
        'date': 'Q3 2026',
      },
      {
        'title': 'Overtime Analysis Report',
        'description': 'Overtime hours by department',
        'icon': Icons.access_time_rounded,
        'color': Colors.purple,
        'date': 'Sep 2026',
      },
      {
        'title': 'Headcount Report',
        'description': 'Employee count by department and location',
        'icon': Icons.people_rounded,
        'color': Colors.orange,
        'date': 'Q3 2026',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
        children: reports.map((report) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (report['color'] as Color).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    report['icon'] as IconData,
                    size: 18,
                    color: report['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  report['title'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  report['description'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    color: kSubText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      report['date'] as String,
                      style: TextStyle(
                        fontSize: 8,
                        color: kSubText,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (report['color'] as Color).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'View',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: report['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: kSubText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════

  void _showFilterOptions(BuildContext context) {
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
              'Filter Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 16),
            _filterOption('All Departments', _selectedDepartment == 'All', () {
              setState(() {
                _selectedDepartment = 'All';
              });
              Navigator.pop(context);
            }),
            ..._departmentData.map((dept) {
              return _filterOption(dept['name'], _selectedDepartment == dept['name'], () {
                setState(() {
                  _selectedDepartment = dept['name'];
                });
                Navigator.pop(context);
              });
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _filterOption(String label, bool isSelected, VoidCallback onTap) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? kPrimary : kText,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: kPrimary, size: 20)
          : null,
      onTap: onTap,
    );
  }

  void _showExportOptions(BuildContext context) {
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
              'Export Analytics',
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
              'Download analytics report as PDF',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📄 Analytics exported as PDF!'),
                    backgroundColor: kSuccess,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _exportOption(
              Icons.table_chart_rounded,
              'Export as Excel',
              'Download analytics data as Excel',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📊 Analytics exported as Excel!'),
                    backgroundColor: kSuccess,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _exportOption(
              Icons.insert_chart_rounded,
              'Export Charts',
              'Download charts as images',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📈 Charts exported!'),
                    backgroundColor: kSuccess,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
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