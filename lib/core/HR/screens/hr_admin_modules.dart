import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:BisonsTechs_app/core/HR/widgets/hr_admin_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String hrPersonName(dynamic value) {
  if (value == null) return 'Employee';
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is Map) {
    final name = value['name'] ?? value['employee'] ?? value['employeeName'];
    if (name != null && '$name'.trim().isNotEmpty) return '$name'.trim();
  }
  return 'Employee';
}

String hrField(Map<String, dynamic> row, List<String> keys, [String fallback = '—']) {
  for (final key in keys) {
    final value = row[key];
    if (value == null) continue;
    final text = '$value'.trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return fallback;
}

String hrMoney(dynamic value) {
  final n = value is num ? value : num.tryParse('$value') ?? 0;
  return 'Rs ${n.toStringAsFixed(0)}';
}

String hrShortDate(dynamic value) {
  if (value == null) return '—';
  final raw = '$value';
  if (raw.length >= 10) return raw.substring(0, 10);
  return raw;
}

// ── Admin attendance register (web /hr/attendance) ───────────────
class AdminAttendanceRegisterScreen extends StatefulWidget {
  const AdminAttendanceRegisterScreen({super.key});

  @override
  State<AdminAttendanceRegisterScreen> createState() =>
      _AdminAttendanceRegisterScreenState();
}

class _AdminAttendanceRegisterScreenState
    extends State<AdminAttendanceRegisterScreen> {
  DateTime _date = DateTime.now();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _employees = [];
  String _filter = 'All';
  String _query = '';

  static const _filters = ['All', 'Present', 'Late', 'Absent', 'Half Day'];
  static const _statusOptions = [
    'Present', 'Late', 'Absent', 'Half Day', 'On Leave', 'Weekly Off', 'Holiday'
  ];

  String get _ymd => DateFormat('yyyy-MM-dd').format(_date);

  @override
  void initState() {
    super.initState();
    _load();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final list = await HrApiService.instance.employees();
      if (!mounted) return;
      setState(() => _employees = list);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final summary = await HrApiService.instance.attendanceSummary(date: _ymd);
      if (!mounted) return;
      final summaryMap = summary['summary'] is Map
          ? Map<String, dynamic>.from(summary['summary'] as Map)
          : <String, dynamic>{};
      List<Map<String, dynamic>> rows = [];
      final data = summary['data'];
      if (data is List) {
        rows = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
      if (rows.isEmpty) {
        final list = await HrApiService.instance.listAttendance(date: _ymd);
        rows = list;
      }
      setState(() { _summary = summaryMap; _rows = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _rows.where((r) {
      final status = '${r['status'] ?? ''}';
      final name = hrPersonName(r['employee'] ?? r['employeeName']);
      final q = _query.toLowerCase();
      final matchesFilter = _filter == 'All' || status == _filter;
      final matchesQuery = q.isEmpty || name.toLowerCase().contains(q);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  Future<void> _pickDate() async {
    final next = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (next == null) return;
    setState(() => _date = next);
    _load();
  }

  void _openMarkDialog({Map<String, dynamic>? existing}) {
    final isNew = existing == null;
    String empId = isNew ? (_employees.isNotEmpty ? '${_employees.first['id']}' : '') : '${existing['employeeId'] ?? ''}';
    String status = isNew ? 'Present' : '${existing['status'] ?? 'Present'}';

    String _timeOf(dynamic v) {
      final s = '$v';
      if (s == 'null' || s.isEmpty) return '';
      if (s.length >= 16) return s.substring(11, 16);
      return s;
    }

    String checkIn = isNew ? '09:00' : _timeOf(existing['checkIn']);
    String checkOut = isNew ? '18:00' : _timeOf(existing['checkOut']);
    bool saving = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final noTimes = status == 'Absent' || status == 'Weekly Off' || status == 'Holiday' || status == 'On Leave';
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isNew ? 'Mark / Adjust Attendance' : 'Edit Attendance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNew && _employees.isNotEmpty) ...[
                  const Text('Employee', style: TextStyle(fontSize: 12, color: kSubTextLight)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: empId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _employees.map((e) => DropdownMenuItem(
                      value: '${e['id']}',
                      child: Text('${e['name']}', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) => ss(() => empId = v ?? empId),
                  ),
                  const SizedBox(height: 12),
                ] else if (!isNew) ...[
                  Text(
                    hrPersonName(existing['employee'] ?? existing['employeeName']),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                ],
                const Text('Status', style: TextStyle(fontSize: 12, color: kSubTextLight)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => ss(() => status = v ?? status),
                ),
                if (!noTimes) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _timeField('Check-in', checkIn, (v) => ss(() => checkIn = v))),
                      const SizedBox(width: 8),
                      Expanded(child: _timeField('Check-out', checkOut, (v) => ss(() => checkOut = v))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: saving ? null : () async {
                ss(() => saving = true);
                try {
                  await HrApiService.instance.upsertAttendance({
                    'employeeId': isNew ? empId : '${existing['employeeId'] ?? existing['id'] ?? ''}',
                    'date': _ymd,
                    'status': status,
                    if (!noTimes && checkIn.isNotEmpty) 'checkIn': checkIn,
                    if (!noTimes && checkOut.isNotEmpty) 'checkOut': checkOut,
                  });
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  await _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attendance saved — payroll will use this')),
                    );
                  }
                } catch (e) {
                  ss(() => saving = false);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: kDanger),
                  );
                }
              },
              child: Text(saving ? 'Saving…' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  Widget _timeField(String label, String value, void Function(String) onChanged) {
    final ctrl = TextEditingController(text: value);
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'HH:mm',
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        labelStyle: const TextStyle(fontSize: 11),
      ),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final present = _summary['present'] ??
        _rows.where((r) => '${r['status']}'.toLowerCase().contains('present')).length;
    final late = _summary['late'] ??
        _rows.where((r) => '${r['status']}'.toLowerCase() == 'late').length;
    final absent = _summary['absent'] ??
        _rows.where((r) => '${r['status']}'.toLowerCase().contains('absent')).length;
    final records = _rows.length;
    final onLeave = _summary['onLeave'] ?? _summary['on_leave'] ?? 0;
    final missingOut = _summary['missingCheckout'] ?? _summary['missing_checkout'] ?? 0;
    final halfDay = _summary['halfDay'] ?? _summary['half_day'] ?? 0;
    final headcount = _summary['headcount'] ?? 0;

    final filtered = _filtered;

    return HrAdminScaffold(
      title: 'Attendance',
      subtitle: DateFormat('EEE, d MMM yyyy').format(_date),
      drawerId: 'attendance',
      actions: [
        IconButton(
          onPressed: () => _openMarkDialog(),
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
          tooltip: 'Mark / adjust',
        ),
        IconButton(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          tooltip: 'Pick date',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Day navigation
            Row(
              children: [
                _dayBtn(Icons.chevron_left_rounded, () {
                  setState(() => _date = _date.subtract(const Duration(days: 1)));
                  _load();
                }),
                Expanded(
                  child: Center(
                    child: Text(
                      DateFormat('EEEE, d MMM').format(_date),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                _dayBtn(Icons.chevron_right_rounded, _date.day >= DateTime.now().day &&
                    _date.month >= DateTime.now().month &&
                    _date.year >= DateTime.now().year
                    ? null
                    : () {
                        setState(() => _date = _date.add(const Duration(days: 1)));
                        _load();
                      }),
              ],
            ),
            const SizedBox(height: 12),
            // 8 stat cards
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: [
                _statCard('Present', '$present', kSuccess),
                _statCard('Late', '$late', kWarning),
                _statCard('Absent', '$absent', kDanger),
                _statCard('Records', '$records', kPrimary),
                _statCard('On Leave', '$onLeave', Colors.purple),
                _statCard('No Out', '$missingOut', kDanger),
                _statCard('Half Day', '$halfDay', Colors.teal),
                _statCard('Headcount', '$headcount', kPrimary),
              ],
            ),
            const SizedBox(height: 12),
            // Search
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search employee…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final sel = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sel ? kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : kSubText)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: kPrimary)),
              )
            else if (_error != null)
              HrCard(child: Text(_error!, style: const TextStyle(color: kDanger)))
            else if (filtered.isEmpty)
              HrCard(
                child: Text(
                  _query.isNotEmpty || _filter != 'All'
                      ? 'No matching records'
                      : 'No records for this date. Tap + to mark attendance.',
                  style: const TextStyle(color: kSubTextLight),
                ),
              )
            else
              ...filtered.map((r) {
                final name = hrPersonName(r['employee'] ?? r['employeeName']);
                final status = '${r['status'] ?? '—'}';
                String timeOf(dynamic v) {
                  final s = '$v';
                  if (s == 'null' || s.isEmpty) return '—';
                  if (s.length >= 16) return s.substring(11, 16);
                  return s;
                }
                final checkInLabel = timeOf(r['checkIn']);
                final checkOutLabel = timeOf(r['checkOut']);
                final isLate = status == 'Late';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HrCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: kPrimary.withValues(alpha: 0.12),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(
                                'In ${isLate ? "⚠ " : ""}$checkInLabel · Out $checkOutLabel',
                                style: TextStyle(fontSize: 11, color: isLate ? kWarning : kSubTextLight),
                              ),
                            ],
                          ),
                        ),
                        HrStatusPill(status),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _openMarkDialog(existing: r),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Edit',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kPrimary)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _dayBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: onTap == null ? kBgLight : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: onTap == null ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(icon, size: 20, color: onTap == null ? kSubText : kPrimary),
    ),
  );

  Widget _statCard(String label, String value, Color color) => Container(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label,
          style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center),
      ],
    ),
  );
}

// ── Salary build (web /hr/payroll) ──────────────────────────────
class SalaryBuildScreen extends StatefulWidget {
  const SalaryBuildScreen({super.key});
  @override
  State<SalaryBuildScreen> createState() => _SalaryBuildScreenState();
}

class _SalaryBuildScreenState extends State<SalaryBuildScreen> {
  late String _period;
  String _payDate = '';
  bool _loading = true;
  bool _busy = false;
  bool _recalcWarn = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _settings = {};
  String _periodLabel = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        HrApiService.instance.payroll(period: _period),
        HrApiService.instance.settings(),
        HrApiService.instance.getPayrollRun(period: _period),
      ]);
      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      final cfg = results[1] as Map<String, dynamic>;
      final run = results[2] as Map<String, dynamic>;
      final allItems = (data['items'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _rows = allItems.where((r) => !_isSalesRow(r)).toList();
        _summary = Map<String, dynamic>.from(data['summary'] ?? {});
        _periodLabel = '${data['periodLabel'] ?? _period}';
        _period = '${data['period'] ?? _period}';
        _settings = cfg;
        _payDate = '${run['payDate'] ?? ''}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _doGenerate() async {
    setState(() { _busy = true; _recalcWarn = false; });
    try {
      final data = await HrApiService.instance.generatePayroll(period: _period, mode: 'office');
      if (!mounted) return;
      final allItems = (data['items'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _rows = allItems.where((r) => !_isSalesRow(r)).toList();
        _summary = Map<String, dynamic>.from(data['summary'] ?? {});
        _periodLabel = '${data['periodLabel'] ?? _period}';
        _busy = false;
      });
      await _hrSnack(context, '${_rows.length} office slips calculated');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _generate() async {
    final hasApproved = _rows.any((r) => r['status'] == 'Approved' || r['status'] == 'Paid');
    if (hasApproved && !_recalcWarn) {
      setState(() => _recalcWarn = true);
      await _hrSnack(context, 'Some slips are Approved/Paid — tap Calculate again to confirm override');
      return;
    }
    await _doGenerate();
  }

  Future<void> _bulk(String status) async {
    if (status == 'Paid' && _payDate.isEmpty) {
      await _hrSnack(context, 'Set a pay date first', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final data = await HrApiService.instance.bulkPayrollStatus(
        period: _period,
        status: status,
        payDate: _payDate.isNotEmpty ? _payDate : null,
        mode: 'office',
      );
      if (!mounted) return;
      final all = (data['items'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _rows = all.where((r) => !_isSalesRow(r)).toList();
        _summary = Map<String, dynamic>.from(data['summary'] ?? {});
        _busy = false;
      });
      await _hrSnack(context, status == 'Paid' ? 'Paid — loan balances updated' : 'Status updated to $status');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  String _pkr(dynamic n) {
    final v = n is num ? n : num.tryParse('$n') ?? 0;
    return 'Rs ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Future<void> _openEdit(Map<String, dynamic> row) async {
    final b = Map<String, dynamic>.from(row['breakdown'] is Map ? row['breakdown'] : {});
    final earn = Map<String, dynamic>.from(b['earnings'] is Map ? b['earnings'] : {});
    final ded = Map<String, dynamic>.from(b['deductions'] is Map ? b['deductions'] : {});
    final commPct = (_settings['salesCommissionPct'] as num?)?.toDouble() ?? 5.0;
    final eobiDefault = (_settings['eobiAmount'] as num?)?.toDouble() ?? 370.0;

    final cBasic = TextEditingController(text: '${earn['basic'] ?? row['base'] ?? 0}');
    final cHra = TextEditingController(text: '${earn['houseAllowance'] ?? 0}');
    final cTransport = TextEditingController(text: '${earn['transportAllowance'] ?? 0}');
    final cMedical = TextEditingController(text: '${earn['medicalAllowance'] ?? 0}');
    final cOt = TextEditingController(text: '${earn['overtime'] ?? row['overtime'] ?? 0}');
    final cBonus = TextEditingController(text: '${earn['bonus'] ?? 0}');
    final cCommission = TextEditingController(text: '${earn['commission'] ?? 0}');
    final cSales = TextEditingController(text: '${b['salesAmount'] ?? 0}');
    final cNoSale = TextEditingController(text: '${ded['noSaleCut'] ?? b['noSaleCut'] ?? 0}');
    final cAttCut = TextEditingController(text: '${ded['attendanceCut'] ?? ((ded['unpaidLeave'] ?? 0) + (ded['late'] ?? 0))}');
    final cLoan = TextEditingController(text: '${ded['loan'] ?? 0}');
    final cOther = TextEditingController(text: '${ded['otherCut'] ?? 0}');
    final cTax = TextEditingController(text: '${ded['incomeTax'] ?? ded['tax'] ?? 0}');
    final cEobi = TextEditingController(text: '${ded['eobi'] ?? eobiDefault}');
    final cPf = TextEditingController(text: '${ded['providentFund'] ?? 0}');
    final cNotes = TextEditingController(text: '${row['notes'] ?? ''}');

    final locked = row['status'] == 'Paid';
    final isOnProbation = b['isOnProbation'] == true;
    final proRata = (b['proRata'] as num?)?.toDouble() ?? 1.0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBgLight,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          double n(TextEditingController c) => double.tryParse(c.text) ?? 0;
          final totalAllowances = n(cHra) + n(cTransport) + n(cMedical);
          final liveGross = n(cBasic) + totalAllowances + n(cOt) + n(cBonus) + n(cCommission);
          final liveCuts = n(cAttCut) + n(cLoan) + n(cOther) + n(cNoSale) + n(cTax) + n(cEobi) + n(cPf);
          final liveNet = (liveGross - liveCuts).clamp(0, double.infinity);

          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.97,
            expand: false,
            builder: (_, scrollCtrl) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Column(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${row['employee'] ?? 'Employee'}',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                              Row(children: [
                                Text('${row['periodLabel'] ?? row['period'] ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                if (isOnProbation) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('Probation', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                                if (proRata < 0.99) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(6)),
                                    child: Text('${(proRata * 100).round()}% pro-rated', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ]),
                            ],
                          ),
                        ),
                        if (locked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                            child: const Text('PAID', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (!locked) ...[
                          _section('+ Earnings', [
                            _fld(ctx, '+ Basic salary', cBasic, setLocal),
                            _fld(ctx, '+ House rent allowance', cHra, setLocal),
                            _fld(ctx, '+ Transport allowance', cTransport, setLocal),
                            _fld(ctx, '+ Medical allowance', cMedical, setLocal),
                            _fld(ctx, '+ Overtime', cOt, setLocal),
                            _fld(ctx, '+ Bonus', cBonus, setLocal),
                          ]),
                          const SizedBox(height: 12),
                          _section('Sales / Commission (optional)', [
                            _fld(ctx, 'Sales amount (Rs)', cSales, setLocal),
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              child: GestureDetector(
                                onTap: () {
                                  final sales = double.tryParse(cSales.text) ?? 0;
                                  final comm = (sales * commPct / 100 * 100).round() / 100;
                                  setLocal(() { cCommission.text = '$comm'; });
                                },
                                child: Text('Auto commission = sales x $commPct%',
                                    style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            _fld(ctx, '+ Commission', cCommission, setLocal, green: true),
                            _fld(ctx, '- No-sale cut', cNoSale, setLocal, red: true),
                          ]),
                          const SizedBox(height: 12),
                          _section('- Deductions', [
                            _fld(ctx, '- Attendance cut', cAttCut, setLocal, red: true),
                            _fld(ctx, '- Loan installment', cLoan, setLocal, red: true),
                            _fld(ctx, '- Other deduction', cOther, setLocal, red: true),
                          ]),
                          const SizedBox(height: 12),
                          _section('Statutory (FBR / EOBI / PF)', [
                            _fld(ctx, '- Income tax (FBR slab)', cTax, setLocal, red: true),
                            _fld(ctx, '- EOBI employee (Rs ${eobiDefault.round()}/mo)', cEobi, setLocal, red: true),
                            _fld(ctx, '- Provident fund', cPf, setLocal, red: true),
                          ]),
                          const SizedBox(height: 12),
                          _section('Notes', [_fld(ctx, 'Notes', cNotes, setLocal, multiline: true)]),
                          const SizedBox(height: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Gross ${_pkr(liveGross)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('Cuts -${_pkr(liveCuts)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Net pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  Text(_pkr(liveNet), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!locked) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _saveSlip(ctx, row, {
                                'manual': true,
                                'basic': n(cBasic), 'houseAllowance': n(cHra), 'transportAllowance': n(cTransport),
                                'medicalAllowance': n(cMedical), 'allowances': totalAllowances,
                                'overtime': n(cOt), 'bonus': n(cBonus), 'commission': n(cCommission),
                                'salesAmount': n(cSales), 'noSaleCut': n(cNoSale),
                                'attendanceCut': n(cAttCut), 'loan': n(cLoan), 'otherCut': n(cOther),
                                'incomeTax': n(cTax), 'tax': n(cTax), 'eobi': n(cEobi), 'providentFund': n(cPf),
                                'notes': cNotes.text,
                              }),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary, foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Save changes', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _saveSlip(ctx, row, {
                                    'manual': true, 'status': 'Approved',
                                    'basic': n(cBasic), 'houseAllowance': n(cHra), 'transportAllowance': n(cTransport),
                                    'medicalAllowance': n(cMedical), 'allowances': totalAllowances,
                                    'overtime': n(cOt), 'bonus': n(cBonus), 'commission': n(cCommission),
                                    'salesAmount': n(cSales), 'noSaleCut': n(cNoSale),
                                    'attendanceCut': n(cAttCut), 'loan': n(cLoan), 'otherCut': n(cOther),
                                    'incomeTax': n(cTax), 'tax': n(cTax), 'eobi': n(cEobi), 'providentFund': n(cPf),
                                    'notes': cNotes.text,
                                  }),
                                  child: const Text('Save & Approve', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _saveSlip(ctx, row, {
                                    'manual': true, 'status': 'Paid',
                                    'basic': n(cBasic), 'houseAllowance': n(cHra), 'transportAllowance': n(cTransport),
                                    'medicalAllowance': n(cMedical), 'allowances': totalAllowances,
                                    'overtime': n(cOt), 'bonus': n(cBonus), 'commission': n(cCommission),
                                    'salesAmount': n(cSales), 'noSaleCut': n(cNoSale),
                                    'attendanceCut': n(cAttCut), 'loan': n(cLoan), 'otherCut': n(cOther),
                                    'incomeTax': n(cTax), 'tax': n(cTax), 'eobi': n(cEobi), 'providentFund': n(cPf),
                                    'notes': cNotes.text,
                                  }),
                                  style: ElevatedButton.styleFrom(backgroundColor: kSuccess, foregroundColor: Colors.white),
                                  child: const Text('Save & Paid', style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          const Center(child: Text('Paid slip is locked', style: TextStyle(color: kSubTextLight, fontWeight: FontWeight.w600))),
                        ],
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

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderLight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: kSubText, letterSpacing: 0.7)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _fld(BuildContext ctx, String label, TextEditingController c, void Function(void Function()) setLocal, {bool green = false, bool red = false, bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        onChanged: (_) => setLocal(() {}),
        keyboardType: multiline ? TextInputType.multiline : const TextInputType.numberWithOptions(decimal: true),
        maxLines: multiline ? 3 : 1,
        style: TextStyle(color: green ? Colors.green.shade700 : red ? Colors.red.shade700 : null),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 12, color: green ? Colors.green.shade700 : red ? Colors.red.shade700 : kSubText),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Future<void> _saveSlip(BuildContext ctx, Map<String, dynamic> row, Map<String, dynamic> payload) async {
    try {
      await HrApiService.instance.updatePayroll('${row['id']}', payload);
      if (ctx.mounted) Navigator.pop(ctx);
      await _load();
    } catch (e) {
      if (ctx.mounted) await _hrSnack(ctx, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPaid = _rows.isNotEmpty && _rows.every((r) => r['status'] == 'Paid');
    final hasApproved = _rows.any((r) => r['status'] == 'Approved');
    return HrAdminScaffold(
      title: 'Office payroll',
      subtitle: _periodLabel.isNotEmpty ? '$_periodLabel' : 'Non-sales staff salary',
      drawerId: 'payroll',
      actions: [
        IconButton(
          onPressed: _busy ? null : _generate,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(_recalcWarn ? Icons.warning_amber_rounded : Icons.play_arrow_rounded, color: Colors.white),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalesPayrollScreen())),
          icon: const Icon(Icons.emoji_events_rounded, color: Colors.white),
          tooltip: 'Sales payroll',
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Period + pay date picker
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: kBorderLight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Salary month', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kSubText)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            final picked = await _pickYearMonth(context, _period);
                            if (picked != null && picked != _period) {
                              setState(() { _period = picked; _rows = []; });
                              await _load();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: kBgLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderLight)),
                            child: Row(children: [
                              Icon(Icons.calendar_month_rounded, size: 16, color: kPrimary),
                              const SizedBox(width: 6),
                              Text(_period, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ]),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pay date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kSubText)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            final d = await _pickYmd(context);
                            if (d != null) {
                              setState(() => _payDate = d);
                              await HrApiService.instance.savePayrollRun({'period': _period, 'payDate': d});
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: kBgLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderLight)),
                            child: Row(children: [
                              Icon(Icons.event_rounded, size: 16, color: kSubText),
                              const SizedBox(width: 6),
                              Text(_payDate.isEmpty ? 'Pick date' : _payDate, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _payDate.isEmpty ? kSubText : null)),
                            ]),
                          ),
                        ),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Text('Tax: FBR slabs  EOBI: Rs ${(_settings['eobiAmount'] as num?)?.round() ?? 370}/mo  PF: ${_settings['pfPct'] ?? 0}%',
                      style: const TextStyle(fontSize: 10, color: kSubTextLight)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Stats
            Row(children: [
              HrStatChip(label: 'Employees', value: '${_summary['headcount'] ?? _rows.length}'),
              const SizedBox(width: 8),
              HrStatChip(label: 'Net payable', value: _pkr((_summary['net'] as num?) ?? 0), color: kSuccess),
              const SizedBox(width: 8),
              HrStatChip(label: 'Deductions', value: _pkr((_summary['deductions'] as num?) ?? 0), color: kDanger),
            ]),
            const SizedBox(height: 10),
            // Actions
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chipBtn(_recalcWarn ? 'Confirm recalculate' : (_rows.isEmpty ? 'Calculate' : 'Recalculate'), _generate, warning: _recalcWarn),
              _chipBtn('Approve all', () => _bulk('Approved'), disabled: allPaid),
              _chipBtn('Mark paid', () => _bulk('Paid'), disabled: !hasApproved),
            ]),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: kPrimary)))
            else if (_error != null)
              HrCard(child: Text(_error!, style: const TextStyle(color: kDanger)))
            else if (_rows.isEmpty)
              HrCard(child: Column(children: [
                Icon(Icons.calculate_rounded, size: 36, color: kSubText),
                const SizedBox(height: 8),
                const Text('Tap Calculate to build salaries from attendance, leave & loan data.', style: TextStyle(color: kSubTextLight), textAlign: TextAlign.center),
              ]))
            else
              ..._rows.map((r) {
                final b = Map<String, dynamic>.from(r['breakdown'] is Map ? r['breakdown'] : {});
                final earn = Map<String, dynamic>.from(b['earnings'] is Map ? b['earnings'] : {});
                final ded = Map<String, dynamic>.from(b['deductions'] is Map ? b['deductions'] : {});
                final commission = (earn['commission'] as num?) ?? 0;
                final cut = (ded['attendanceCut'] as num?) ?? (((ded['unpaidLeave'] as num?) ?? 0) + ((ded['late'] as num?) ?? 0));
                final incomeTax = (ded['incomeTax'] as num?) ?? (ded['tax'] as num?) ?? 0;
                final isOnProbation = b['isOnProbation'] == true;
                final proRata = (b['proRata'] as num?)?.toDouble() ?? 1.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _openEdit(r),
                    borderRadius: BorderRadius.circular(16),
                    child: HrCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text('${r['employee'] ?? 'Employee'}', style: const TextStyle(fontWeight: FontWeight.w800))),
                            HrStatusPill('${r['status'] ?? 'Draft'}'),
                          ]),
                          const SizedBox(height: 4),
                          Wrap(spacing: 6, children: [
                            if (isOnProbation) _badge('Probation', Colors.amber.shade700),
                            if (proRata < 0.99) _badge('${(proRata * 100).round()}% pro-rata', Colors.orange.shade700),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            'Basic ${_pkr(earn['basic'] ?? r['base'] ?? 0)}  Gross ${_pkr(earn['gross'] ?? 0)}  Cut -${_pkr(cut)}  Tax -${_pkr(incomeTax)}',
                            style: const TextStyle(fontSize: 11, color: kSubTextLight),
                          ),
                          const SizedBox(height: 6),
                          Text('Net ${_pkr((r['net'] as num?) ?? 0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimary)),
                          if (commission > 0)
                            Text('+Comm ${_pkr(commission)}', style: const TextStyle(fontSize: 11, color: kSuccess)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            if (allPaid)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_rounded, size: 14, color: kSuccess),
                  SizedBox(width: 4),
                  Text('All paid', style: TextStyle(color: kSuccess, fontWeight: FontWeight.w700, fontSize: 12)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
    );
  }

  Widget _chipBtn(String label, VoidCallback onTap, {bool warning = false, bool disabled = false}) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: warning ? Colors.orange.shade800 : null)),
      onPressed: (_busy || disabled) ? null : onTap,
      backgroundColor: warning ? Colors.orange.shade50 : Colors.white,
      side: BorderSide(color: warning ? Colors.orange.shade400 : kBorderLight),
    );
  }
}

// ── Helper: is this employee a sales/field person? ──────────────
bool _isSalesRow(Map<String, dynamic> r) {
  if (r['isSalesRole'] == true) return true;
  final typeStr = '${r['employeeType'] ?? ''} ${r['designation'] ?? ''}'.toLowerCase();
  return typeStr.contains('sales') || typeStr.contains('salesman');
}

// ────────────────────────────────────────────────────────────────
// SALES PAYROLL (separate screen for field/sales staff)
// ────────────────────────────────────────────────────────────────
class SalesPayrollScreen extends StatefulWidget {
  const SalesPayrollScreen({super.key});
  @override
  State<SalesPayrollScreen> createState() => _SalesPayrollScreenState();
}

class _SalesPayrollScreenState extends State<SalesPayrollScreen> {
  late String _period;
  String _payDate = '';
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _settings = {};
  String _periodLabel = '';
  double _commissionPct = 5.0;
  double _noSaleCutDefault = 0.0;
  final Map<String, String> _draftSales = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        HrApiService.instance.payroll(period: _period),
        HrApiService.instance.settings(),
      ]);
      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      final cfg = results[1] as Map<String, dynamic>;
      final allItems = (data['items'] as List).cast<Map<String, dynamic>>();
      final salesRows = allItems.where((r) => _isSalesRow(r)).toList();
      setState(() {
        _rows = salesRows;
        _summary = Map<String, dynamic>.from(data['summary'] ?? {});
        _periodLabel = '${data['periodLabel'] ?? _period}';
        _period = '${data['period'] ?? _period}';
        _settings = cfg;
        _commissionPct = (cfg['salesCommissionPct'] as num?)?.toDouble() ?? 5.0;
        _noSaleCutDefault = (cfg['noSaleCutAmount'] as num?)?.toDouble() ?? 0.0;
        for (final r in salesRows) {
          final b = r['breakdown'] is Map ? Map<String, dynamic>.from(r['breakdown'] as Map) : <String, dynamic>{};
          _draftSales['${r['id']}'] = '${b['salesAmount'] ?? 0}';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _calculate() async {
    setState(() => _busy = true);
    try {
      final data = await HrApiService.instance.generatePayroll(period: _period, mode: 'sales');
      if (!mounted) return;
      final allItems = (data['items'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _rows = allItems.where((r) => _isSalesRow(r)).toList();
        _summary = Map<String, dynamic>.from(data['summary'] ?? {});
        _periodLabel = '${data['periodLabel'] ?? _period}';
        for (final r in _rows) {
          final b = r['breakdown'] is Map ? Map<String, dynamic>.from(r['breakdown'] as Map) : <String, dynamic>{};
          _draftSales['${r['id']}'] = '${b['salesAmount'] ?? 0}';
        }
        _busy = false;
      });
      await _hrSnack(context, 'Sales payroll calculated');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _saveSalesRow(Map<String, dynamic> row) async {
    final id = '${row['id']}';
    final sales = double.tryParse(_draftSales[id] ?? '0') ?? 0;
    final b = row['breakdown'] is Map ? Map<String, dynamic>.from(row['breakdown'] as Map) : <String, dynamic>{};
    final earn = b['earnings'] is Map ? Map<String, dynamic>.from(b['earnings'] as Map) : <String, dynamic>{};
    final ded = b['deductions'] is Map ? Map<String, dynamic>.from(b['deductions'] as Map) : <String, dynamic>{};
    final commission = (sales * _commissionPct / 100 * 100).round() / 100;
    final noSaleCut = (sales > 0 || commission > 0) ? 0.0 : _noSaleCutDefault;
    try {
      final updated = await HrApiService.instance.updatePayroll(id, {
        'manual': true, 'autoCommission': true,
        'salesAmount': sales, 'commission': commission, 'noSaleCut': noSaleCut,
        'basic': (earn['basic'] as num?) ?? 0,
        'houseAllowance': (earn['houseAllowance'] as num?) ?? 0,
        'transportAllowance': (earn['transportAllowance'] as num?) ?? 0,
        'medicalAllowance': (earn['medicalAllowance'] as num?) ?? 0,
        'overtime': (earn['overtime'] as num?) ?? 0,
        'bonus': (earn['bonus'] as num?) ?? 0,
        'attendanceCut': (ded['attendanceCut'] as num?) ?? 0,
        'loan': (ded['loan'] as num?) ?? 0,
        'otherCut': (ded['otherCut'] as num?) ?? 0,
        'incomeTax': (ded['incomeTax'] as num?) ?? (ded['tax'] as num?) ?? 0,
        'tax': (ded['incomeTax'] as num?) ?? (ded['tax'] as num?) ?? 0,
        'eobi': (ded['eobi'] as num?) ?? 0,
        'providentFund': (ded['providentFund'] as num?) ?? 0,
        'notes': sales > 0 ? 'Sales Rs ${sales.round()} -> comm Rs ${commission.round()} ($_commissionPct%)' : 'No sales this period',
      });
      if (!mounted) return;
      setState(() {
        final idx = _rows.indexWhere((r) => r['id'] == id);
        if (idx >= 0) _rows[idx] = updated;
      });
      await _hrSnack(context, '${row['employee']}: saved');
    } catch (e) {
      if (mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _bulk(String status) async {
    if (status == 'Paid' && _payDate.isEmpty) {
      await _hrSnack(context, 'Set a pay date first', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final data = await HrApiService.instance.bulkPayrollStatus(
        period: _period, status: status,
        payDate: _payDate.isNotEmpty ? _payDate : null,
        mode: 'sales',
      );
      if (!mounted) return;
      final all = (data['items'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _rows = all.where((r) => _isSalesRow(r)).toList();
        _summary = Map<String, dynamic>.from(data['summary'] ?? {});
        _busy = false;
      });
      await _hrSnack(context, status == 'Paid' ? 'Paid - loans updated' : 'Status updated to $status');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  String _pkr(dynamic n) {
    final v = n is num ? n : num.tryParse('$n') ?? 0;
    return 'Rs ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalComm = _rows.fold(0.0, (s, r) {
      final b = r['breakdown'] is Map ? Map<String, dynamic>.from(r['breakdown'] as Map) : <String, dynamic>{};
      final earn = b['earnings'] is Map ? Map<String, dynamic>.from(b['earnings'] as Map) : <String, dynamic>{};
      return s + ((earn['commission'] as num?) ?? 0).toDouble();
    });
    final totalNet = _rows.fold(0.0, (s, r) => s + ((r['net'] as num?) ?? 0).toDouble());
    final hasApproved = _rows.any((r) => r['status'] == 'Approved');

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          Container(
            color: kPrimary,
            child: SafeArea(bottom: false, child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Sales payroll', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(_periodLabel.isNotEmpty ? '$_periodLabel - ${_rows.length} sales staff' : 'Basic + commission',
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ])),
                if (_busy)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                else
                  IconButton(onPressed: _calculate, icon: const Icon(Icons.play_arrow_rounded, color: Colors.white)),
              ]),
            )),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: kPrimary,
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
                // Period picker
                GestureDetector(
                  onTap: () async {
                    final picked = await _pickYearMonth(context, _period);
                    if (picked != null && picked != _period) {
                      setState(() { _period = picked; _rows = []; });
                      await _load();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorderLight)),
                    child: Row(children: [
                      Icon(Icons.calendar_month_rounded, size: 16, color: kPrimary),
                      const SizedBox(width: 8),
                      Text(_period, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      const Spacer(),
                      Text('Comm: $_commissionPct%   No-sale cut: ${_pkr(_noSaleCutDefault)}', style: const TextStyle(fontSize: 11, color: kSubTextLight)),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                // Stats
                Row(children: [
                  HrStatChip(label: 'Sales staff', value: '${_rows.length}'),
                  const SizedBox(width: 8),
                  HrStatChip(label: 'Commission', value: _pkr(totalComm), color: kSuccess),
                  const SizedBox(width: 8),
                  HrStatChip(label: 'Net payable', value: _pkr(totalNet), color: kPrimary),
                ]),
                const SizedBox(height: 10),
                // Pay date + bulk actions
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () async {
                      final d = await _pickYmd(context);
                      if (d != null) {
                        setState(() => _payDate = d);
                        await HrApiService.instance.savePayrollRun({'period': _period, 'payDate': d});
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderLight)),
                      child: Row(children: [
                        Icon(Icons.event_rounded, size: 15, color: kSubText),
                        const SizedBox(width: 6),
                        Text(_payDate.isEmpty ? 'Pay date' : _payDate, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _payDate.isEmpty ? kSubText : null)),
                      ]),
                    ),
                  )),
                  const SizedBox(width: 8),
                  ActionChip(label: const Text('Approve all', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    onPressed: _busy ? null : () => _bulk('Approved'), backgroundColor: Colors.white, side: const BorderSide(color: kBorderLight)),
                  const SizedBox(width: 6),
                  ActionChip(label: const Text('Mark paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: kSuccess)),
                    onPressed: (_busy || !hasApproved) ? null : () => _bulk('Paid'), backgroundColor: Colors.white, side: const BorderSide(color: kBorderLight)),
                ]),
                const SizedBox(height: 12),
                if (_loading)
                  const Center(child: CircularProgressIndicator(color: kPrimary))
                else if (_error != null)
                  HrCard(child: Text(_error!, style: const TextStyle(color: kDanger)))
                else if (_rows.isEmpty)
                  HrCard(child: Column(children: [
                    Icon(Icons.storefront_rounded, size: 36, color: kSubText),
                    const SizedBox(height: 8),
                    const Text('No sales staff found. Tap Calculate or ensure employees are tagged as Salesman / Sales.', style: TextStyle(color: kSubTextLight), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    TextButton.icon(onPressed: _calculate, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Calculate now')),
                  ]))
                else
                  ..._rows.map((row) {
                    final id = '${row['id']}';
                    final b = row['breakdown'] is Map ? Map<String, dynamic>.from(row['breakdown'] as Map) : <String, dynamic>{};
                    final earn = b['earnings'] is Map ? Map<String, dynamic>.from(b['earnings'] as Map) : <String, dynamic>{};
                    final basic = (earn['basic'] as num?) ?? (row['salary'] as num?) ?? 0;
                    final comm = (earn['commission'] as num?) ?? 0;
                    final locked = row['status'] == 'Paid';
                    final draft = _draftSales[id] ?? '${b['salesAmount'] ?? 0}';
                    final liveComm = (double.tryParse(draft) ?? 0) * _commissionPct / 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: HrCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text('${row['employee'] ?? 'Employee'}', style: const TextStyle(fontWeight: FontWeight.w800))),
                          HrStatusPill('${row['status'] ?? 'Draft'}'),
                        ]),
                        const SizedBox(height: 4),
                        Text('${row['employeeType'] ?? 'Sales'}  Basic ${_pkr(basic)}', style: const TextStyle(fontSize: 11, color: kSubTextLight)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: TextField(
                              enabled: !locked,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              controller: TextEditingController.fromValue(TextEditingValue(
                                text: draft, selection: TextSelection.collapsed(offset: draft.length),
                              )),
                              onChanged: (v) => setState(() => _draftSales[id] = v),
                              decoration: InputDecoration(
                                labelText: 'Sales amount (Rs)',
                                labelStyle: const TextStyle(fontSize: 12),
                                filled: true, fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                suffixText: '-> ${_pkr(liveComm)}',
                                suffixStyle: const TextStyle(color: kSuccess, fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!locked)
                            ElevatedButton(
                              onPressed: () => _saveSalesRow(row),
                              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
                              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            ),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: kSuccess.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('+Comm ${_pkr(locked ? comm : liveComm)}', style: const TextStyle(fontSize: 11, color: kSuccess, fontWeight: FontWeight.w700))),
                          const SizedBox(width: 6),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('Net ${_pkr((row['net'] as num?) ?? 0)}', style: const TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w700))),
                        ]),
                      ])),
                    );
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Year-month picker dialog ────────────────────────────────────
Future<String?> _pickYearMonth(BuildContext context, String current) async {
  final parts = current.split('-');
  int year = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? DateTime.now().year;
  int month = int.tryParse(parts.length > 1 ? parts[1] : '') ?? DateTime.now().month;
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
      title: const Text('Select month'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setLocal(() { year--; })),
          Text('$year', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setLocal(() { year++; })),
        ]),
        GridView.count(shrinkWrap: true, crossAxisCount: 4, childAspectRatio: 1.5,
          children: List.generate(12, (i) => InkWell(
            onTap: () => setLocal(() => month = i + 1),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: month == i + 1 ? kPrimary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text(months[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: month == i + 1 ? Colors.white : null))),
            ),
          ))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, '$year-${month.toString().padLeft(2, '0')}'), child: const Text('Select')),
      ],
    )),
  );
}

Future<void> _hrSnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return Future.value();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : null,
    ),
  );
  return Future.value();
}

Future<String?> _pickYmd(BuildContext context, {DateTime? initial}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2024),
    lastDate: DateTime.now().add(const Duration(days: 730)),
  );
  if (picked == null) return null;
  return DateFormat('yyyy-MM-dd').format(picked);
}

// ── Module screens mirroring web nav ────────────────────────────
class LeaveManagementAdminScreen extends StatelessWidget {
  const LeaveManagementAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Leave Management',
      subtitle: 'Approve, reject, or record leave',
      drawerId: 'leave',
      loader: () => HrApiService.instance.leaves(),
      titleOf: (r) => hrPersonName(r['employee'] ?? r['employeeName']),
      subtitleOf: (r) =>
          '${hrField(r, ['type'], 'Leave')} · ${hrField(r, ['from', 'fromDate'])} → ${hrField(r, ['to', 'toDate'])}',
      statusOf: (r) => hrField(r, ['status'], 'Pending'),
      onStatus: (r, status) => HrApiService.instance.updateLeave('${r['id']}', status),
      onCreate: () => _promptRecordLeave(context),
      emptyIcon: Icons.beach_access_rounded,
    );
  }

  Future<void> _promptRecordLeave(BuildContext context) async {
    final employees = await HrApiService.instance.employees();
    final types = await HrApiService.instance.leaveTypes();
    if (!context.mounted) return;
    if (employees.isEmpty) {
      await _hrSnack(context, 'No employees found', error: true);
      return;
    }
    String? employeeId = '${employees.first['id']}';
    String typeName = types.isNotEmpty
        ? hrField(types.first, ['name'], 'Casual Leave')
        : 'Casual Leave';
    String? leaveTypeId =
        types.isNotEmpty ? '${types.first['id']}' : null;
    final from = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final to = TextEditingController(text: from.text);
    final reason = TextEditingController();
    final typeOptions = types.isNotEmpty
        ? types
            .map((t) => hrField(t, ['name'], 'Leave'))
            .toSet()
            .toList()
        : ['Casual Leave', 'Sick Leave', 'Annual Leave', 'Emergency Leave'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Record leave'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: employeeId,
                  decoration: const InputDecoration(labelText: 'Employee'),
                  items: employees
                      .map(
                        (e) => DropdownMenuItem(
                          value: '${e['id']}',
                          child: Text(hrPersonName(e['name'] ?? e)),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => employeeId = v),
                ),
                DropdownButtonFormField<String>(
                  value: typeName,
                  decoration: const InputDecoration(labelText: 'Leave type'),
                  items: typeOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() {
                      typeName = v;
                      leaveTypeId = null;
                      for (final t in types) {
                        if (hrField(t, ['name']) == v) {
                          leaveTypeId = '${t['id']}';
                          break;
                        }
                      }
                    });
                  },
                ),
                TextField(
                  controller: from,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'From'),
                  onTap: () async {
                    final d = await _pickYmd(ctx);
                    if (d != null) setLocal(() => from.text = d);
                  },
                ),
                TextField(
                  controller: to,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'To'),
                  onTap: () async {
                    final d = await _pickYmd(ctx);
                    if (d != null) setLocal(() => to.text = d);
                  },
                ),
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || employeeId == null) return;
    try {
      await HrApiService.instance.createLeave({
        'employeeId': employeeId,
        'type': typeName,
        if (leaveTypeId != null) 'leaveTypeId': leaveTypeId,
        'from': from.text.trim(),
        'to': to.text.trim(),
        'reason': reason.text.trim(),
      });
      if (context.mounted) await _hrSnack(context, 'Leave recorded');
    } catch (e) {
      if (context.mounted) {
        await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }
}

class OvertimeAdminScreen extends StatelessWidget {
  const OvertimeAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Overtime',
      subtitle: 'Approve OT before salary build · HR can also record',
      drawerId: 'overtime',
      loader: () => HrApiService.instance.overtime(),
      titleOf: (r) => hrPersonName(r['employee']),
      subtitleOf: (r) {
        final amount = r['amount'] ?? ((r['hours'] is num && r['rate'] is num)
            ? (r['hours'] as num) * (r['rate'] as num)
            : 0);
        final reason = hrField(r, ['reason', 'notes'], '');
        return '${hrField(r, ['hours'], '0')} hrs · ${hrField(r, ['date', 'workDate'])} · ${hrMoney(amount)}${reason.isNotEmpty ? ' · $reason' : ''}';
      },
      statusOf: (r) => hrField(r, ['status'], 'Pending'),
      onStatus: (r, status) => HrApiService.instance.updateOvertime('${r['id']}', status),
      onCreate: () => _promptRecord(context),
      emptyIcon: Icons.more_time_rounded,
    );
  }

  Future<void> _promptRecord(BuildContext context) async {
    final employees = await HrApiService.instance.employees();
    if (!context.mounted) return;
    if (employees.isEmpty) { await _hrSnack(context, 'No employees', error: true); return; }
    String? employeeId = '${employees.first['id']}';
    final hours = TextEditingController(text: '2');
    final date = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final reason = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Record overtime'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: employeeId,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: employees.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text(hrPersonName(e['name'] ?? e)))).toList(),
              onChanged: (v) => setLocal(() => employeeId = v),
            ),
            const SizedBox(height: 10),
            TextField(controller: hours, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'OT hours', suffixText: 'hrs')),
            const SizedBox(height: 10),
            TextField(controller: date, readOnly: true, decoration: const InputDecoration(labelText: 'Date'),
              onTap: () async {
                final d = await _pickYmd(ctx);
                if (d != null) setLocal(() => date.text = d);
              }),
            const SizedBox(height: 10),
            TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (ok != true || employeeId == null) return;
    final h = double.tryParse(hours.text.trim()) ?? 0;
    if (h <= 0) { if (context.mounted) await _hrSnack(context, 'Enter valid hours', error: true); return; }
    try {
      await HrApiService.instance.requestOvertime(hours: h, date: date.text.trim(), reason: reason.text.trim());
      if (context.mounted) await _hrSnack(context, 'OT recorded');
    } catch (e) {
      if (context.mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
}

class HolidaysAdminScreen extends StatelessWidget {
  const HolidaysAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Holidays',
      subtitle: 'Company holiday calendar',
      drawerId: 'holidays',
      loader: () => HrApiService.instance.holidayCalendar(),
      titleOf: (r) => '${r['name'] ?? 'Holiday'}',
      subtitleOf: (r) => '${hrShortDate(r['date'])} · ${r['type'] ?? 'Public'}',
      statusOf: (r) => r['optional'] == true ? 'Optional' : 'Public',
      onCreate: () => _promptHoliday(context),
      emptyIcon: Icons.celebration_rounded,
    );
  }

  Future<void> _promptHoliday(BuildContext context) async {
    final name = TextEditingController();
    final date = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    String type = 'Public';
    bool optional = false;
    const types = ['Public', 'National', 'Religious', 'Company'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add holiday'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                controller: date,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date'),
                onTap: () async {
                  final d = await _pickYmd(ctx);
                  if (d != null) setLocal(() => date.text = d);
                },
              ),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setLocal(() => type = v ?? type),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Optional holiday'),
                value: optional,
                onChanged: (v) => setLocal(() => optional = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await HrApiService.instance.saveHoliday({
        'name': name.text.trim(),
        'date': date.text.trim(),
        'type': type,
        'optional': optional,
      });
      if (context.mounted) await _hrSnack(context, 'Holiday saved');
    } catch (e) {
      if (context.mounted) {
        await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }
}

class ShiftsAdminScreen extends StatelessWidget {
  const ShiftsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Shifts',
      subtitle: 'Working hours · grace · night / flexible',
      drawerId: 'shifts',
      loader: () => HrApiService.instance.shiftPlans(),
      titleOf: (r) => '${r['name'] ?? 'Shift'}',
      subtitleOf: (r) {
        final flags = <String>[
          if (r['isNight'] == true) 'Night',
          if (r['isFlexible'] == true) 'Flexible',
        ];
        final flagText = flags.isEmpty ? 'Day' : flags.join(' · ');
        return '${r['startTime'] ?? ''} – ${r['endTime'] ?? ''} · grace ${r['graceMinutes'] ?? 15}m · $flagText';
      },
      statusOf: (r) => r['isNight'] == true ? 'Night' : (r['isFlexible'] == true ? 'Flexible' : 'Fixed'),
      onCreate: () => _promptShift(context),
      emptyIcon: Icons.schedule_rounded,
    );
  }

  Future<void> _promptShift(BuildContext context) async {
    final name = TextEditingController(text: 'General');
    final start = TextEditingController(text: '09:00');
    final end = TextEditingController(text: '18:00');
    final grace = TextEditingController(text: '15');
    final breakMins = TextEditingController(text: '60');
    final otAfter = TextEditingController(text: '8');
    bool isNight = false;
    bool isFlexible = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add shift'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(controller: start, decoration: const InputDecoration(labelText: 'Start HH:mm')),
                TextField(controller: end, decoration: const InputDecoration(labelText: 'End HH:mm')),
                TextField(
                  controller: grace,
                  decoration: const InputDecoration(labelText: 'Grace minutes'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: breakMins,
                  decoration: const InputDecoration(labelText: 'Break minutes'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: otAfter,
                  decoration: const InputDecoration(labelText: 'OT after (hours)'),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Night shift'),
                  value: isNight,
                  onChanged: (v) => setLocal(() => isNight = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Flexible'),
                  value: isFlexible,
                  onChanged: (v) => setLocal(() => isFlexible = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await HrApiService.instance.saveShiftPlan({
        'name': name.text.trim(),
        'startTime': start.text.trim(),
        'endTime': end.text.trim(),
        'graceMinutes': int.tryParse(grace.text) ?? 15,
        'breakMinutes': int.tryParse(breakMins.text) ?? 60,
        'overtimeAfterHours': double.tryParse(otAfter.text) ?? 8,
        'isNight': isNight,
        'isFlexible': isFlexible,
        'workingDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      });
      if (context.mounted) await _hrSnack(context, 'Shift saved');
    } catch (e) {
      if (context.mounted) {
        await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }
}

/// Kept for any old routes — same as Shifts.
class ShiftPlansAdminScreen extends StatelessWidget {
  const ShiftPlansAdminScreen({super.key});

  @override
  Widget build(BuildContext context) => const ShiftsAdminScreen();
}

class DepartmentsAdminScreen extends StatelessWidget {
  const DepartmentsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Departments',
      subtitle: 'Org structure · departments & designations',
      drawerId: 'departments',
      loader: () async {
        final deps = await HrApiService.instance.departments();
        final des = await HrApiService.instance.designations();
        return [
          ...deps.map((d) => {...d, '_kind': 'Department'}),
          ...des.map((d) => {...d, '_kind': 'Designation'}),
        ];
      },
      titleOf: (r) => hrField(r, ['name'], 'Item'),
      subtitleOf: (r) {
        if (r['_kind'] == 'Designation') {
          return 'Designation · level ${hrField(r, ['level'], '—')}';
        }
        return 'Department · ${hrField(r, ['headcount'], '0')} people · ${hrField(r, ['costCenter'], '—')}';
      },
      statusOf: (r) => '${r['_kind'] ?? ''}',
      onCreate: () => _promptDept(context),
      emptyIcon: Icons.account_tree_rounded,
    );
  }

  Future<void> _promptDept(BuildContext context) async {
    String kind = 'Department';
    final name = TextEditingController();
    final costCenter = TextEditingController();
    final level = TextEditingController(text: '1');
    final parentDept = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add department / designation'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'Department', child: Text('Department')),
                DropdownMenuItem(value: 'Designation', child: Text('Designation')),
              ],
              onChanged: (v) => setLocal(() => kind = v ?? kind),
            ),
            const SizedBox(height: 10),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
            if (kind == 'Department') ...[
              const SizedBox(height: 10),
              TextField(controller: costCenter, decoration: const InputDecoration(labelText: 'Cost center (optional)')),
            ],
            if (kind == 'Designation') ...[
              const SizedBox(height: 10),
              TextField(controller: level, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Level (1 = entry, 5 = senior)', suffixText: 'lvl')),
              const SizedBox(height: 10),
              TextField(controller: parentDept, decoration: const InputDecoration(labelText: 'Department (optional)')),
            ],
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      if (kind == 'Department') {
        await HrApiService.instance.saveDepartment({
          'name': name.text.trim(),
          if (costCenter.text.trim().isNotEmpty) 'costCenter': costCenter.text.trim(),
        });
      } else {
        await HrApiService.instance.saveDesignation({
          'name': name.text.trim(),
          'level': int.tryParse(level.text) ?? 1,
          if (parentDept.text.trim().isNotEmpty) 'department': parentDept.text.trim(),
        });
      }
      if (context.mounted) await _hrSnack(context, '$kind saved');
    } catch (e) {
      if (context.mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
}

class LeavePoliciesAdminScreen extends StatelessWidget {
  const LeavePoliciesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Leave Policies',
      subtitle: 'Leave types · quotas · carry / encash',
      drawerId: 'leave_policies',
      loader: () => HrApiService.instance.leaveTypes(),
      titleOf: (r) => hrField(r, ['name', 'type'], 'Leave type'),
      subtitleOf: (r) {
        final bits = <String>[
          'Quota ${hrField(r, ['annualQuota', 'quota'], '—')}',
          if (r['carryForward'] == true) 'Carry',
          if (r['encashable'] == true) 'Encash',
        ];
        return bits.join(' · ');
      },
      statusOf: (r) => r['paid'] == false ? 'Unpaid' : 'Paid',
      onCreate: () => _prompt(context),
    );
  }

  Future<void> _prompt(BuildContext context) async {
    final name = TextEditingController();
    final quota = TextEditingController(text: '14');
    String unit = 'day';
    bool paid = true;
    bool carry = false;
    bool encash = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add leave type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                  controller: quota,
                  decoration: const InputDecoration(labelText: 'Annual quota'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Day')),
                    DropdownMenuItem(value: 'hour', child: Text('Hour')),
                  ],
                  onChanged: (v) => setLocal(() => unit = v ?? unit),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Paid'),
                  value: paid,
                  onChanged: (v) => setLocal(() => paid = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Carry forward'),
                  value: carry,
                  onChanged: (v) => setLocal(() => carry = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Encashable'),
                  value: encash,
                  onChanged: (v) => setLocal(() => encash = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    try {
      await HrApiService.instance.saveLeaveType({
        'name': name.text.trim(),
        'annualQuota': int.tryParse(quota.text) ?? 14,
        'unit': unit,
        'paid': paid,
        'carryForward': carry,
        'encashable': encash,
      });
      if (context.mounted) await _hrSnack(context, 'Leave type saved');
    } catch (e) {
      if (context.mounted) {
        await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }
}

class RosterAdminScreen extends StatefulWidget {
  const RosterAdminScreen({super.key});
  @override
  State<RosterAdminScreen> createState() => _RosterAdminScreenState();
}

class _RosterAdminScreenState extends State<RosterAdminScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  DateTime _from = DateTime.now().subtract(const Duration(days: 3));
  DateTime _to = DateTime.now().add(const Duration(days: 14));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final rows = await HrApiService.instance.roster(
        from: fmt.format(_from), to: fmt.format(_to),
      );
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HrAdminScaffold(
      title: 'Roster',
      subtitle: 'Shift assignments by date',
      drawerId: 'roster',
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () => _promptAssign(context),
        ),
      ],
      body: Column(
        children: [
          // Date range picker bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Expanded(child: GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _from, firstDate: DateTime(2024), lastDate: _to);
                  if (d != null) { setState(() => _from = d); _load(); }
                },
                child: _dateChip('From', DateFormat('dd MMM').format(_from)),
              )),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: _to, firstDate: _from, lastDate: DateTime(2026, 12, 31));
                  if (d != null) { setState(() => _to = d); _load(); }
                },
                child: _dateChip('To', DateFormat('dd MMM').format(_to)),
              )),
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('This week', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  final now = DateTime.now();
                  final mon = now.subtract(Duration(days: now.weekday - 1));
                  setState(() { _from = mon; _to = mon.add(const Duration(days: 6)); });
                  _load();
                },
                backgroundColor: Colors.white,
                side: const BorderSide(color: kBorderLight),
              ),
            ]),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: kPrimary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimary))
                  : _error != null
                      ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
                      : _rows.isEmpty
                          ? const Center(child: Text('No roster entries. Tap + to assign shifts.', style: TextStyle(color: kSubTextLight)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _rows.length,
                              itemBuilder: (_, i) {
                                final r = _rows[i];
                                final shift = r['shiftName'] ?? r['shift'] ?? 'Shift';
                                final date = hrShortDate(r['workDate'] ?? r['date']);
                                final start = r['startTime'] ?? '';
                                final end = r['endTime'] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: HrCard(child: Row(children: [
                                    Container(
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Center(child: Text(date.substring(8).trim(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPrimary))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(hrPersonName(r['employee'] ?? r['employeeName']), style: const TextStyle(fontWeight: FontWeight.w800)),
                                      Text('$shift${start.isNotEmpty ? '  $start–$end' : ''}', style: const TextStyle(fontSize: 11)),
                                    ])),
                                    HrStatusPill(hrField(r, ['status'], 'Scheduled')),
                                  ])),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: kBgLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: kBorderLight)),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 14, color: kPrimary),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 9, color: kSubTextLight, fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ]),
      ]),
    );
  }

  Future<void> _promptAssign(BuildContext context) async {
    final employees = await HrApiService.instance.employees();
    final shifts = await HrApiService.instance.shiftPlans();
    if (!context.mounted) return;
    if (employees.isEmpty || shifts.isEmpty) {
      await _hrSnack(context, employees.isEmpty ? 'No employees found' : 'Create a shift plan first', error: true);
      return;
    }
    String? employeeId = '${employees.first['id']}';
    String? shiftId = '${shifts.first['id']}';
    final workDate = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Assign shift'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: employeeId,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: employees.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text(hrPersonName(e['name'] ?? e)))).toList(),
              onChanged: (v) => setLocal(() => employeeId = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: shiftId,
              decoration: const InputDecoration(labelText: 'Shift'),
              items: shifts.map((s) => DropdownMenuItem(value: '${s['id']}', child: Text('${s['name'] ?? 'Shift'} (${s['startTime'] ?? ''}–${s['endTime'] ?? ''})'))).toList(),
              onChanged: (v) => setLocal(() => shiftId = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: workDate, readOnly: true,
              decoration: const InputDecoration(labelText: 'Work date'),
              onTap: () async {
                final d = await _pickYmd(ctx);
                if (d != null) setLocal(() => workDate.text = d);
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Assign')),
          ],
        ),
      ),
    );
    if (ok != true || employeeId == null || shiftId == null) return;
    try {
      await HrApiService.instance.saveRoster({
        'employeeId': employeeId, 'shiftId': shiftId,
        'workDate': workDate.text.trim(),
        if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
      });
      if (context.mounted) { await _hrSnack(context, 'Shift assigned'); _load(); }
    } catch (e) {
      if (context.mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
}

// ── Loans & Advances ─────────────────────────────────────────────
class LoansAdminScreen extends StatelessWidget {
  const LoansAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Loans & Advances',
      subtitle: 'Recovery auto-deducted on salary build',
      drawerId: 'loans',
      loader: () => HrApiService.instance.loans(),
      titleOf: (r) => hrPersonName(r['employee']),
      subtitleOf: (r) {
        final kind = hrField(r, ['kind'], 'loan');
        final amt = hrMoney(r['amount']);
        final monthly = hrMoney(r['monthlyDeduct']);
        final remaining = r['remaining'];
        return '$kind  $amt  $monthly/month${remaining != null ? '  remaining: ${hrMoney(remaining)}' : ''}';
      },
      statusOf: (r) => hrField(r, ['status'], 'Pending'),
      onStatus: (r, status) => HrApiService.instance.updateLoan('${r['id']}', status),
      onCreate: () => _promptCreate(context),
      emptyIcon: Icons.account_balance_rounded,
    );
  }

  Future<void> _promptCreate(BuildContext context) async {
    final employees = await HrApiService.instance.employees();
    if (!context.mounted) return;
    if (employees.isEmpty) { await _hrSnack(context, 'No employees found', error: true); return; }
    String? employeeId = '${employees.first['id']}';
    String kind = 'advance';
    final amount = TextEditingController();
    final installments = TextEditingController(text: '3');
    final reason = TextEditingController();
    const kinds = ['advance', 'loan', 'emergency', 'other'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New loan / advance'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: employeeId,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: employees.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text(hrPersonName(e['name'] ?? e)))).toList(),
              onChanged: (v) => setLocal(() => employeeId = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: kind,
              decoration: const InputDecoration(labelText: 'Type'),
              items: kinds.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (v) => setLocal(() => kind = v ?? kind),
            ),
            const SizedBox(height: 10),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs)', prefixText: 'Rs ')),
            const SizedBox(height: 10),
            TextField(controller: installments, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Installments (months)', suffixText: 'months')),
            const SizedBox(height: 10),
            TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 2),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (ok != true || employeeId == null) return;
    final amt = double.tryParse(amount.text.trim()) ?? 0;
    final inst = int.tryParse(installments.text.trim()) ?? 1;
    if (amt <= 0) { if (context.mounted) await _hrSnack(context, 'Enter a valid amount', error: true); return; }
    try {
      await HrApiService.instance.saveLoan({
        'employeeId': employeeId, 'kind': kind,
        'amount': amt, 'installments': inst,
        'reason': reason.text.trim(),
      });
      if (context.mounted) await _hrSnack(context, 'Loan submitted for approval');
    } catch (e) {
      if (context.mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
}

// ── Bonuses ───────────────────────────────────────────────────────
class BonusesAdminScreen extends StatelessWidget {
  const BonusesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Bonuses',
      subtitle: 'Sales commission auto-calculated from Settings %',
      drawerId: 'bonuses',
      notice: 'Kind = sales → enter sales amount; commission % auto-calculated from HR Settings. Approve, then run Payroll Calculate.',
      loader: () => HrApiService.instance.bonuses(),
      titleOf: (r) => hrPersonName(r['employee']),
      subtitleOf: (r) {
        final kind = hrField(r, ['kind'], 'bonus');
        final amount = hrMoney(r['amount']);
        final salesAmt = r['salesAmount'];
        final period = hrField(r, ['period', 'month']);
        if (salesAmt != null && salesAmt != 0) {
          return '$kind · Sales ${hrMoney(salesAmt)} → Comm $amount · $period';
        }
        return '$kind · $amount · $period';
      },
      statusOf: (r) => hrField(r, ['status'], 'Pending'),
      onStatus: (r, status) => HrApiService.instance.updateBonus('${r['id']}', status),
      onCreate: () => _promptCreate(context),
      emptyIcon: Icons.emoji_events_rounded,
    );
  }

  Future<void> _promptCreate(BuildContext context) async {
    final results = await Future.wait([
      HrApiService.instance.employees(),
      HrApiService.instance.settings(),
    ]);
    if (!context.mounted) return;
    final employees = results[0] as List<Map<String, dynamic>>;
    final settings = results[1] as Map<String, dynamic>;
    final commissionPct = (settings['salesCommissionPct'] as num?)?.toDouble() ?? 5.0;

    if (employees.isEmpty) { await _hrSnack(context, 'No employees found', error: true); return; }
    String? employeeId = '${employees.first['id']}';
    String kind = 'performance';
    final salesAmount = TextEditingController();
    final amount = TextEditingController();
    final now = DateTime.now();
    String period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final reason = TextEditingController();
    const kinds = ['performance', 'eid', 'sales', 'commission', 'annual', 'spot', 'attendance', 'target', 'other'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final isSales = kind == 'sales' || kind == 'commission';
          return AlertDialog(
            title: const Text('Add bonus / commission'),
            content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: employeeId,
                decoration: const InputDecoration(labelText: 'Employee'),
                items: employees.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text(hrPersonName(e['name'] ?? e)))).toList(),
                onChanged: (v) => setLocal(() => employeeId = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Type'),
                items: kinds.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                onChanged: (v) {
                  setLocal(() {
                    kind = v ?? kind;
                    // Auto-calc commission when switching to sales
                    if ((kind == 'sales' || kind == 'commission') &&
                        salesAmount.text.isNotEmpty) {
                      final s = double.tryParse(salesAmount.text) ?? 0;
                      if (s > 0) amount.text = (s * commissionPct / 100).toStringAsFixed(0);
                    }
                  });
                },
              ),
              if (isSales) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: salesAmount,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Sales amount (Rs)', prefixText: 'Rs ', hintText: 'Auto-calc $commissionPct% commission'),
                  onChanged: (v) {
                    final s = double.tryParse(v) ?? 0;
                    if (s > 0) {
                      setLocal(() => amount.text = (s * commissionPct / 100).toStringAsFixed(0));
                    }
                  },
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isSales ? 'Commission amount (auto-calculated)' : 'Bonus amount (Rs)',
                  prefixText: 'Rs ',
                  helperText: isSales ? '$commissionPct% of sales → auto-filled' : null,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: true,
                decoration: InputDecoration(labelText: 'Period', suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16)),
                controller: TextEditingController(text: period),
                onTap: () async {
                  final picked = await _pickYearMonth(ctx, period);
                  if (picked != null) setLocal(() => period = picked);
                },
              ),
              const SizedBox(height: 10),
              TextField(controller: reason, decoration: const InputDecoration(labelText: 'Note / reason'), maxLines: 2),
            ])),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
            ],
          );
        },
      ),
    );
    if (ok != true || employeeId == null) return;
    final amt = double.tryParse(amount.text.trim()) ?? 0;
    final salesAmt = double.tryParse(salesAmount.text.trim()) ?? 0;
    if (amt <= 0) { if (context.mounted) await _hrSnack(context, 'Enter a valid amount', error: true); return; }
    try {
      await HrApiService.instance.saveBonus({
        'employeeId': employeeId, 'kind': kind,
        'amount': amt,
        if (salesAmt > 0) 'salesAmount': salesAmt,
        'period': period,
        'reason': reason.text.trim(),
      });
      if (context.mounted) await _hrSnack(context, 'Bonus submitted for approval — include in next payroll Calculate');
    } catch (e) {
      if (context.mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
}

// ── Lifecycle ─────────────────────────────────────────────────────
class LifecycleAdminScreen extends StatelessWidget {
  const LifecycleAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Lifecycle',
      subtitle: 'Onboarding, probation, transfer, exit events',
      drawerId: 'lifecycle',
      loader: () => HrApiService.instance.lifecycle(),
      titleOf: (r) => hrPersonName(r['employee']),
      subtitleOf: (r) {
        final event = hrField(r, ['type', 'event'], 'Event');
        final date = hrShortDate(r['effective'] ?? r['date'] ?? r['createdAt']);
        final notes = hrField(r, ['notes', 'description'], '');
        return '$event  $date${notes.isNotEmpty ? '  — $notes' : ''}';
      },
      statusOf: (r) => hrField(r, ['status'], 'Logged'),
      onStatus: (r, status) => HrApiService.instance.updateApproval('${r['id']}', status),
      onCreate: () => _promptCreate(context),
      emptyIcon: Icons.timeline_rounded,
    );
  }

  Future<void> _promptCreate(BuildContext context) async {
    final employees = await HrApiService.instance.employees();
    if (!context.mounted) return;
    if (employees.isEmpty) { await _hrSnack(context, 'No employees found', error: true); return; }
    String? employeeId = '${employees.first['id']}';
    String eventType = 'onboarding';
    final date = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final notes = TextEditingController();
    const events = ['onboarding', 'probation_end', 'confirmation', 'promotion', 'transfer', 'warning', 'termination', 'resignation', 'retirement', 'other'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Log lifecycle event'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: employeeId,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: employees.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text(hrPersonName(e['name'] ?? e)))).toList(),
              onChanged: (v) => setLocal(() => employeeId = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: eventType,
              decoration: const InputDecoration(labelText: 'Event type'),
              items: events.map((e) => DropdownMenuItem(value: e, child: Text(e.replaceAll('_', ' ').toUpperCase()))).toList(),
              onChanged: (v) => setLocal(() => eventType = v ?? eventType),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: date, readOnly: true,
              decoration: const InputDecoration(labelText: 'Effective date'),
              onTap: () async {
                final d = await _pickYmd(ctx);
                if (d != null) setLocal(() => date.text = d);
              },
            ),
            const SizedBox(height: 10),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log event')),
          ],
        ),
      ),
    );
    if (ok != true || employeeId == null) return;
    try {
      await HrApiService.instance.saveLifecycle({
        'employeeId': employeeId, 'type': eventType, 'event': eventType,
        'effective': date.text.trim(), 'date': date.text.trim(),
        'notes': notes.text.trim(), 'status': 'Logged',
      });
      if (context.mounted) await _hrSnack(context, 'Lifecycle event logged');
    } catch (e) {
      if (context.mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
}

// ── Documents ─────────────────────────────────────────────────────
class DocumentsAdminScreen extends StatelessWidget {
  const DocumentsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Documents',
      subtitle: 'Contracts, ID cards, certificates, policies',
      drawerId: 'documents',
      loader: () => HrApiService.instance.documents(),
      titleOf: (r) => hrField(r, ['title', 'name'], 'Document'),
      subtitleOf: (r) {
        final emp = hrPersonName(r['employee']);
        final cat = hrField(r, ['category', 'kind', 'type'], '');
        final exp = hrShortDate(r['expiresAt'] ?? r['expiry']);
        return '$emp  $cat${exp != '—' ? '  exp $exp' : ''}';
      },
      statusOf: (r) {
        final exp = r['expiresAt'] ?? r['expiry'];
        if (exp != null) {
          try {
            final expDate = DateTime.parse('$exp');
            if (expDate.isBefore(DateTime.now())) return 'Expired';
            if (expDate.isBefore(DateTime.now().add(const Duration(days: 30)))) return 'Expiring soon';
          } catch (_) {}
        }
        return hrField(r, ['status', 'category'], 'Active');
      },
      onCreate: () => _promptUpload(context),
      emptyIcon: Icons.folder_open_rounded,
    );
  }

  Future<void> _promptUpload(BuildContext context) async {
    final employees = await HrApiService.instance.employees();
    if (!context.mounted) return;
    if (employees.isEmpty) { await _hrSnack(context, 'No employees found', error: true); return; }
    String? employeeId = '${employees.first['id']}';
    String category = 'contract';
    final title = TextEditingController();
    final url = TextEditingController();
    String? expiresAt;
    const categories = ['contract', 'id_card', 'certificate', 'policy', 'nda', 'warning_letter', 'offer_letter', 'other'];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add document'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: employeeId,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: employees.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text(hrPersonName(e['name'] ?? e)))).toList(),
              onChanged: (v) => setLocal(() => employeeId = v),
            ),
            const SizedBox(height: 10),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Document title *')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' ')))).toList(),
              onChanged: (v) => setLocal(() => category = v ?? category),
            ),
            const SizedBox(height: 10),
            TextField(controller: url, decoration: const InputDecoration(labelText: 'URL / file link (optional)')),
            const SizedBox(height: 10),
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Expiry date (optional)',
                hintText: expiresAt ?? 'No expiry',
              ),
              onTap: () async {
                final d = await _pickYmd(ctx, initial: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setLocal(() => expiresAt = d);
              },
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || employeeId == null || title.text.trim().isEmpty) return;
    try {
      await HrApiService.instance.saveDocument({
        'employeeId': employeeId, 'title': title.text.trim(),
        'category': category,
        if (url.text.trim().isNotEmpty) 'url': url.text.trim(),
        if (expiresAt != null) 'expiresAt': expiresAt,
      });
      if (context.mounted) await _hrSnack(context, 'Document saved');
    } catch (e) {
      if (context.mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
}

// ── Approvals ─────────────────────────────────────────────────────
class ApprovalsAdminScreen extends StatefulWidget {
  const ApprovalsAdminScreen({super.key});
  @override
  State<ApprovalsAdminScreen> createState() => _ApprovalsAdminScreenState();
}

class _ApprovalsAdminScreenState extends State<ApprovalsAdminScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  String _module = 'All';
  String _query = '';

  static const _modules = ['All', 'Leave', 'Loan', 'Overtime', 'Bonus', 'Document', 'Lifecycle'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Load from all modules simultaneously
      final results = await Future.wait([
        HrApiService.instance.approvals().catchError((_) => <Map<String, dynamic>>[]),
        HrApiService.instance.leaves().catchError((_) => <Map<String, dynamic>>[]),
        HrApiService.instance.loans().catchError((_) => <Map<String, dynamic>>[]),
        HrApiService.instance.overtime().catchError((_) => <Map<String, dynamic>>[]),
        HrApiService.instance.bonuses().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      final approvals = (results[0] as List<Map<String, dynamic>>)
          .map((r) => {...r, '_module': hrField(r, ['module', 'type'], 'Request')})
          .toList();
      final leaves = (results[1] as List<Map<String, dynamic>>)
          .where((r) => '${r['status']}'.toLowerCase() == 'pending')
          .map((r) => {...r, '_module': 'Leave', 'title': '${hrField(r, ['type'])} leave — ${hrPersonName(r['employee'])}'}).toList();
      final loans = (results[2] as List<Map<String, dynamic>>)
          .where((r) => '${r['status']}'.toLowerCase() == 'pending')
          .map((r) => {...r, '_module': 'Loan', 'title': '${hrField(r, ['kind'])} — ${hrPersonName(r['employee'])}'}).toList();
      final ot = (results[3] as List<Map<String, dynamic>>)
          .where((r) => '${r['status']}'.toLowerCase() == 'pending')
          .map((r) => {...r, '_module': 'Overtime', 'title': 'OT ${hrField(r, ['hours'])} hrs — ${hrPersonName(r['employee'])}'}).toList();
      final bonuses = (results[4] as List<Map<String, dynamic>>)
          .where((r) => '${r['status']}'.toLowerCase() == 'pending')
          .map((r) => {...r, '_module': 'Bonus', 'title': '${hrField(r, ['kind'])} bonus — ${hrPersonName(r['employee'])}'}).toList();

      // Merge, dedup by id
      final seen = <String>{};
      final all = <Map<String, dynamic>>[];
      for (final list in [approvals, leaves, loans, ot, bonuses]) {
        for (final row in list) {
          final id = '${row['_module']}_${row['id']}';
          if (seen.add(id)) all.add(row);
        }
      }
      setState(() { _rows = all; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _rows.where((r) {
      final mod = '${r['_module'] ?? ''}';
      final matchesMod = _module == 'All' || mod.toLowerCase() == _module.toLowerCase();
      final q = _query.toLowerCase();
      final title = '${r['title'] ?? ''}${hrPersonName(r['employee'])}${r['_module']}';
      final matchesQ = q.isEmpty || title.toLowerCase().contains(q);
      return matchesMod && matchesQ;
    }).toList();
  }

  Future<void> _approve(Map<String, dynamic> row, String status) async {
    final mod = '${row['_module']}'.toLowerCase();
    try {
      if (mod == 'leave') {
        await HrApiService.instance.updateLeave('${row['id']}', status);
      } else if (mod == 'loan') {
        await HrApiService.instance.updateLoan('${row['id']}', status);
      } else if (mod == 'overtime') {
        await HrApiService.instance.updateOvertime('${row['id']}', status);
      } else if (mod == 'bonus') {
        await HrApiService.instance.updateBonus('${row['id']}', status);
      } else {
        await HrApiService.instance.updateApproval('${row['id']}', status);
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: kDanger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final pending = _rows.where((r) => '${r['status']}'.toLowerCase() == 'pending').length;

    return HrAdminScaffold(
      title: 'Approvals',
      subtitle: '$pending pending · all modules',
      drawerId: 'approvals',
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Search
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search approvals…',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: kSubTextLight),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorderLight)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            // Module filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _modules.map((m) {
                final sel = _module == m;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _module = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? kPrimary : kBorderLight),
                      ),
                      child: Text(m, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : kSubText)),
                    ),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: kPrimary)))
            else if (_error != null)
              HrCard(child: Column(children: [
                Text(_error!, style: const TextStyle(color: kDanger)),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ]))
            else if (filtered.isEmpty)
              HrCard(child: Column(children: [
                const Icon(Icons.inbox_rounded, size: 40, color: kSubTextLight),
                const SizedBox(height: 8),
                Text(_module == 'All' ? 'No pending approvals' : 'No pending $_module requests',
                  style: const TextStyle(color: kSubTextLight, fontWeight: FontWeight.w600)),
              ]))
            else
              ...filtered.map((r) {
                final status = hrField(r, ['status'], 'Pending');
                final module = '${r['_module'] ?? 'Request'}';
                final isPending = status.toLowerCase() == 'pending' || status.toLowerCase() == 'draft';
                final moduleColor = module == 'Leave' ? Colors.purple
                    : module == 'Loan' ? Colors.orange
                    : module == 'Overtime' ? kWarning
                    : module == 'Bonus' ? Colors.green
                    : kPrimary;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HrCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: moduleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(module, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: moduleColor)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(hrField(r, ['title', 'module', 'type'], 'Request'),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kTextLight))),
                        HrStatusPill(status),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        '${hrPersonName(r['employee'] ?? r['requestedBy'])}  ${hrShortDate(r['createdAt'] ?? r['date'])}  ${hrField(r, ['reason', 'notes'], '')}',
                        style: const TextStyle(fontSize: 12, color: kSubTextLight),
                      ),
                      if (isPending) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: OutlinedButton(
                            onPressed: () => _approve(r, 'Rejected'),
                            style: OutlinedButton.styleFrom(foregroundColor: kDanger),
                            child: const Text('Reject'),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: ElevatedButton(
                            onPressed: () => _approve(r, 'Approved'),
                            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                            child: const Text('Approve'),
                          )),
                        ]),
                      ],
                    ]),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── Tasks ─────────────────────────────────────────────────────────
class TasksAdminScreen extends StatelessWidget {
  const TasksAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Task Management',
      subtitle: 'Assign and track HR tasks',
      drawerId: 'tasks',
      loader: () => HrApiService.instance.tasks(),
      titleOf: (r) => hrField(r, ['title'], 'Task'),
      subtitleOf: (r) {
        final assignee = hrField(r, ['assignedTo', 'assignee', 'employee'], 'Unassigned');
        final due = hrField(r, ['due', 'dueDate']);
        final desc = hrField(r, ['description', 'notes'], '');
        return '$assignee  due: $due${desc.isNotEmpty ? '\n$desc' : ''}';
      },
      statusOf: (r) => hrField(r, ['status'], 'Pending'),
      onCreate: () => _promptCreate(context),
      emptyIcon: Icons.task_alt_rounded,
    );
  }

  Future<void> _promptCreate(BuildContext context) async {
    final employees = await HrApiService.instance.employees();
    if (!context.mounted) return;
    if (employees.isEmpty) { await _hrSnack(context, 'No employees found', error: true); return; }
    String? assigneeId = '${employees.first['id']}';
    final title = TextEditingController();
    final description = TextEditingController();
    final due = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 3))));
    String priority = 'medium';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New task'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Task title *')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: assigneeId,
              decoration: const InputDecoration(labelText: 'Assign to'),
              items: employees.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text(hrPersonName(e['name'] ?? e)))).toList(),
              onChanged: (v) => setLocal(() => assigneeId = v),
            ),
            const SizedBox(height: 10),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            const SizedBox(height: 10),
            TextField(controller: due, readOnly: true, decoration: const InputDecoration(labelText: 'Due date'),
              onTap: () async {
                final d = await _pickYmd(ctx);
                if (d != null) setLocal(() => due.text = d);
              }),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: ['low', 'medium', 'high', 'urgent'].map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
              onChanged: (v) => setLocal(() => priority = v ?? priority),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );
    if (ok != true || assigneeId == null || title.text.trim().isEmpty) return;
    try {
      await HrApiService.instance.createTask({
        'title': title.text.trim(), 'assigneeId': assigneeId,
        'description': description.text.trim(), 'dueDate': due.text.trim(),
        'priority': priority, 'status': 'Pending',
      });
      if (context.mounted) await _hrSnack(context, 'Task created');
    } catch (e) {
      if (context.mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
}

// ── Performance Reviews ────────────────────────────────────────────
class PerformanceAdminScreen extends StatelessWidget {
  const PerformanceAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Performance Reviews',
      subtitle: 'Review cycles, ratings & appraisals',
      drawerId: 'performance',
      loader: () => HrApiService.instance.performance(),
      titleOf: (r) => hrPersonName(r['employee']),
      subtitleOf: (r) {
        final period = hrField(r, ['period'], '');
        final rating = hrField(r, ['rating', 'score'], '—');
        final reviewer = hrField(r, ['reviewer', 'reviewerName'], '');
        return '$period  Rating: $rating/5${reviewer.isNotEmpty ? '  Reviewer: $reviewer' : ''}';
      },
      statusOf: (r) => hrField(r, ['status'], 'Draft'),
      onStatus: (r, status) => HrApiService.instance.updateReview('${r['id']}', {'status': status}),
      onCreate: () => _promptCreate(context),
      emptyIcon: Icons.rate_review_rounded,
    );
  }

  Future<void> _promptCreate(BuildContext context) async {
    final employees = await HrApiService.instance.employees();
    if (!context.mounted) return;
    if (employees.isEmpty) { await _hrSnack(context, 'No employees found', error: true); return; }
    String? employeeId = '${employees.first['id']}';
    String? reviewerId;
    final now = DateTime.now();
    String period = 'Q${((now.month - 1) ~/ 3) + 1} ${now.year}';
    double rating = 3;
    final notes = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Create performance review'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: employeeId,
              decoration: const InputDecoration(labelText: 'Employee'),
              items: employees.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text(hrPersonName(e['name'] ?? e)))).toList(),
              onChanged: (v) => setLocal(() => employeeId = v),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: reviewerId,
              decoration: const InputDecoration(labelText: 'Reviewer (optional)'),
              items: [const DropdownMenuItem(value: null, child: Text('— HR Manager —')),
                ...employees.map((e) => DropdownMenuItem(value: '${e['id']}', child: Text(hrPersonName(e['name'] ?? e))))],
              onChanged: (v) => setLocal(() => reviewerId = v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: period),
              decoration: const InputDecoration(labelText: 'Review period (e.g. Q3 2025)'),
              onChanged: (v) => period = v,
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Rating: ${rating.toStringAsFixed(1)} / 5.0', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
            Slider(
              value: rating, min: 1, max: 5, divisions: 8,
              label: rating.toStringAsFixed(1),
              onChanged: (v) => setLocal(() => rating = v),
            ),
            const SizedBox(height: 6),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Reviewer notes'), maxLines: 3),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      ),
    );
    if (ok != true || employeeId == null) return;
    try {
      await HrApiService.instance.createReview({
        'employeeId': employeeId,
        if (reviewerId != null) 'reviewerId': reviewerId,
        'period': period, 'rating': rating, 'score': rating,
        'notes': notes.text.trim(), 'status': 'Draft',
      });
      if (context.mounted) await _hrSnack(context, 'Review created');
    } catch (e) {
      if (context.mounted) await _hrSnack(context, e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }
}

// ── Org Chart ─────────────────────────────────────────────────────
class OrgChartAdminScreen extends StatefulWidget {
  const OrgChartAdminScreen({super.key});
  @override
  State<OrgChartAdminScreen> createState() => _OrgChartAdminScreenState();
}

class _OrgChartAdminScreenState extends State<OrgChartAdminScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _nodes = [];
  String? _error;
  String _filterDept = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await HrApiService.instance.orgChart();
      final list = <Map<String, dynamic>>[];
      void walk(dynamic node, {String? dept, int depth = 0}) {
        if (node is! Map) return;
        final m = Map<String, dynamic>.from(node);
        final children = m['children'];
        final name = '${m['name'] ?? ''}';
        if (name == 'Organization') {
          if (children is List) for (final c in children) walk(c, depth: 0);
          return;
        }
        final isDept = children is List && children.isNotEmpty && (children.first is Map) && ((children.first as Map)['children'] is List || depth == 0);
        list.add({ 'name': name, 'role': '${m['role'] ?? m['designation'] ?? ''}', 'department': dept ?? m['department'] ?? '', 'isDepartment': isDept, 'depth': depth, 'headcount': isDept ? children?.length ?? 0 : 0, 'reportsTo': '${m['reportsTo'] ?? ''}' });
        if (isDept && children is List) for (final c in children) walk(c, dept: name, depth: depth + 1);
      }
      walk(data);
      if (!mounted) return;
      setState(() { _nodes = list; _loading = false; _error = null; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterDept.isEmpty) return _nodes;
    return _nodes.where((n) => '${n['department']}'.toLowerCase().contains(_filterDept.toLowerCase()) || n['isDepartment'] == true).toList();
  }

  @override
  Widget build(BuildContext context) {
    final depts = _nodes.where((n) => n['isDepartment'] == true).map((n) => '${n['name']}').toSet().toList();
    return HrAdminScaffold(
      title: 'Organization Chart',
      subtitle: 'Departments, roles & reporting lines',
      drawerId: 'org_chart',
      body: Column(
        children: [
          if (depts.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  ActionChip(
                    label: const Text('All', style: TextStyle(fontSize: 11)),
                    onPressed: () => setState(() => _filterDept = ''),
                    backgroundColor: _filterDept.isEmpty ? kPrimary : Colors.white,
                    labelStyle: TextStyle(color: _filterDept.isEmpty ? Colors.white : null),
                    side: BorderSide(color: _filterDept.isEmpty ? kPrimary : kBorderLight),
                  ),
                  ...depts.map((d) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ActionChip(
                      label: Text(d, style: const TextStyle(fontSize: 11)),
                      onPressed: () => setState(() => _filterDept = d == _filterDept ? '' : d),
                      backgroundColor: _filterDept == d ? kPrimary : Colors.white,
                      labelStyle: TextStyle(color: _filterDept == d ? Colors.white : null),
                      side: BorderSide(color: _filterDept == d ? kPrimary : kBorderLight),
                    ),
                  )),
                ]),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: kPrimary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kPrimary))
                  : _error != null
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_error!, style: const TextStyle(color: kDanger)),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ]))
                      : _nodes.isEmpty
                          ? const Center(child: Text('No org chart data from API', style: TextStyle(color: kSubTextLight)))
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) {
                                final n = _filtered[i];
                                final isDept = n['isDepartment'] == true;
                                final depth = (n['depth'] as int?) ?? 0;
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 8, left: isDept ? 0 : (depth * 16.0).clamp(0, 48)),
                                  child: isDept
                                      ? Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(14)),
                                          child: Row(children: [
                                            const Icon(Icons.account_tree_rounded, color: Colors.white, size: 18),
                                            const SizedBox(width: 10),
                                            Expanded(child: Text('${n['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14))),
                                            if ((n['headcount'] as int? ?? 0) > 0)
                                              Text('${n['headcount']} people', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                          ]),
                                        )
                                      : HrCard(child: Row(children: [
                                          CircleAvatar(
                                            backgroundColor: kPrimary.withValues(alpha: 0.1),
                                            radius: 20,
                                            child: Text(
                                              '${n['name']}'.isNotEmpty ? '${n['name']}'[0].toUpperCase() : '?',
                                              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text('${n['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                            Text('${n['role']}${n['department'] != '' ? '  •  ${n['department']}' : ''}', style: const TextStyle(fontSize: 11, color: kSubTextLight)),
                                          ])),
                                          if ('${n['reportsTo']}'.isNotEmpty && n['reportsTo'] != 'null')
                                            Tooltip(message: 'Reports to: ${n['reportsTo']}', child: const Icon(Icons.arrow_upward_rounded, size: 14, color: kSubTextLight)),
                                        ])),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}


class NotificationsAdminScreen extends StatelessWidget {
  const NotificationsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrResourceListScreen(
      title: 'Notifications',
      subtitle: 'Live HR alerts',
      drawerId: 'notifications',
      loader: () => HrApiService.instance.notifications(),
      titleOf: (r) => hrField(r, ['title', 'type'], 'Alert'),
      subtitleOf: (r) =>
          '${hrField(r, ['body', 'message'])} · ${hrShortDate(r['time'] ?? r['createdAt'])}',
      statusOf: (r) => hrField(r, ['type'], 'Info'),
      emptyIcon: Icons.notifications_rounded,
    );
  }
}

class HrSettingsAdminScreen extends StatefulWidget {
  const HrSettingsAdminScreen({super.key});

  @override
  State<HrSettingsAdminScreen> createState() => _HrSettingsAdminScreenState();
}

class _HrSettingsAdminScreenState extends State<HrSettingsAdminScreen> {
  bool _loading = true;
  bool _saving = false;

  // Attendance toggles
  bool _geofence = true;
  bool _autoCheckout = true;
  bool _lateAlerts = true;
  bool _faceId = false;
  bool _weeklyReports = false;

  // Working time
  final _workHoursPerDay = TextEditingController(text: '8');
  final _workDaysPerWeek = TextEditingController(text: '6');
  final _overtimeMultiplier = TextEditingController(text: '1.5');
  final _annualLeaveQuota = TextEditingController(text: '14');
  final _graceMinutes = TextEditingController(text: '15');
  final _lateThresholdMinutes = TextEditingController(text: '15');
  final _earlyCheckoutMinutes = TextEditingController(text: '30');
  final _minimumWorkingHours = TextEditingController(text: '8');
  final _halfDayHours = TextEditingController(text: '4');

  // Sales & commission
  final _salesCommissionPct = TextEditingController(text: '5');
  final _noSaleCutAmount = TextEditingController(text: '0');
  final _noSaleCutRoles = TextEditingController(text: 'Salesman,sales,Field Employee');

  // Deduction policy
  final _lateDeductionPerDay = TextEditingController(text: '0');
  String _absentDeductionMode = 'daily_rate';
  final _absentDeductionPerDay = TextEditingController(text: '0');
  final _halfDayDeductionPct = TextEditingController(text: '50');

  // Salary structure
  final _basicPct = TextEditingController(text: '60');
  final _housePct = TextEditingController(text: '25');
  final _transportPct = TextEditingController(text: '10');
  final _medicalPct = TextEditingController(text: '5');
  final _taxPct = TextEditingController(text: '0');
  final _eobiPct = TextEditingController(text: '1');
  final _pfPct = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _workHoursPerDay, _workDaysPerWeek, _overtimeMultiplier, _annualLeaveQuota,
      _graceMinutes, _lateThresholdMinutes, _earlyCheckoutMinutes, _minimumWorkingHours, _halfDayHours,
      _salesCommissionPct, _noSaleCutAmount, _noSaleCutRoles,
      _lateDeductionPerDay, _absentDeductionPerDay, _halfDayDeductionPct,
      _basicPct, _housePct, _transportPct, _medicalPct, _taxPct, _eobiPct, _pfPct,
    ]) { c.dispose(); }
    super.dispose();
  }

  void _applySettings(Map<String, dynamic> s) {
    _geofence = s['geofence'] != false;
    _autoCheckout = s['autoCheckout'] != false;
    _lateAlerts = s['lateAlerts'] != false;
    _faceId = s['faceId'] == true;
    _weeklyReports = s['weeklyReports'] == true;

    void num(TextEditingController c, String key, dynamic def) =>
        c.text = '${s[key] ?? def}';

    num(_workHoursPerDay, 'workHoursPerDay', 8);
    num(_workDaysPerWeek, 'workDaysPerWeek', 6);
    num(_overtimeMultiplier, 'overtimeMultiplier', 1.5);
    num(_annualLeaveQuota, 'annualLeaveQuota', 14);
    num(_graceMinutes, 'graceMinutes', 15);
    num(_lateThresholdMinutes, 'lateThresholdMinutes', 15);
    num(_earlyCheckoutMinutes, 'earlyCheckoutMinutes', 30);
    num(_minimumWorkingHours, 'minimumWorkingHours', 8);
    num(_halfDayHours, 'halfDayHours', 4);

    num(_salesCommissionPct, 'salesCommissionPct', 5);
    num(_noSaleCutAmount, 'noSaleCutAmount', 0);
    _noSaleCutRoles.text = '${s['noSaleCutRoles'] ?? 'Salesman,sales,Field Employee'}';

    num(_lateDeductionPerDay, 'lateDeductionPerDay', 0);
    _absentDeductionMode = '${s['absentDeductionMode'] ?? 'daily_rate'}';
    num(_absentDeductionPerDay, 'absentDeductionPerDay', 0);
    num(_halfDayDeductionPct, 'halfDayDeductionPct', 50);

    num(_basicPct, 'basicPct', 60);
    num(_housePct, 'housePct', 25);
    num(_transportPct, 'transportPct', 10);
    num(_medicalPct, 'medicalPct', 5);
    num(_taxPct, 'taxPct', 0);
    num(_eobiPct, 'eobiPct', 1);
    num(_pfPct, 'pfPct', 0);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await HrApiService.instance.settings();
      final payload = s['payload'] is Map ? Map<String, dynamic>.from(s['payload'] as Map) : s;
      if (!mounted) return;
      setState(() {
        _applySettings(payload);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  double _d(TextEditingController c, double def) => double.tryParse(c.text) ?? def;
  int _i(TextEditingController c, int def) => int.tryParse(c.text) ?? def;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await HrApiService.instance.saveSettings({
        'geofence': _geofence,
        'autoCheckout': _autoCheckout,
        'lateAlerts': _lateAlerts,
        'faceId': _faceId,
        'weeklyReports': _weeklyReports,
        'workHoursPerDay': _i(_workHoursPerDay, 8),
        'workDaysPerWeek': _i(_workDaysPerWeek, 6),
        'overtimeMultiplier': _d(_overtimeMultiplier, 1.5),
        'annualLeaveQuota': _i(_annualLeaveQuota, 14),
        'graceMinutes': _i(_graceMinutes, 15),
        'lateThresholdMinutes': _i(_lateThresholdMinutes, 15),
        'earlyCheckoutMinutes': _i(_earlyCheckoutMinutes, 30),
        'minimumWorkingHours': _i(_minimumWorkingHours, 8),
        'halfDayHours': _i(_halfDayHours, 4),
        'salesCommissionPct': _d(_salesCommissionPct, 5),
        'noSaleCutAmount': _d(_noSaleCutAmount, 0),
        'noSaleCutRoles': _noSaleCutRoles.text.trim(),
        'lateDeductionPerDay': _d(_lateDeductionPerDay, 0),
        'absentDeductionMode': _absentDeductionMode,
        'absentDeductionPerDay': _d(_absentDeductionPerDay, 0),
        'halfDayDeductionPct': _d(_halfDayDeductionPct, 50),
        'basicPct': _d(_basicPct, 60),
        'housePct': _d(_housePct, 25),
        'transportPct': _d(_transportPct, 10),
        'medicalPct': _d(_medicalPct, 5),
        'taxPct': _d(_taxPct, 0),
        'eobiPct': _d(_eobiPct, 1),
        'pfPct': _d(_pfPct, 0),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HR settings saved — next payroll will use these rules')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: kDanger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HrAdminScaffold(
      title: 'HR Settings',
      subtitle: 'Attendance · salary policy · statutory',
      drawerId: 'settings',
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('Attendance Toggles', [
                  _toggle('Auto Geofence Check-in', 'Auto check-in when inside office radius', _geofence,
                      (v) => setState(() => _geofence = v)),
                  _toggle('Auto Checkout', 'Check employees out when leaving office radius', _autoCheckout,
                      (v) => setState(() => _autoCheckout = v)),
                  _toggle('Late Arrival Alerts', 'Show late check-ins in Notifications', _lateAlerts,
                      (v) => setState(() => _lateAlerts = v)),
                  _toggle('Face / Biometric Verification', 'Require biometric on check-in (mobile)', _faceId,
                      (v) => setState(() => _faceId = v)),
                  _toggle('Weekly HR Report Email', 'Email weekly attendance summary to HR admins', _weeklyReports,
                      (v) => setState(() => _weeklyReports = v)),
                ]),
                const SizedBox(height: 16),
                _section('Working Time', [
                  Row(children: [
                    Expanded(child: _num('Hours / day', _workHoursPerDay)),
                    const SizedBox(width: 10),
                    Expanded(child: _num('Days / week', _workDaysPerWeek)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _num('OT multiplier', _overtimeMultiplier)),
                    const SizedBox(width: 10),
                    Expanded(child: _num('Annual leave quota', _annualLeaveQuota)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _num('Grace (min)', _graceMinutes)),
                    const SizedBox(width: 10),
                    Expanded(child: _num('Late threshold (min)', _lateThresholdMinutes)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _num('Early checkout (min)', _earlyCheckoutMinutes)),
                    const SizedBox(width: 10),
                    Expanded(child: _num('Min working hrs', _minimumWorkingHours)),
                  ]),
                  const SizedBox(height: 10),
                  _num('Half-day hours', _halfDayHours),
                ]),
                const SizedBox(height: 16),
                _section('Sales & Commission', [
                  _num('Sales commission %', _salesCommissionPct),
                  const SizedBox(height: 10),
                  _num('No-sale cut (Rs)', _noSaleCutAmount),
                  const SizedBox(height: 10),
                  _tf('No-sale cut roles (comma-separated)', _noSaleCutRoles),
                ]),
                const SizedBox(height: 16),
                _section('Deduction Policy', [
                  _num('Late deduction / day (Rs)', _lateDeductionPerDay),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _absentDeductionMode,
                    decoration: InputDecoration(
                      labelText: 'Absent deduction mode',
                      filled: true,
                      fillColor: kBgLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily_rate', child: Text('Daily rate')),
                      DropdownMenuItem(value: 'fixed', child: Text('Fixed amount')),
                    ],
                    onChanged: (v) => setState(() => _absentDeductionMode = v ?? _absentDeductionMode),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _num('Absent cut / day (Rs)', _absentDeductionPerDay)),
                    const SizedBox(width: 10),
                    Expanded(child: _num('Half-day deduction %', _halfDayDeductionPct)),
                  ]),
                ]),
                const SizedBox(height: 16),
                _section('Salary Structure & Statutory', [
                  Row(children: [
                    Expanded(child: _num('Basic %', _basicPct)),
                    const SizedBox(width: 10),
                    Expanded(child: _num('House %', _housePct)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _num('Transport %', _transportPct)),
                    const SizedBox(width: 10),
                    Expanded(child: _num('Medical %', _medicalPct)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _num('Tax %', _taxPct)),
                    const SizedBox(width: 10),
                    Expanded(child: _num('EOBI %', _eobiPct)),
                  ]),
                  const SizedBox(height: 10),
                  _num('Provident fund %', _pfPct),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(_saving ? 'Saving…' : 'Save HR Settings',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _section(String title, List<Widget> children) => HrCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kPrimary)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );

  Widget _toggle(String label, String desc, bool value, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: kSubTextLight)),
      activeColor: kPrimary,
      contentPadding: EdgeInsets.zero,
      dense: true,
    ),
  );

  Widget _num(String label, TextEditingController c) => TextField(
    controller: c,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: kBgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(fontSize: 12),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  Widget _tf(String label, TextEditingController c) => TextField(
    controller: c,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: kBgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(fontSize: 12),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

class ReportsAdminScreen extends StatefulWidget {
  const ReportsAdminScreen({super.key});
  @override
  State<ReportsAdminScreen> createState() => _ReportsAdminScreenState();
}

class _ReportsAdminScreenState extends State<ReportsAdminScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _payrollSummary = {};
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _attendanceSummary = {};
  List<Map<String, dynamic>> _loans = [];
  List<Map<String, dynamic>> _bonuses = [];
  late String _period;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _period = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        HrApiService.instance.payrollReport(period: _period).catchError((_) => <String, dynamic>{}),
        HrApiService.instance.dashboard().catchError((_) => <String, dynamic>{}),
        HrApiService.instance.attendanceSummary(date: DateFormat('yyyy-MM-dd').format(DateTime.now())).catchError((_) => <String, dynamic>{}),
        HrApiService.instance.loans().catchError((_) => <Map<String, dynamic>>[]),
        HrApiService.instance.bonuses().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      final payRaw = results[0] as Map<String, dynamic>;
      final dash = results[1] as Map<String, dynamic>;
      final att = results[2] as Map<String, dynamic>;
      setState(() {
        _payrollSummary = Map<String, dynamic>.from(payRaw['summary'] ?? payRaw['data'] ?? payRaw);
        _dashboard = Map<String, dynamic>.from(dash['data'] ?? dash);
        _attendanceSummary = Map<String, dynamic>.from(att['summary'] ?? att['data'] ?? att);
        _loans = (results[3] as List).whereType<Map<String, dynamic>>().toList();
        _bonuses = (results[4] as List).whereType<Map<String, dynamic>>().toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  String _pkr(dynamic n) {
    final v = n is num ? n : num.tryParse('$n') ?? 0;
    return 'Rs ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final pendingLoans = _loans.where((l) => l['status'] == 'Pending').length;
    final approvedLoans = _loans.where((l) => l['status'] == 'Approved').length;
    final totalLoanAmt = _loans.fold(0.0, (s, l) => s + ((l['amount'] as num?) ?? 0).toDouble());
    final pendingBonuses = _bonuses.where((b) => b['status'] == 'Pending').length;
    final totalBonusAmt = _bonuses.fold(0.0, (s, b) => s + ((b['amount'] as num?) ?? 0).toDouble());

    return HrAdminScaffold(
      title: 'Reports & Analytics',
      subtitle: _period,
      drawerId: 'reports',
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          onPressed: () async {
            final picked = await _pickYearMonth(context, _period);
            if (picked != null && picked != _period) {
              setState(() => _period = picked);
              _load();
            }
          },
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    HrCard(child: Text(_error!, style: const TextStyle(color: kDanger))),

                  // ── Payroll summary
                  _sectionHeader('Payroll — $_period', Icons.payments_rounded),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _statCard('Gross pay', _pkr(_payrollSummary['gross'] ?? _payrollSummary['totalGross']), kPrimary)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Net pay', _pkr(_payrollSummary['net'] ?? _payrollSummary['totalNet']), kSuccess)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _statCard('Deductions', _pkr(_payrollSummary['deductions'] ?? _payrollSummary['totalDeductions']), kDanger)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Headcount', '${_payrollSummary['headcount'] ?? _payrollSummary['employees'] ?? 0}', kPrimary)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _statCard('Income tax', _pkr(_payrollSummary['totalTax'] ?? _payrollSummary['tax'] ?? 0), Colors.orange.shade700)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('EOBI', _pkr(_payrollSummary['totalEobi'] ?? _payrollSummary['eobi'] ?? 0), Colors.teal)),
                  ]),
                  const SizedBox(height: 16),

                  // ── Today's attendance
                  _sectionHeader('Attendance — today', Icons.how_to_reg_rounded),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _statCard('Present', '${_attendanceSummary['present'] ?? _dashboard['presentToday'] ?? 0}', kSuccess)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Absent', '${_attendanceSummary['absent'] ?? _dashboard['absentToday'] ?? 0}', kDanger)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Late', '${_attendanceSummary['late'] ?? _dashboard['lateToday'] ?? 0}', Colors.orange.shade700)),
                  ]),
                  const SizedBox(height: 16),

                  // ── Workforce snapshot
                  _sectionHeader('Workforce snapshot', Icons.people_rounded),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _statCard('Total employees', '${_dashboard['totalEmployees'] ?? _dashboard['employees'] ?? 0}', kPrimary)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Active', '${_dashboard['activeEmployees'] ?? _dashboard['active'] ?? 0}', kSuccess)),
                  ]),
                  const SizedBox(height: 16),

                  // ── Loans
                  _sectionHeader('Loans & Advances', Icons.account_balance_rounded),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _statCard('Pending approval', '$pendingLoans', Colors.orange.shade700)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Active loans', '$approvedLoans', kPrimary)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Total exposure', _pkr(totalLoanAmt), kDanger)),
                  ]),
                  const SizedBox(height: 16),

                  // ── Bonuses
                  _sectionHeader('Bonuses this month', Icons.emoji_events_rounded),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _statCard('Pending', '$pendingBonuses', Colors.orange.shade700)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Total amount', _pkr(totalBonusAmt), kSuccess)),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: kPrimary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: kPrimary)),
    ]);
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: kSubText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}



class CalendarAdminScreen extends StatefulWidget {
  const CalendarAdminScreen({super.key});
  @override
  State<CalendarAdminScreen> createState() => _CalendarAdminScreenState();
}

class _CalendarAdminScreenState extends State<CalendarAdminScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _holidays = [];
  List<Map<String, dynamic>> _leaves = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        HrApiService.instance.holidayCalendar(year: _month.year),
        HrApiService.instance.leaves(),
      ]);
      if (!mounted) return;
      setState(() {
        _holidays = (results[0] as List).cast<Map<String, dynamic>>();
        _leaves = (results[1] as List)
            .cast<Map<String, dynamic>>()
            .where((l) => '${l['status']}'.toLowerCase() == 'approved')
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Set<DateTime> _holidayDates() {
    final set = <DateTime>{};
    for (final h in _holidays) {
      final d = DateTime.tryParse('${h['date'] ?? ''}');
      if (d != null) set.add(DateTime(d.year, d.month, d.day));
    }
    return set;
  }

  Map<DateTime, List<String>> _leaveByDate() {
    final map = <DateTime, List<String>>{};
    for (final l in _leaves) {
      final from = DateTime.tryParse('${l['from'] ?? l['fromDate'] ?? ''}');
      final to = DateTime.tryParse('${l['to'] ?? l['toDate'] ?? ''}');
      if (from == null) continue;
      final end = to ?? from;
      for (var d = from; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        final key = DateTime(d.year, d.month, d.day);
        final name = hrPersonName(l['employee'] ?? l['employeeName']);
        (map[key] ??= []).add(name);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final holidayDates = _holidayDates();
    final leaveMap = _leaveByDate();
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7; // 0=Sun

    // Events list for bottom section
    final monthHolidays = _holidays.where((h) {
      final d = DateTime.tryParse('${h['date'] ?? ''}');
      return d != null && d.year == _month.year && d.month == _month.month;
    }).toList();
    final monthLeaves = _leaves.where((l) {
      final from = DateTime.tryParse('${l['from'] ?? l['fromDate'] ?? ''}');
      final to = DateTime.tryParse('${l['to'] ?? l['toDate'] ?? ''}');
      if (from == null) return false;
      final end = to ?? from;
      return (from.year == _month.year && from.month == _month.month) ||
             (end.year == _month.year && end.month == _month.month);
    }).toList();

    return HrAdminScaffold(
      title: 'Calendar',
      subtitle: DateFormat('MMMM yyyy').format(_month),
      drawerId: 'calendar',
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
          onPressed: () { setState(() { _month = DateTime(_month.year, _month.month - 1); }); _load(); },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
          onPressed: () { setState(() { _month = DateTime(_month.year, _month.month + 1); }); _load(); },
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: kDanger)),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Legend
                      Row(children: [
                        _legendDot(Colors.blue.shade600, 'Holiday'),
                        const SizedBox(width: 16),
                        _legendDot(Colors.purple, 'Approved leave'),
                        const SizedBox(width: 16),
                        _legendDot(Colors.grey.shade300, 'Weekend'),
                      ]),
                      const SizedBox(height: 12),
                      // Calendar grid
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Weekday headers
                            Row(children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) =>
                              Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kSubText))))
                            ).toList()),
                            const SizedBox(height: 8),
                            // Day cells
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 4,
                              ),
                              itemCount: firstWeekday + daysInMonth,
                              itemBuilder: (_, i) {
                                if (i < firstWeekday) return const SizedBox.shrink();
                                final day = i - firstWeekday + 1;
                                final date = DateTime(_month.year, _month.month, day);
                                final isToday = date.year == DateTime.now().year &&
                                    date.month == DateTime.now().month &&
                                    date.day == DateTime.now().day;
                                final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                                final isHoliday = holidayDates.contains(date);
                                final leaveNames = leaveMap[date] ?? [];
                                final hasLeave = leaveNames.isNotEmpty;

                                Color bg = isHoliday
                                    ? Colors.blue.shade100
                                    : hasLeave
                                        ? Colors.purple.shade50
                                        : isWeekend
                                            ? Colors.grey.shade100
                                            : Colors.transparent;
                                Color textColor = isHoliday
                                    ? Colors.blue.shade700
                                    : hasLeave
                                        ? Colors.purple.shade700
                                        : isWeekend
                                            ? kSubText
                                            : kText;
                                if (isToday) { bg = kPrimary; textColor = Colors.white; }

                                return GestureDetector(
                                  onTap: (isHoliday || hasLeave) ? () => _showDayDetail(date, isHoliday, leaveNames) : null,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: bg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isToday ? null : Border.all(color: Colors.transparent),
                                    ),
                                    child: Stack(
                                      children: [
                                        Center(child: Text('$day', style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: textColor))),
                                        if (isHoliday && !isToday)
                                          Positioned(bottom: 3, right: 3, child: Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.blue.shade600, shape: BoxShape.circle))),
                                        if (hasLeave && !isToday)
                                          Positioned(bottom: 3, left: 3, child: Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle))),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Holidays this month
                      if (monthHolidays.isNotEmpty) ...[
                        const Text('Holidays', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kPrimary)),
                        const SizedBox(height: 8),
                        ...monthHolidays.map((h) => _eventTile(
                          icon: Icons.celebration_rounded,
                          color: Colors.blue.shade600,
                          title: '${h['name'] ?? 'Holiday'}',
                          subtitle: '${hrShortDate(h['date'])} · ${h['type'] ?? 'Public'}',
                        )),
                        const SizedBox(height: 12),
                      ],
                      // Leaves this month
                      if (monthLeaves.isNotEmpty) ...[
                        const Text('Approved Leaves', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: kPrimary)),
                        const SizedBox(height: 8),
                        ...monthLeaves.map((l) => _eventTile(
                          icon: Icons.flight_takeoff_rounded,
                          color: Colors.purple,
                          title: hrPersonName(l['employee'] ?? l['employeeName']),
                          subtitle: '${l['type'] ?? 'Leave'}  ${hrShortDate(l['from'] ?? l['fromDate'])} → ${hrShortDate(l['to'] ?? l['toDate'])}',
                        )),
                      ],
                      if (monthHolidays.isEmpty && monthLeaves.isEmpty)
                        HrCard(child: Text('No events this month', style: TextStyle(color: kSubText))),
                    ],
                  ),
                ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: kSubText, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _eventTile({required IconData icon, required Color color, required String title, required String subtitle}) =>
    Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: kSubText)),
          ])),
        ],
      ),
    );

  void _showDayDetail(DateTime date, bool isHoliday, List<String> leaveNames) {
    final holiday = _holidays.firstWhere(
      (h) { final d = DateTime.tryParse('${h['date'] ?? ''}'); return d != null && DateTime(d.year, d.month, d.day) == date; },
      orElse: () => {},
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(DateFormat('EEE, d MMM yyyy').format(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHoliday) ...[
              Row(children: [
                Icon(Icons.celebration_rounded, size: 16, color: Colors.blue.shade600),
                const SizedBox(width: 6),
                Text('${holiday['name'] ?? 'Holiday'}  (${holiday['type'] ?? 'Public'})', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blue.shade700)),
              ]),
              const SizedBox(height: 8),
            ],
            if (leaveNames.isNotEmpty) ...[
              const Text('On approved leave:', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.purple)),
              const SizedBox(height: 4),
              ...leaveNames.map((n) => Padding(padding: const EdgeInsets.only(bottom: 2), child: Row(children: [
                const Icon(Icons.person_outline_rounded, size: 14, color: Colors.purple),
                const SizedBox(width: 4),
                Text(n, style: const TextStyle(fontSize: 13)),
              ]))),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
