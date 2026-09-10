import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_payslip_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_self_service_screens.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_profile_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_attendance_screen.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:BisonsTechs_app/core/HR/utils/employee_nav.dart';
import 'package:flutter/material.dart';

class EmployeeMyHrHubScreen extends StatefulWidget {
  const EmployeeMyHrHubScreen({super.key});

  @override
  State<EmployeeMyHrHubScreen> createState() => _EmployeeMyHrHubScreenState();
}

class _EmployeeMyHrHubScreenState extends State<EmployeeMyHrHubScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _data = await HrApiService.instance.ess();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employee = _data['employee'] as Map<String, dynamic>? ?? {};
    final balances = (_data['leaveBalances'] as List?)?.whereType<Map>().toList() ?? [];
    final holidays = (_data['holidays'] as List?)?.whereType<Map>().toList() ?? [];
    final tasks = (_data['tasks'] as List?)?.whereType<Map>().toList() ?? [];
    final roster = (_data['roster'] as List?)?.whereType<Map>().toList() ?? [];

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kPrimary,
        title: const Text('My HR', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      employee['name']?.toString() ?? 'Employee',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${employee['designation'] ?? ''} · ${employee['department'] ?? ''}',
                      style: TextStyle(color: kSubText, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _tile('Profile', Icons.person, () => openEmployeeScreen(context, const EmployeeProfileScreen())),
                        _tile('Attendance', Icons.fingerprint, () => openEmployeeScreen(context, const EmployeeAttendanceScreen())),
                        _tile('Leaves', Icons.beach_access, () => openEmployeeScreen(context, const EmployeeLeavesScreen())),
                        _tile('Payslips', Icons.receipt_long, () => openEmployeeScreen(context, const EmployeePayslipScreen())),
                        _tile('Reports', Icons.bar_chart, () => openEmployeeScreen(context, const EmployeeMyReportsScreen())),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Leave balances', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (balances.isEmpty)
                      Text('Balances appear after HR sets leave policies.', style: TextStyle(color: kSubText, fontSize: 12)),
                    ...balances.map((b) => _row('${b['type']}', '${b['remaining'] ?? 0} remaining')),
                    const SizedBox(height: 16),
                    const Text('Upcoming holidays', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...holidays.take(5).map((h) => _row('${h['name']}', '${h['date']}')),
                    const SizedBox(height: 16),
                    const Text('My roster', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (roster.isEmpty) Text('No upcoming shift assignments.', style: TextStyle(color: kSubText, fontSize: 12)),
                    ...roster.take(5).map((r) => _row('${r['workDate']}', '${r['shift'] ?? 'Shift'}')),
                    const SizedBox(height: 16),
                    const Text('My tasks', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...tasks.take(5).map((t) => _row('${t['title']}', '${t['status']}')),
                  ],
                ),
    );
  }

  Widget _tile(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE4EE)),
        ),
        child: Column(
          children: [
            Icon(icon, color: kPrimary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _row(String left, String right) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE4EE)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(left, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          Text(right, style: TextStyle(color: kSubText, fontSize: 12)),
        ],
      ),
    );
  }
}
