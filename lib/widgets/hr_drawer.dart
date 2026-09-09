import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/screens/add_employee_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_attendance_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employees_list_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/holiday_management_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/hr_reports_analytics_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/hr_settings_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/leave_management_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/live_employee_tracking_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/notifications_center_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/office_management_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/organization_chart_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/overtime_management_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/payroll_generation_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/performance_reviews_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/shift_management_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/task_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HRNav {
  static void go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  static void logout(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }
}

class HRDrawer extends StatelessWidget {
  final String currentItem;

  const HRDrawer({super.key, this.currentItem = 'dashboard'});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _item(
                  context,
                  id: 'dashboard',
                  icon: Icons.home_rounded,
                  label: 'Dashboard',
                ),
                _item(
                  context,
                  id: 'employees',
                  icon: Icons.people_rounded,
                  label: 'Employees',
                  screen: const EmployeesListScreen(),
                ),
                _item(
                  context,
                  id: 'add_employee',
                  icon: Icons.person_add_rounded,
                  label: 'Add Employee',
                  screen: const AddEmployeeScreen(),
                ),
                _item(
                  context,
                  id: 'offices',
                  icon: Icons.apartment_rounded,
                  label: 'Offices',
                  screen: const OfficeManagementScreen(),
                ),
                _item(
                  context,
                  id: 'shifts',
                  icon: Icons.schedule_rounded,
                  label: 'Shifts',
                  screen: const ShiftManagementScreen(),
                ),
                _item(
                  context,
                  id: 'attendance',
                  icon: Icons.fingerprint_rounded,
                  label: 'Attendance',
                  screen: const EmployeeAttendanceScreen(),
                ),
                _item(
                  context,
                  id: 'live_tracking',
                  icon: Icons.map_rounded,
                  label: 'Live Tracking',
                  screen: const LiveEmployeeTrackingScreen(),
                ),
                _item(
                  context,
                  id: 'leave',
                  icon: Icons.beach_access_rounded,
                  label: 'Leave Management',
                  screen: const LeaveManagementScreen(),
                ),
                _item(
                  context,
                  id: 'holidays',
                  icon: Icons.celebration_rounded,
                  label: 'Holidays',
                  screen: const HolidayManagementScreen(),
                ),
                _item(
                  context,
                  id: 'overtime',
                  icon: Icons.more_time_rounded,
                  label: 'Overtime',
                  screen: const OvertimeManagementScreen(),
                ),
                _item(
                  context,
                  id: 'payroll',
                  icon: Icons.payments_rounded,
                  label: 'Payroll',
                  screen: const PayrollGenerationScreen(),
                ),
                _item(
                  context,
                  id: 'reports',
                  icon: Icons.bar_chart_rounded,
                  label: 'Reports',
                  screen: const HRReportsAnalyticsScreen(),
                ),
                _item(
                  context,
                  id: 'organization',
                  icon: Icons.account_tree_rounded,
                  label: 'Organization',
                  screen: const OrganizationChartScreen(),
                ),
                _item(
                  context,
                  id: 'performance',
                  icon: Icons.rate_review_rounded,
                  label: 'Performance',
                  screen: const PerformanceReviewsScreen(),
                ),
                _item(
                  context,
                  id: 'tasks',
                  icon: Icons.task_alt_rounded,
                  label: 'Task Management',
                  screen: const TaskManagementScreen(),
                ),
                _item(
                  context,
                  id: 'notifications',
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  screen: const NotificationsCenterScreen(),
                ),
                _item(
                  context,
                  id: 'settings',
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  screen: const HRSettingsScreen(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.apps_rounded, color: Colors.grey.shade700),
                  title: Text(
                    'All Dashboards',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.offAllNamed('/dashboard');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: kPrimary),
                  title: const Text(
                    'Employee Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.offAllNamed('/hr/employee-dashboard');
                  },
                ),
                _item(
                  context,
                  id: 'logout',
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  isLogout: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HR Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'hr@bisonstechs.com',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
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

  Widget _item(
    BuildContext context, {
    required String id,
    required IconData icon,
    required String label,
    Widget? screen,
    bool isLogout = false,
  }) {
    final selected = currentItem == id;
    final color = isLogout ? kDanger : (selected ? kPrimary : kText);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: kPrimary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
        dense: true,
        onTap: () {
          if (isLogout) {
            _confirmLogout(context);
            return;
          }
          final navigator = Navigator.of(context);
          navigator.pop();
          if (screen != null) {
            navigator.push(MaterialPageRoute(builder: (_) => screen));
          }
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: kSubText)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              HRNav.logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
