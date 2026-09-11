// screens/hr_dashboard_screen.dart - HR DASHBOARD

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/screens/add_employee_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_profile_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employees_list_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/hr_admin_modules.dart';
import 'package:BisonsTechs_app/core/HR/screens/live_employee_tracking_screen.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:BisonsTechs_app/widgets/hr_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HRDashboardScreen extends StatefulWidget {
  const HRDashboardScreen({super.key});

  @override
  State<HRDashboardScreen> createState() => _HRDashboardScreenState();
}

class _HRDashboardScreenState extends State<HRDashboardScreen> {
  Map<String, dynamic> _stats = {
    'totalEmployees': 0, 'present': 0, 'late': 0,
    'absent': 0, 'onLeave': 0, 'fieldStaff': 0, 'liveCount': 0, 'working': 0,
  };
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _weekly = [];
  int _pendingLeaves = 0;
  int _pendingOt = 0;
  int _pendingLoans = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        HrApiService.instance.dashboard(),
        HrApiService.instance.leaves().catchError((_) => <Map<String, dynamic>>[]),
        HrApiService.instance.overtime().catchError((_) => <Map<String, dynamic>>[]),
        HrApiService.instance.loans().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      final leaves = results[1] as List<Map<String, dynamic>>;
      final ot = results[2] as List<Map<String, dynamic>>;
      final loans = results[3] as List<Map<String, dynamic>>;
      final attendance = data['attendance'];

      List<Map<String, dynamic>> listOf(dynamic v) {
        if (v is! List) return [];
        return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }

      setState(() {
        _stats = data;
        _attendance = attendance is List ? listOf(attendance) : [];
        _weekly = listOf(data['weekly']);
        _pendingLeaves = leaves.where((l) => '${l['status']}'.toLowerCase() == 'pending').length;
        _pendingOt = ot.where((o) => '${o['status']}'.toLowerCase() == 'pending').length;
        _pendingLoans = loans.where((l) => '${l['status']}'.toLowerCase() == 'pending').length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      drawer: const HRDrawer(currentItem: 'dashboard'),
      body: Builder(
        builder: (context) {
          return Column(
            children: [
              _buildTopHeader(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadStats,
                  color: kPrimary,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildDateSelector(),
                          const SizedBox(height: 12),
                          if (_loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator(color: kPrimary)),
                            )
                          else ...[
                            if (_error != null) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kDanger.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(color: kDanger, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    TextButton(onPressed: _loadStats, child: const Text('Retry')),
                                  ],
                                ),
                              ),
                            ],
                            _buildStatsGrid(context),
                            const SizedBox(height: 16),
                            _buildPendingApprovals(context),
                            const SizedBox(height: 16),
                            if (_weekly.isNotEmpty) ...[
                              _buildWeeklyChart(),
                              const SizedBox(height: 16),
                            ],
                            _buildQuickActions(context),
                            const SizedBox(height: 16),
                            _buildLiveTrackingCard(context),
                            const SizedBox(height: 16),
                            _buildRecentActivity(context),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
              // Menu Icon
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HR Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Profile
              GestureDetector(
                onTap: () => HRNav.go(context, const EmployeeProfileScreen()),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Notifications
              GestureDetector(
                onTap: () => HRNav.go(context, const NotificationsAdminScreen()),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
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

  // ═══════════════════════════════════════════════════════════════
  // DATE SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          // Previous Day
          GestureDetector(
            onTap: () {
              // Go to previous day
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:  Icon(
                Icons.chevron_left,
                size: 20,
                color: kSubText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Date Display
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: kPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy').format(DateTime.now()),
                    style:  TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Next Day
          GestureDetector(
            onTap: () {
              // Go to next day
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:  Icon(
                Icons.chevron_right,
                size: 20,
                color: kSubText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATS GRID - 3x2
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsGrid(BuildContext context) {
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
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        padding: EdgeInsets.zero,
        children: [
          _statItem(
            'Total Employees',
            '${_stats['totalEmployees'] ?? 0}',
            Icons.people_rounded,
            kPrimary,
            Colors.blue.shade50,
            () => HRNav.go(context, const EmployeesListScreen()),
          ),
          _statItem(
            'Present',
            '${_stats['present'] ?? 0}',
            Icons.check_circle_rounded,
            kSuccess,
            Colors.green.shade50,
            () => HRNav.go(context, const AdminAttendanceRegisterScreen()),
          ),
          _statItem(
            'Late',
            '${_stats['late'] ?? 0}',
            Icons.warning_rounded,
            kWarning,
            Colors.orange.shade50,
            () => HRNav.go(context, const AdminAttendanceRegisterScreen()),
          ),
          _statItem(
            'Absent',
            '${_stats['absent'] ?? 0}',
            Icons.person_off_rounded,
            kDanger,
            Colors.red.shade50,
            () => HRNav.go(context, const AdminAttendanceRegisterScreen()),
          ),
          _statItem(
            'On Leave',
            '${_stats['onLeave'] ?? 0}',
            Icons.beach_access_rounded,
            Colors.purple,
            Colors.purple.shade50,
            () => HRNav.go(context, const LeaveManagementAdminScreen()),
          ),
          _statItem(
            'Field Staff',
            '${_stats['fieldStaff'] ?? 0}',
            Icons.location_on_rounded,
            Colors.teal,
            Colors.teal.shade50,
            () => HRNav.go(context, const LiveEmployeeTrackingScreen()),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 8),
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: kSubText,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPendingApprovals(BuildContext context) {
    final total = _pendingLeaves + _pendingOt + _pendingLoans;
    if (total == 0) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => HRNav.go(context, const ApprovalsAdminScreen()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.inbox_rounded, color: Colors.deepOrange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$total Pending Approval${total == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.deepOrange)),
            const SizedBox(height: 2),
            Text(
              [
                if (_pendingLeaves > 0) '$_pendingLeaves leave${_pendingLeaves > 1 ? 's' : ''}',
                if (_pendingOt > 0) '$_pendingOt OT',
                if (_pendingLoans > 0) '$_pendingLoans loan${_pendingLoans > 1 ? 's' : ''}',
              ].join(' · '),
              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
            ),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Colors.deepOrange),
        ]),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final days = _weekly.take(7).toList();
    final maxY = days.fold<double>(0, (prev, d) {
      final p = (d['present'] as num?)?.toDouble() ?? 0;
      final a = (d['absent'] as num?)?.toDouble() ?? 0;
      return (p + a) > prev ? (p + a) : prev;
    });
    final safeMax = maxY < 1 ? 5.0 : maxY * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Weekly Attendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
            Row(children: [
              _legendDot(kPrimary, 'Present'),
              const SizedBox(width: 10),
              _legendDot(kDanger, 'Absent'),
            ]),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: safeMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => kPrimary.withValues(alpha: 0.9),
                    getTooltipItem: (g, gi, rod, ri) {
                      final d = days[gi];
                      return BarTooltipItem(
                        '${d['day'] ?? ''}\nP:${d['present'] ?? 0} A:${d['absent'] ?? 0}',
                        const TextStyle(color: Colors.white, fontSize: 10),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox.shrink();
                      final day = '${days[i]['day'] ?? ''}';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(day.length > 3 ? day.substring(0, 3) : day, style: TextStyle(fontSize: 9, color: kSubText)),
                      );
                    },
                    reservedSize: 22,
                  )),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}', style: TextStyle(fontSize: 9, color: kSubText)),
                  )),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: safeMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(color: kBorderLight, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(days.length, (i) {
                  final d = days[i];
                  final present = (d['present'] as num?)?.toDouble() ?? 0;
                  final absent = (d['absent'] as num?)?.toDouble() ?? 0;
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: present + absent,
                      width: 14,
                      borderRadius: BorderRadius.circular(4),
                      rodStackItems: [
                        BarChartRodStackItem(0, present, kPrimary),
                        BarChartRodStackItem(present, present + absent, kDanger.withValues(alpha: 0.6)),
                      ],
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: kSubText, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _buildQuickActions(BuildContext context) {
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
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _actionButton(
                'Add Employee',
                Icons.person_add_rounded,
                kPrimary,
                () => HRNav.go(context, const AddEmployeeScreen()),
              ),
              const SizedBox(width: 12),
              _actionButton(
                'Attendance',
                Icons.fingerprint_rounded,
                Colors.teal,
                () => HRNav.go(context, const AdminAttendanceRegisterScreen()),
              ),
              const SizedBox(width: 12),
              _actionButton(
                'Salary build',
                Icons.payments_rounded,
                Colors.purple,
                () => HRNav.go(context, const SalaryBuildScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LIVE TRACKING CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLiveTrackingCard(BuildContext context) {
    return GestureDetector(
      onTap: () => HRNav.go(context, const LiveEmployeeTrackingScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kPrimary.withValues(alpha: 0.08),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: kPrimary.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: kPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Live Employee Tracking',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: kSuccess,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                       Text(
                        '${_stats['liveCount'] ?? _stats['working'] ?? _stats['fieldStaff'] ?? 0} employees active',
                        style: TextStyle(
                          fontSize: 11,
                          color: kSubText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Live Map',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RECENT ACTIVITY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRecentActivity(BuildContext context) {
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
                onTap: () => HRNav.go(context, const LeaveManagementAdminScreen()),
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
          if (_attendance.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No attendance activity yet today',
                style: TextStyle(color: kSubTextLight, fontSize: 12),
              ),
            )
          else
            ..._attendance.take(6).toList().asMap().entries.expand((entry) {
              final row = entry.value;
              final emp = row['employee'];
              final name = emp is Map
                  ? '${emp['name'] ?? 'Employee'}'
                  : '${row['employee'] ?? row['employeeName'] ?? row['name'] ?? 'Employee'}';
              final status = '${row['status'] ?? 'present'}'.toLowerCase();
              String action;
              IconData icon;
              Color color;
              String subtitle;
              if (status.contains('late')) {
                action = 'Checked in (Late)';
                icon = Icons.warning_rounded;
                color = kWarning;
                subtitle = 'Late arrival';
              } else if (status.contains('absent')) {
                action = 'Absent';
                icon = Icons.person_off_rounded;
                color = kDanger;
                subtitle = 'No check-in';
              } else if (status.contains('leave')) {
                action = 'On leave';
                icon = Icons.beach_access_rounded;
                color = Colors.purple;
                subtitle = 'Approved leave';
              } else {
                action = 'Checked in';
                icon = Icons.login_rounded;
                color = kSuccess;
                subtitle = '${row['source'] ?? 'Attendance'}';
              }
              String time = '—';
              final checkIn = row['checkIn'];
              if (checkIn != null) {
                final raw = '$checkIn';
                time = raw.length >= 16 ? raw.substring(11, 16) : raw;
              }
              return [
                if (entry.key > 0) const Divider(height: 1),
                _activityItem(name, action, time, icon, color, subtitle),
              ];
            }),
        ],
      ),
    );
  }

  Widget _activityItem(
    String name,
    String action,
    String time,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style:  TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      action,
                      style: TextStyle(
                        fontSize: 11,
                        color: kSubText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: kSubText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
