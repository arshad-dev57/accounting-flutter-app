import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _money = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

class EmployeePayslipScreen extends StatefulWidget {
  const EmployeePayslipScreen({super.key});

  @override
  State<EmployeePayslipScreen> createState() => _EmployeePayslipScreenState();
}

class _EmployeePayslipScreenState extends State<EmployeePayslipScreen> {
  Map<String, dynamic> _me = {};
  Map<String, dynamic> _ytd = {};
  Map<String, dynamic> _compensation = {};
  List<Map<String, dynamic>> _slips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await HrApiService.instance.me();
      final payroll = await HrApiService.instance.myPayroll();
      _me = me;
      _slips = (payroll['items'] as List).whereType<Map<String, dynamic>>().toList();
      _ytd = payroll['ytd'] is Map
          ? Map<String, dynamic>.from(payroll['ytd'] as Map)
          : {};
      _compensation = payroll['compensation'] is Map
          ? Map<String, dynamic>.from(payroll['compensation'] as Map)
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
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          Container(
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payroll & Payslips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Official monthly statements',
                            style: TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() => _loading = true);
                        _load();
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() => _loading = true);
                          await _load();
                        },
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(
                              _me['name']?.toString() ?? 'Employee',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_me['employeeCode'] ?? ''}  ·  ${_me['designation'] ?? ''}  ·  ${_me['department'] ?? ''}',
                              style: TextStyle(color: kSubText, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            _ytdGrid(),
                            const SizedBox(height: 16),
                            _compensationCard(),
                            const SizedBox(height: 16),
                            const Text(
                              'Payslip history',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_slips.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFDDE4EE)),
                                ),
                                child: Text(
                                  'No released payslips yet. HR must process, approve and pay the monthly run before it appears here.',
                                  style: TextStyle(color: kSubText, fontSize: 13, height: 1.4),
                                ),
                              )
                            else
                              ..._slips.map(_slipTile),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _ytdGrid() {
    final year = _ytd['year'] ?? DateTime.now().year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Year to date · $year',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _stat('Net paid', _money.format(_n(_ytd['net'])))),
            const SizedBox(width: 10),
            Expanded(child: _stat('Gross earnings', _money.format(_n(_ytd['gross'])))),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _stat('Deductions', _money.format(_n(_ytd['deductions'])))),
            const SizedBox(width: 10),
            Expanded(child: _stat('Months released', '${_ytd['months'] ?? _slips.length}')),
          ],
        ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: kSubText, fontSize: 11, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _compensationCard() {
    final pkg = _n(_compensation['package'] ?? _me['salary']);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Salary structure', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            'Monthly package split used on every official payslip',
            style: TextStyle(color: kSubText, fontSize: 11),
          ),
          const Divider(height: 22),
          _kv('Monthly package', pkg > 0 ? _money.format(pkg) : 'Not set by HR'),
          _kv('Basic', _money.format(_n(_compensation['basic']))),
          _kv('House rent', _money.format(_n(_compensation['houseAllowance']))),
          _kv('Transport', _money.format(_n(_compensation['transportAllowance']))),
          _kv('Medical', _money.format(_n(_compensation['medicalAllowance']))),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: kSubText, fontSize: 12))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _slipTile(Map<String, dynamic> slip) {
    final net = _n(slip['net']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EmployeePayslipDetailScreen(slip: slip)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDE4EE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long_rounded, color: kPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slip['periodLabel']?.toString() ?? slip['period']?.toString() ?? 'Payslip',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${slip['status'] ?? ''}  ·  tap for official statement',
                        style: TextStyle(color: kSubText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  _money.format(net),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2ECC71),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmployeePayslipDetailScreen extends StatelessWidget {
  const EmployeePayslipDetailScreen({super.key, required this.slip});

  final Map<String, dynamic> slip;

  double _n(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  Map<String, dynamic> get _b =>
      slip['breakdown'] is Map ? Map<String, dynamic>.from(slip['breakdown'] as Map) : {};

  Map<String, dynamic> get _earn =>
      _b['earnings'] is Map ? Map<String, dynamic>.from(_b['earnings'] as Map) : {};

  Map<String, dynamic> get _ded =>
      _b['deductions'] is Map ? Map<String, dynamic>.from(_b['deductions'] as Map) : {};

  bool get _isOnProbation => _b['isOnProbation'] == true;
  double get _proRata => (_b['proRata'] as num?)?.toDouble() ?? 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          Container(
            color: kPrimary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
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
                          const Text(
                            'OFFICIAL PAYSLIP',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            slip['periodLabel']?.toString() ?? slip['period']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${slip['employee'] ?? ''} · ${slip['employeeCode'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _panel(
                  children: [
                    _row('Department', '${slip['department'] ?? '—'}'),
                    _row('Designation', '${slip['designation'] ?? '—'}'),
                    _row('Pay basis', '${slip['payBasis'] ?? 'Monthly'}'),
                    _row('Attendance', '${_b['presentDays'] ?? 0}/${_b['workingDays'] ?? 0} days'),
                    _row('Paid leave / Unpaid', '${_b['paidLeaveDays'] ?? 0} / ${_b['unpaidLeaveDays'] ?? 0}'),
                    _row('Late days', '${_b['lateDays'] ?? 0}'),
                    if (_isOnProbation) _row('Probation', 'On probation — PF waived'),
                    if (_proRata < 0.99) _row('Pro-rata', '${(_proRata * 100).round()}% of month'),
                    _row('Status', '${slip['status'] ?? ''}'),
                    if (slip['payDate'] != null) _row('Pay date', '${slip['payDate']}'.substring(0, 10)),
                    if (slip['bankAccount'] != null && '${slip['bankAccount']}'.isNotEmpty)
                      _row('Bank account', '${slip['bankName'] ?? ''} — ${slip['bankAccount']}'),
                  ],
                ),
                const SizedBox(height: 12),
                _section('Earnings', [
                  ['Basic salary', _n(_earn['basic'] ?? slip['base'])],
                  ['House rent allowance', _n(_earn['houseAllowance'])],
                  ['Transport allowance', _n(_earn['transportAllowance'])],
                  ['Medical allowance', _n(_earn['medicalAllowance'])],
                  ['Overtime', _n(_earn['overtime'] ?? slip['overtime'])],
                  ['Bonus / incentive', _n(_earn['bonus'])],
                  ['Commission', _n(_earn['commission'])],
                  ['Gross earnings', _n(_earn['gross'] ?? slip['base'])],
                ]),
                const SizedBox(height: 12),
                _section('Deductions', [
                  ['Unpaid / absent days', _n(_ded['unpaidLeave'])],
                  ['Late arrival', _n(_ded['late'])],
                  ['Income tax (FBR slab)', _n(_ded['incomeTax'] ?? _ded['tax'])],
                  ['EOBI employee', _n(_ded['eobi'])],
                  ['Provident fund', _n(_ded['providentFund'])],
                  ['Loan / advance', _n(_ded['loan'])],
                  ['Other deduction', _n(_ded['otherCut'])],
                  ['Total deductions', _n(_ded['total'] ?? slip['deductions'])],
                ], negative: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Net take-home',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        _money.format(_n(slip['net'])),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE4EE)),
      ),
      child: Column(children: children),
    );
  }

  Widget _section(String title, List<List<dynamic>> rows, {bool negative = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE4EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: kSubText,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map((r) => _row(
                r[0] as String,
                '${negative && (r[1] as double) > 0 ? '-' : ''}${_money.format(r[1] as double)}',
              )),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: kSubText, fontSize: 12))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
