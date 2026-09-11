import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/screens/add_employee_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employees_list_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/hr_admin_modules.dart';
import 'package:BisonsTechs_app/core/HR/screens/live_employee_tracking_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/manager_my_team_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/office_management_screen.dart';
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

class _NavItem {
  final String id;
  final String label;
  final IconData icon;
  final Widget Function()? builder;

  const _NavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.builder,
  });
}

class _NavSection {
  final String label;
  final List<_NavItem> items;
  const _NavSection(this.label, this.items);
}

final _hrSections = [
  _NavSection('MAIN', [
    _NavItem(id: 'dashboard', label: 'Dashboard', icon: Icons.home_rounded),
    _NavItem(
      id: 'employees',
      label: 'Employees',
      icon: Icons.people_rounded,
      builder: () => const EmployeesListScreen(),
    ),
    _NavItem(
      id: 'add_employee',
      label: 'Add Employee',
      icon: Icons.person_add_rounded,
      builder: () => const AddEmployeeScreen(),
    ),
    _NavItem(
      id: 'offices',
      label: 'Offices',
      icon: Icons.apartment_rounded,
      builder: () => const OfficeManagementScreen(),
    ),
    _NavItem(
      id: 'departments',
      label: 'Departments',
      icon: Icons.account_tree_rounded,
      builder: () => const DepartmentsAdminScreen(),
    ),
    _NavItem(
      id: 'my_team',
      label: 'My Team',
      icon: Icons.groups_rounded,
      builder: () => const ManagerMyTeamScreen(),
    ),
  ]),
  _NavSection('TIME & ATTENDANCE', [
    _NavItem(
      id: 'attendance',
      label: 'Attendance',
      icon: Icons.fingerprint_rounded,
      builder: () => const AdminAttendanceRegisterScreen(),
    ),
    _NavItem(
      id: 'shifts',
      label: 'Shifts',
      icon: Icons.schedule_rounded,
      builder: () => const ShiftsAdminScreen(),
    ),
    _NavItem(
      id: 'calendar',
      label: 'Calendar View',
      icon: Icons.calendar_month_rounded,
      builder: () => const CalendarAdminScreen(),
    ),
    _NavItem(
      id: 'leave',
      label: 'Leave Management',
      icon: Icons.flight_takeoff_rounded,
      builder: () => const LeaveManagementAdminScreen(),
    ),
    _NavItem(
      id: 'leave_policies',
      label: 'Leave Policies',
      icon: Icons.policy_rounded,
      builder: () => const LeavePoliciesAdminScreen(),
    ),
    _NavItem(
      id: 'holidays',
      label: 'Holidays',
      icon: Icons.celebration_rounded,
      builder: () => const HolidaysAdminScreen(),
    ),
    _NavItem(
      id: 'overtime',
      label: 'Overtime',
      icon: Icons.more_time_rounded,
      builder: () => const OvertimeAdminScreen(),
    ),
    _NavItem(
      id: 'shift_plans',
      label: 'Shift Plans',
      icon: Icons.playlist_add_check_rounded,
      builder: () => const ShiftPlansAdminScreen(),
    ),
    _NavItem(
      id: 'roster',
      label: 'Roster',
      icon: Icons.calendar_view_week_rounded,
      builder: () => const RosterAdminScreen(),
    ),
    _NavItem(
      id: 'live_tracking',
      label: 'Live Tracking',
      icon: Icons.map_rounded,
      builder: () => const LiveEmployeeTrackingScreen(),
    ),
  ]),
  _NavSection('WORKFORCE', [
    _NavItem(
      id: 'payroll',
      label: 'Office Payroll',
      icon: Icons.payments_rounded,
      builder: () => const SalaryBuildScreen(),
    ),
    _NavItem(
      id: 'sales_payroll',
      label: 'Sales Payroll',
      icon: Icons.point_of_sale_rounded,
      builder: () => const SalesPayrollScreen(),
    ),
    _NavItem(
      id: 'loans',
      label: 'Loans & Advances',
      icon: Icons.account_balance_rounded,
      builder: () => const LoansAdminScreen(),
    ),
    _NavItem(
      id: 'bonuses',
      label: 'Bonuses',
      icon: Icons.emoji_events_rounded,
      builder: () => const BonusesAdminScreen(),
    ),
    _NavItem(
      id: 'lifecycle',
      label: 'Lifecycle',
      icon: Icons.timeline_rounded,
      builder: () => const LifecycleAdminScreen(),
    ),
    _NavItem(
      id: 'documents',
      label: 'Documents',
      icon: Icons.folder_open_rounded,
      builder: () => const DocumentsAdminScreen(),
    ),
    _NavItem(
      id: 'approvals',
      label: 'Approvals',
      icon: Icons.inbox_rounded,
      builder: () => const ApprovalsAdminScreen(),
    ),
    _NavItem(
      id: 'tasks',
      label: 'Task Management',
      icon: Icons.task_alt_rounded,
      builder: () => const TasksAdminScreen(),
    ),
    _NavItem(
      id: 'performance',
      label: 'Performance Reviews',
      icon: Icons.rate_review_rounded,
      builder: () => const PerformanceAdminScreen(),
    ),
    _NavItem(
      id: 'org_chart',
      label: 'Organization Chart',
      icon: Icons.device_hub_rounded,
      builder: () => const OrgChartAdminScreen(),
    ),
  ]),
  _NavSection('INSIGHTS & SETTINGS', [
    _NavItem(
      id: 'reports',
      label: 'Reports & Analytics',
      icon: Icons.bar_chart_rounded,
      builder: () => const ReportsAdminScreen(),
    ),
    _NavItem(
      id: 'notifications',
      label: 'Notifications',
      icon: Icons.notifications_rounded,
      builder: () => const NotificationsAdminScreen(),
    ),
    _NavItem(
      id: 'settings',
      label: 'HR Settings',
      icon: Icons.settings_rounded,
      builder: () => const HrSettingsAdminScreen(),
    ),
  ]),
];

class HRDrawer extends StatelessWidget {
  final String currentItem;

  const HRDrawer({super.key, this.currentItem = 'dashboard'});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              children: [
                for (final section in _hrSections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                    child: Text(
                      section.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  ...section.items.map((item) => _item(context, item)),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          SafeArea(
            top: false,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.apps_rounded, color: Colors.white.withValues(alpha: 0.7)),
                  title: Text(
                    'All Dashboards',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.offAllNamed('/dashboard');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: Colors.white),
                  title: const Text(
                    'Employee Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Get.offAllNamed('/hr/employee-dashboard');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: kDanger),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: kDanger,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () => _confirmLogout(context),
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
                ),
                child: const Icon(
                  Icons.groups_rounded,
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
                      'HR Management',
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

  Widget _item(BuildContext context, _NavItem item) {
    final selected = currentItem == item.id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          item.icon,
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
          size: 20,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.8),
          ),
        ),
        dense: true,
        onTap: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          if (item.id == 'dashboard') {
            Get.offAllNamed('/hr/dashboard');
            return;
          }
          if (item.builder != null) {
            navigator.push(MaterialPageRoute(builder: (_) => item.builder!()));
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
