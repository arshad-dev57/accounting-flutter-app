import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_payslip_screen.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.75),
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
}

class EmployeeLeavesScreen extends StatefulWidget {
  const EmployeeLeavesScreen({super.key});

  @override
  State<EmployeeLeavesScreen> createState() => _EmployeeLeavesScreenState();
}

class _EmployeeLeavesScreenState extends State<EmployeeLeavesScreen> {
  String _employeeName = '';
  List<Map<String, dynamic>> _leaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await HrApiService.instance.me();
      _employeeName = me['name']?.toString() ?? 'Employee';
      _leaves = await HrApiService.instance.myLeaves();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _applyLeave() async {
    String leaveType = 'Casual Leave';
    final reasonCtrl = TextEditingController();
    DateTime from = DateTime.now();
    DateTime to = DateTime.now();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apply leave',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: leaveType,
                    decoration: const InputDecoration(
                      labelText: 'Leave type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      'Casual Leave',
                      'Sick Leave',
                      'Annual Leave',
                      'Emergency Leave',
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setModal(() => leaveType = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: from,
                              firstDate: DateTime.now()
                                  .subtract(const Duration(days: 1)),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModal(() {
                                from = picked;
                                if (to.isBefore(from)) to = from;
                              });
                            }
                          },
                          child: Text('From ${DateFormat('dd MMM').format(from)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: to.isBefore(from) ? from : to,
                              firstDate: from,
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365)),
                            );
                            if (picked != null) setModal(() => to = picked);
                          },
                          child: Text('To ${DateFormat('dd MMM').format(to)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (reasonCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Submit request'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (submitted != true) {
      reasonCtrl.dispose();
      return;
    }
    try {
      await HrApiService.instance.applyLeave(
        type: leaveType,
        from: DateFormat('yyyy-MM-dd').format(from),
        to: DateFormat('yyyy-MM-dd').format(to),
        reason: reasonCtrl.text.trim(),
      );
      reasonCtrl.dispose();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request submitted to HR')),
        );
      }
    } catch (e) {
      reasonCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _applyLeave,
        backgroundColor: kPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Apply leave', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _EmployeeHeader(
            title: 'My Leaves',
            subtitle: _employeeName.isEmpty ? null : _employeeName,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _leaves.isEmpty
                    ? const Center(
                        child: Text(
                          'No leave requests yet.\nTap Apply leave to submit one.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _leaves.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final leave = _leaves[i];
                          final from = DateTime.tryParse('${leave['from']}');
                          final to = DateTime.tryParse('${leave['to']}');
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFDDE4EE),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${leave['type']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${leave['status']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: leave['status'] == 'Pending'
                                            ? kWarning
                                            : kSuccess,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  from != null && to != null
                                      ? '${DateFormat('dd MMM').format(from)} – ${DateFormat('dd MMM').format(to)} · ${leave['days']} day(s)'
                                      : '',
                                  style: TextStyle(fontSize: 12, color: kSubText),
                                ),
                                if ('${leave['reason']}'.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    '${leave['reason']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class EmployeeMyReportsScreen extends StatefulWidget {
  const EmployeeMyReportsScreen({super.key});

  @override
  State<EmployeeMyReportsScreen> createState() => _EmployeeMyReportsScreenState();
}

class _EmployeeMyReportsScreenState extends State<EmployeeMyReportsScreen> {
  Map<String, dynamic> _me = {};
  Map<String, dynamic> _att = {};
  Map<String, dynamic> _ytd = {};
  List<Map<String, dynamic>> _slips = [];
  bool _loading = true;
  String? _error;
  final _money = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await HrApiService.instance.me();
      final att = await HrApiService.instance.myAttendance();
      final payroll = await HrApiService.instance.myPayroll();
      _me = me;
      _att = att;
      _slips = (payroll['items'] as List).whereType<Map<String, dynamic>>().toList();
      _ytd = payroll['ytd'] is Map
          ? Map<String, dynamic>.from(payroll['ytd'] as Map)
          : {};
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  double _n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  @override
  Widget build(BuildContext context) {
    final attendance = _att['attendance'] as Map<String, dynamic>?;
    final employee = _att['employee'] as Map<String, dynamic>? ?? _me;
    final latest = _slips.isNotEmpty ? _slips.first : null;
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          const _EmployeeHeader(
            title: 'My Reports',
            subtitle: 'Attendance and payroll year-to-date',
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          const Text('Today', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 8),
                          _card('Employee', employee['name']?.toString() ?? _me['name']?.toString() ?? '—'),
                          _card('Office', employee['office']?.toString() ?? _me['office']?.toString() ?? '—'),
                          _card(
                            'Status',
                            attendance == null
                                ? 'Not checked in'
                                : attendance['isCheckedIn'] == true
                                    ? 'Working'
                                    : attendance['checkOut'] != null
                                        ? 'Checked out'
                                        : 'Not checked in',
                          ),
                          _card('Check-in', _fmt(attendance?['checkIn'])),
                          _card('Check-out', _fmt(attendance?['checkOut'])),
                          _card('Working hours', _hours(attendance?['workingMinutes'])),
                          const SizedBox(height: 12),
                          const Text('Payroll YTD', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 8),
                          _card('Net paid this year', _money.format(_n(_ytd['net']))),
                          _card('Gross earnings', _money.format(_n(_ytd['gross']))),
                          _card('Deductions', _money.format(_n(_ytd['deductions']))),
                          _card('Tax / EOBI / PF', '${_money.format(_n(_ytd['tax']))} / ${_money.format(_n(_ytd['eobi']))} / ${_money.format(_n(_ytd['providentFund']))}'),
                          if (latest != null) ...[
                            const SizedBox(height: 12),
                            const Text('Latest released payslip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 8),
                            _card(latest['periodLabel']?.toString() ?? 'Payslip', _money.format(_n(latest['net']))),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EmployeePayslipDetailScreen(slip: latest),
                                  ),
                                );
                              },
                              child: const Text('Open official payslip'),
                            ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic value) {
    final dt = DateTime.tryParse('$value');
    if (dt == null) return '—';
    return DateFormat('hh:mm a').format(dt.toLocal());
  }

  String _hours(dynamic minutes) {
    final m = minutes is num ? minutes.toInt() : int.tryParse('$minutes') ?? 0;
    return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
  }

  Widget _card(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE4EE)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: kSubText))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeHelpScreen extends StatelessWidget {
  const EmployeeHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          const _EmployeeHeader(
            title: 'Help',
            subtitle: 'How employee attendance works',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _HelpTile(
                  title: 'Check-in / check-out',
                  body:
                      'Office radius is used for attendance. Stay inside the office geofence to check in. Leaving the office can mark check-out.',
                ),
                _HelpTile(
                  title: 'Live location',
                  body:
                      'Turn on location tracking from the dashboard. HR can see your last location even if you are out in the field. Tracking history is not saved.',
                ),
                _HelpTile(
                  title: 'Payroll & payslips',
                  body:
                      'HR processes a monthly pay run from attendance, approved leave and overtime. After the run is approved or marked paid, your official payslip appears under Payslip with earnings, deductions and year-to-date totals.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(fontSize: 12, color: kSubText, height: 1.4)),
        ],
      ),
    );
  }
}
