// screens/employee_dashboard_screen.dart - EMPLOYEE DASHBOARD (Mobile Home)

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_self_service_screens.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:BisonsTechs_app/core/HR/services/location_tracking_service.dart';
import 'package:BisonsTechs_app/core/HR/utils/hr_role.dart';
import 'package:BisonsTechs_app/Services/auth_logout_service.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_attendance_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_profile_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_my_hr_hub_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_payslip_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/notifications_center_screen.dart';
import 'package:BisonsTechs_app/core/HR/utils/employee_nav.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _selectedQuickAction = 'All';
  bool _isRefreshing = false;
  late AnimationController _pulseController;
  late LocationTrackingService _tracking;

  Map<String, dynamic> _employeeData = {
    'name': 'Employee',
    'designation': '',
    'department': '',
    'employeeId': '',
    'profileImage': null,
    'shift': '',
    'office': '',
    'isCheckedIn': false,
    'checkInTime': '',
    'workingHours': '0h 00m',
  };

  final Map<String, dynamic> _todayStats = {
    'present': 0,
    'late': 0,
    'absent': 0,
    'onLeave': 0,
    'onBreak': 0,
    'working': 0,
  };

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _upcomingEvents = [];

  // Quick Actions
  final List<Map<String, dynamic>> _quickActions = [
    {
      'title': 'Check In',
      'icon': Icons.login_rounded,
      'color': kSuccess,
      'route': '/attendance',
    },
    {
      'title': 'Apply Leave',
      'icon': Icons.beach_access_rounded,
      'color': Colors.blue,
      'route': '/leave',
    },
    {
      'title': 'My Profile',
      'icon': Icons.person_rounded,
      'color': kPrimary,
      'route': '/profile',
    },
    {
      'title': 'Payslip',
      'icon': Icons.receipt_long_rounded,
      'color': Colors.purple,
      'route': '/payslip',
    },
    {
      'title': 'Reports',
      'icon': Icons.insert_chart_rounded,
      'color': Colors.orange,
      'route': '/reports',
    },
    {
      'title': 'My HR',
      'icon': Icons.badge_rounded,
      'color': Colors.teal,
      'route': '/myhr',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _tracking = Get.isRegistered<LocationTrackingService>()
        ? Get.find<LocationTrackingService>()
        : Get.put(LocationTrackingService(), permanent: true);
    _loadMe();
  }

  Future<void> _loadMe({bool startTracking = false}) async {
    try {
      final me = await HrApiService.instance.me();
      if (!mounted) return;
      final office = me['officeDetails'] as Map<String, dynamic>?;
      final attendance = me['attendance'] as Map<String, dynamic>?;
      final checkedIn = attendance?['isCheckedIn'] == true;
      final checkIn = attendance?['checkIn']?.toString() ?? '';
      setState(() {
        _employeeData = {
          'name': me['name']?.toString() ?? 'Employee',
          'designation': me['designation']?.toString() ?? '',
          'department': me['department']?.toString() ?? '',
          'employeeId': me['employeeCode']?.toString() ??
              me['employeeId']?.toString() ??
              '',
          'profileImage': null,
          'shift': me['shift']?.toString() ?? '',
          'office': me['office']?.toString() ?? '',
          'isCheckedIn': checkedIn,
          'checkInTime': checkIn,
          'workingHours': _formatMinutes(attendance?['workingMinutes']),
        };
        if (checkedIn) {
          _notifications = [
            {
              'id': 'att-today',
              'title': 'Attendance Marked',
              'message': 'Checked in${me['office'] != null ? ' at ${me['office']}' : ''}',
              'time': DateTime.tryParse(checkIn) ?? DateTime.now(),
              'type': 'success',
              'icon': Icons.fingerprint_rounded,
              'color': kSuccess,
              'isRead': false,
            }
          ];
        }
      });
      await _tracking.initProfile(
        employeeId: _employeeData['employeeId'] as String,
        employeeName: _employeeData['name'] as String,
        officeName: _employeeData['office'] as String?,
        officeLat: (office?['latitude'] as num?)?.toDouble(),
        officeLng: (office?['longitude'] as num?)?.toDouble(),
        officeRadius: (office?['radiusMeters'] as num?)?.toDouble() ??
            (office?['radius'] as num?)?.toDouble(),
        isFieldEmployee:
            (me['employeeType']?.toString().toLowerCase().contains('field') ??
                false),
        checkedIn: checkedIn,
        checkInTimeIso: checkIn,
      );
      if (startTracking || await _tracking.isTrackingPreferred()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tracking.startTracking();
        });
      }
    } catch (e) {
      if (!mounted) return;
      _tracking.lastMessage.value =
          e.toString().replaceFirst('Exception: ', '');
    }
  }

  String _formatMinutes(dynamic minutes) {
    final m = minutes is num ? minutes.toInt() : int.tryParse('$minutes') ?? 0;
    final h = m ~/ 60;
    final rest = m % 60;
    return '${h}h ${rest.toString().padLeft(2, '0')}m';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: kPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildTopHeader(context),
              _buildWelcomeSection(),
              _buildTrackingBanner(),
              _buildCurrentStatus(),
              _buildQuickActionsGrid(),
              _buildUpcomingEvents(),
              _buildNotificationsSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              // Menu Icon — switch back to dashboards / HR admin
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (ctx) {
                      final employeeOnly = isEmployeeRole();
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!employeeOnly) ...[
                              ListTile(
                                leading: const Icon(Icons.apps_rounded),
                                title: const Text('All Dashboards'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Get.offAllNamed('/dashboard');
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.groups_outlined),
                                title: const Text('HR Admin Dashboard'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Get.offAllNamed('/hr/dashboard');
                                },
                              ),
                            ],
                            ListTile(
                              leading: const Icon(Icons.logout_rounded),
                              title: const Text('Logout'),
                              onTap: () async {
                                Navigator.pop(ctx);
                                await AuthLogoutService.clearLocalSession();
                                Get.offAllNamed('/login');
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
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
                      'Employee Dashboard',
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
              // Notifications
              Stack(
                children: [
                  GestureDetector(
                    onTap: _openNotifications,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_notifications.where((n) => !n['isRead']).length}',
                          style: const TextStyle(
                            fontSize: 6,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WELCOME SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWelcomeSection() {
    return GestureDetector(
      onTap: _openProfile,
      child: Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kPrimary.withValues(alpha: 0.2),
                  kPrimary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: kPrimary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _employeeData['profileImage'] != null
                  ? Image.network(
                      _employeeData['profileImage'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildWelcomeAvatarPlaceholder(),
                    )
                  : _buildWelcomeAvatarPlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning 👋',
                  style: TextStyle(
                    fontSize: 12,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _employeeData['name'] as String,
                  style:  TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_employeeData['designation']} • ${_employeeData['department']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
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

  Widget _buildWelcomeAvatarPlaceholder() {
    final name = _employeeData['name']?.toString() ?? 'E';
    final initials = name
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .join()
        .toUpperCase();
    return Container(
      color: kPrimary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: kPrimary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CURRENT STATUS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTrackingBanner() {
    return Obx(() {
      final tracking = _tracking.isTracking.value;
      final msg = _tracking.lastMessage.value;
      final inside = _tracking.insideGeofence.value;
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (tracking ? kPrimary : kWarning).withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  tracking ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                  color: tracking ? kPrimary : kWarning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tracking
                        ? (inside
                            ? 'Inside office · live location on · attendance uses office radius'
                            : 'Live location on — HR can see you even outside the office')
                        : 'Location tracking is off',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ),
                Switch.adaptive(
                  value: tracking,
                  activeThumbColor: kPrimary,
                  onChanged: (v) {
                    if (v) {
                      _tracking.startTracking();
                    } else {
                      _tracking.stopTracking();
                    }
                  },
                ),
              ],
            ),
            if (msg.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                msg,
                style: TextStyle(fontSize: 11, color: kSubText),
              ),
            ],
            if (tracking && _tracking.lastLat.value != 0) ...[
              const SizedBox(height: 4),
              Text(
                'Last point: ${_tracking.lastLat.value.toStringAsFixed(5)}, ${_tracking.lastLng.value.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildCurrentStatus() {
    return Obx(() {
      final isCheckedIn =
          _tracking.isCheckedIn.value || (_employeeData['isCheckedIn'] as bool);
      final checkInTime = _tracking.checkInTime.value.isNotEmpty
          ? _tracking.checkInTime.value
          : (_employeeData['checkInTime'] as String? ?? '');

      return GestureDetector(
        onTap: _openAttendance,
        child: Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
        border: Border.all(
          color: isCheckedIn ? kSuccess.withValues(alpha: 0.2) : kWarning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status Animation
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 12 + (_pulseController.value * 6),
                    height: 12 + (_pulseController.value * 6),
                    decoration: BoxDecoration(
                      color: isCheckedIn
                          ? kSuccess.withValues(alpha: 0.3)
                          : kWarning.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isCheckedIn ? kSuccess : kWarning,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckedIn ? '✅ Checked In' : '⚠️ Not Checked In',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isCheckedIn ? kSuccess : kWarning,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCheckedIn
                          ? 'Checked in at $checkInTime'
                          : 'Stay inside office geofence ~2 min for auto attendance',
                      style: TextStyle(
                        fontSize: 11,
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
                  color: isCheckedIn
                      ? kSuccess.withValues(alpha: 0.08)
                      : kWarning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCheckedIn
                        ? kSuccess.withValues(alpha: 0.2)
                        : kWarning.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  isCheckedIn ? _employeeData['workingHours'] : '00h 00m',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isCheckedIn ? kSuccess : kWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statusItem(
                Icons.schedule_rounded,
                'Shift',
                _employeeData['shift']?.toString() ?? '',
                kPrimary,
              ),
              _statusItem(
                Icons.location_on_rounded,
                'Office',
                _employeeData['office']?.toString() ?? '',
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    ),
    );
    });
  }

  Widget _statusItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 10,
                    color: kText,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK ACTIONS GRID
  // ═══════════════════════════════════════════════════════════════

  Widget _buildQuickActionsGrid() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: _quickActions.map((action) {
              return GestureDetector(
                onTap: () {
                  _handleQuickAction(action);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: action['color'].withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: action['color'].withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: action['color'].withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          action['icon'],
                          size: 22,
                          color: action['color'],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action['title'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kText,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // UPCOMING EVENTS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUpcomingEvents() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              GestureDetector(
                onTap: _openLeaves,
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
          if (_upcomingEvents.isEmpty)
            Text(
              'No upcoming events. Apply leave or check attendance from the tabs below.',
              style: TextStyle(fontSize: 12, color: kSubText),
            ),
          if (_upcomingEvents.isNotEmpty)
          ..._upcomingEvents.map((event) {
            final daysUntil = event['date'].difference(DateTime.now()).inDays;
            return Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: event['color'].withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: event['color'].withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: event['color'].withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('dd').format(event['date']),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: event['color'],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                        Text(
                          '${DateFormat('EEE, dd MMM').format(event['date'])} • ${event['type']}',
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
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: event['color'].withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: event['color'].withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      daysUntil == 0
                          ? 'Today'
                          : daysUntil == 1
                              ? 'Tomorrow'
                              : '$daysUntil days',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: event['color'],
                      ),
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
  // NOTIFICATIONS SECTION
  // ═══════════════════════════════════════════════════════════════

  Widget _buildNotificationsSection() {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
              Row(
                children: [
                   Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kDanger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              GestureDetector(
                onTap: () {
                  // Mark all as read
                  setState(() {
                    for (var notification in _notifications) {
                      notification['isRead'] = true;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: kSuccess,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Mark All Read',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._notifications.take(3).map((notification) {
            final isRead = notification['isRead'] as bool;
            return Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isRead
                    ? Colors.transparent
                    : notification['color'].withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isRead
                      ? Colors.grey.withValues(alpha: 0.05)
                      : notification['color'].withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: notification['color'].withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      notification['icon'],
                      size: 16,
                      color: notification['color'],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['title'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isRead ? kSubText : kText,
                          ),
                        ),
                        Text(
                          notification['message'],
                          style: TextStyle(
                            fontSize: 10,
                            color: kSubText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getTimeAgo(notification['time']),
                        style: TextStyle(
                          fontSize: 9,
                          color: kSubText,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (_notifications.length > 3) ...[
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                onTap: _openNotifications,
                child: Text(
                  'View ${_notifications.length - 3} more notifications',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Home', true, () {}),
              _navItem(Icons.calendar_today_rounded, 'Attendance', false, _openAttendance),
              _navItem(Icons.beach_access_rounded, 'Leaves', false, _openLeaves),
              _navItem(Icons.person_rounded, 'Profile', false, _openProfile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? kPrimary : kSubText,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? kPrimary : kSubText,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM').format(dateTime);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadMe();
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _openAttendance() async {
    await openEmployeeScreen(context,  EmployeeAttendanceScreen());
    if (mounted) _loadMe();
  }

  Future<void> _openProfile() {
    return openEmployeeScreen(context,  EmployeeProfileScreen());
  }

  Future<void> _openLeaves() {
    return openEmployeeScreen(context,  EmployeeLeavesScreen());
  }

  Future<void> _openPayslip() {
    return openEmployeeScreen(context,  EmployeePayslipScreen());
  }

  Future<void> _openReports() {
    return openEmployeeScreen(context,  EmployeePayslipScreen());
  }

  Future<void> _openMyHr() {
    return openEmployeeScreen(context,  EmployeeMyHrHubScreen());
  }

  Future<void> _openNotifications() {
    return openEmployeeScreen(
      context,
      NotificationsCenterScreen(items: List<Map<String, dynamic>>.from(_notifications)),
    );
  }

  void _handleQuickAction(Map<String, dynamic> action) {
    switch (action['route'] as String) {
      case '/attendance':
        _openAttendance();
        return;
      case '/leave':
        _openLeaves();
        return;
      case '/profile':
        _openProfile();
        return;
      case '/payslip':
        _openPayslip();
        return;
      case '/reports':
        _openReports();
        return;
      case '/help':
        _openMyHr();
        return;
      case '/myhr':
        _openMyHr();
        return;
    }
  }
}