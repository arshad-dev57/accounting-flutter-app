import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:get/get.dart';

class HrApiService {
  HrApiService._();
  static final HrApiService instance = HrApiService._();

  ApiClient get _api {
    if (Get.isRegistered<ApiClient>()) return Get.find<ApiClient>();
    return Get.put(ApiClient(), permanent: true);
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> _unwrap(
    String method,
    String path, {
    dynamic body,
  }) async {
    final res = method == 'GET'
        ? await _api.get(path)
        : method == 'PUT'
            ? await _api.put(path, body: body)
            : await _api.post(path, body: body);
    final raw = _map(res.data);
    if (!res.success || raw['success'] == false) {
      throw Exception(raw['message'] ?? res.message);
    }
    final data = raw['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return raw;
  }

  Future<List<Map<String, dynamic>>> _unwrapList(String path) async {
    final res = await _api.get(path);
    final raw = _map(res.data);
    if (!res.success || raw['success'] == false) {
      throw Exception(raw['message'] ?? res.message);
    }
    return _list(raw['data']);
  }

  Future<Map<String, dynamic>> _unwrapRaw(String path) async {
    final res = await _api.get(path);
    final raw = _map(res.data);
    if (!res.success || raw['success'] == false) {
      throw Exception(raw['message'] ?? res.message);
    }
    return raw;
  }

  // ── Core ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> me() => _unwrap('GET', '/api/hr/me');

  Future<Map<String, dynamic>> dashboard() =>
      _unwrap('GET', '/api/hr/dashboard');

  Future<List<Map<String, dynamic>>> offices() =>
      _unwrapList('/api/hr/offices');

  Future<Map<String, dynamic>> createOffice(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/offices', body: body);

  Future<Map<String, dynamic>> updateOffice(
    String id,
    Map<String, dynamic> body,
  ) =>
      _unwrap('PUT', '/api/hr/offices/$id', body: body);

  Future<List<Map<String, dynamic>>> employees() =>
      _unwrapList('/api/hr/employees');

  Future<Map<String, dynamic>> createEmployee(Map<String, dynamic> body) async {
    final res = await _api.post('/api/hr/employees', body: body);
    final raw = _map(res.data);
    if (!res.success || raw['success'] == false) {
      throw Exception(raw['message'] ?? res.message);
    }
    return raw;
  }

  Future<Map<String, dynamic>> updateEmployee(
    String id,
    Map<String, dynamic> body,
  ) =>
      _unwrap('PUT', '/api/hr/employees/$id', body: body);

  Future<Map<String, dynamic>> employeeById(String id) =>
      _unwrap('GET', '/api/hr/employees/$id');

  Future<Map<String, dynamic>> employeeDossier(String id) =>
      _unwrap('GET', '/api/hr/employees/$id/dossier');

  // ── Attendance ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> listAttendance({String? date}) =>
      _unwrapList(
        '/api/hr/attendance${date != null ? '?date=${Uri.encodeComponent(date)}' : ''}',
      );

  Future<Map<String, dynamic>> attendanceSummary({String? date}) =>
      _unwrapRaw(
        '/api/hr/attendance/summary${date != null ? '?date=${Uri.encodeComponent(date)}' : ''}',
      );

  Future<Map<String, dynamic>> myAttendance() =>
      _unwrap('GET', '/api/hr/attendance/me');

  /// HR: create or update an attendance record for any employee on any date.
  Future<Map<String, dynamic>> upsertAttendance(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/attendance/upsert', body: body);

  /// HR: deactivate an employee (soft-delete / set status Inactive).
  Future<Map<String, dynamic>> deactivateEmployee(String id) =>
      _unwrap('PUT', '/api/hr/employees/$id', body: {'status': 'Inactive'});

  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    double? accuracy,
    String source = 'manual',
  }) =>
      _unwrap('POST', '/api/hr/attendance/check-in', body: {
        'latitude': latitude,
        'longitude': longitude,
        'source': source,
        if (accuracy != null) 'accuracy': accuracy,
      });

  Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    String source = 'manual',
  }) =>
      _unwrap('POST', '/api/hr/attendance/check-out', body: {
        'latitude': latitude,
        'longitude': longitude,
        'source': source,
      });

  Future<Map<String, dynamic>> trackingEvent({
    required String event,
    double? latitude,
    double? longitude,
    double? accuracy,
  }) =>
      _unwrap('POST', '/api/hr/tracking', body: {
        'event': event,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      });

  Future<List<Map<String, dynamic>>> liveTracking() async {
    final res = await _api.get('/api/hr/tracking');
    final raw = _map(res.data);
    if (!res.success || raw['success'] == false) {
      throw Exception(raw['message'] ?? res.message);
    }
    final live = raw['data'] is Map ? raw['data']['live'] : raw['live'];
    return _list(live);
  }

  // ── Leaves / overtime / tasks / performance ───────────────────
  Future<List<Map<String, dynamic>>> leaves() =>
      _unwrapList('/api/hr/leaves');

  Future<List<Map<String, dynamic>>> myLeaves() =>
      _unwrapList('/api/hr/leaves/me');

  Future<Map<String, dynamic>> applyLeave({
    required String type,
    required String from,
    required String to,
    required String reason,
  }) =>
      createLeave({
        'type': type,
        'from': from,
        'to': to,
        'reason': reason,
      });

  /// HR can pass `employeeId`; employees omit it (uses own profile).
  Future<Map<String, dynamic>> createLeave(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/leaves', body: body);

  Future<Map<String, dynamic>> updateLeave(String id, String status) =>
      _unwrap('PUT', '/api/hr/leaves/$id', body: {'status': status});

  Future<List<Map<String, dynamic>>> overtime() =>
      _unwrapList('/api/hr/overtime');

  Future<Map<String, dynamic>> requestOvertime({
    required double hours,
    required String date,
    String reason = '',
  }) =>
      _unwrap('POST', '/api/hr/overtime', body: {
        'hours': hours,
        'date': date,
        'reason': reason,
      });

  Future<Map<String, dynamic>> updateOvertime(String id, String status) =>
      _unwrap('PUT', '/api/hr/overtime/$id', body: {'status': status});

  Future<List<Map<String, dynamic>>> tasks() => _unwrapList('/api/hr/tasks');

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/tasks', body: body);

  Future<Map<String, dynamic>> updateTask(
    String id,
    Map<String, dynamic> body,
  ) =>
      _unwrap('PUT', '/api/hr/tasks/$id', body: body);

  Future<List<Map<String, dynamic>>> performance() =>
      _unwrapList('/api/hr/performance');

  Future<Map<String, dynamic>> createReview(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/performance', body: body);

  Future<Map<String, dynamic>> updateReview(
    String id,
    Map<String, dynamic> body,
  ) =>
      _unwrap('PUT', '/api/hr/performance/$id', body: body);

  // ── Payroll / salary build ────────────────────────────────────
  Future<Map<String, dynamic>> payroll({String? period}) async {
    final qs = period != null ? '?period=${Uri.encodeComponent(period)}' : '';
    final raw = await _unwrapRaw('/api/hr/payroll$qs');
    return {
      'items': _list(raw['data']),
      'period': raw['period'],
      'periodLabel': raw['periodLabel'],
      'summary': _map(raw['summary']),
    };
  }

  /// mode: 'all' | 'office' | 'sales'
  Future<Map<String, dynamic>> generatePayroll({String? period, String mode = 'all'}) async {
    final res = await _api.post('/api/hr/payroll/generate', body: {
      if (period != null) 'period': period,
      if (mode != 'all') 'mode': mode,
    });
    final body = _map(res.data);
    if (!res.success || body['success'] == false) {
      throw Exception(body['message'] ?? res.message);
    }
    return {
      'items': _list(body['data']),
      'period': body['period'],
      'periodLabel': body['periodLabel'],
      'summary': _map(body['summary']),
    };
  }

  Future<Map<String, dynamic>> updatePayroll(
    String id,
    Map<String, dynamic> body,
  ) =>
      _unwrap('PUT', '/api/hr/payroll/$id', body: body);

  /// Create a payslip for a single employee (auto from attendance or blank).
  Future<Map<String, dynamic>> createPayrollItem({
    required String employeeId,
    required String period,
    bool blank = false,
  }) =>
      _unwrap('POST', '/api/hr/payroll/item', body: {
        'employeeId': employeeId,
        'period': period,
        'blank': blank,
      });

  /// mode: 'all' | 'office' | 'sales' — only affects matching employees.
  Future<Map<String, dynamic>> bulkPayrollStatus({
    required String period,
    required String status,
    String? payDate,
    String mode = 'all',
  }) async {
    final res = await _api.post('/api/hr/payroll/bulk-status', body: {
      'period': period,
      'status': status,
      if (payDate != null && payDate.isNotEmpty) 'payDate': payDate,
      if (mode != 'all') 'mode': mode,
    });
    final raw = _map(res.data);
    if (!res.success || raw['success'] == false) {
      throw Exception(raw['message'] ?? res.message);
    }
    return {
      'items': _list(raw['data']),
      'period': raw['period'],
      'summary': _map(raw['summary']),
    };
  }

  Future<Map<String, dynamic>> getPayrollRun({String? period}) async {
    final qs = period != null ? '?period=${Uri.encodeComponent(period)}' : '';
    try {
      final raw = await _unwrapRaw('/api/hr/payroll/run$qs');
      return _map(raw['data']);
    } catch (_) {
      return {};
    }
  }

  Future<void> savePayrollRun(Map<String, dynamic> body) async {
    await _api.put('/api/hr/payroll/run', body: body);
  }

  Future<Map<String, dynamic>> myPayroll() async {
    final res = await _api.get('/api/hr/payroll/me');
    final raw = _map(res.data);
    if (!res.success || raw['success'] == false) {
      throw Exception(raw['message'] ?? res.message);
    }
    return {
      'items': _list(raw['data']),
      'year': raw['year'],
      'ytd': raw['ytd'] is Map ? _map(raw['ytd']) : {'net': raw['ytdNet']},
      'ytdNet': raw['ytdNet'],
      'compensation': _map(raw['compensation']),
    };
  }

  Future<Map<String, dynamic>> getPayslip(String id) =>
      _unwrap('GET', '/api/hr/payroll/$id');

  Future<Map<String, dynamic>> payrollReport({String? period}) async {
    final qs = period != null ? '?period=${Uri.encodeComponent(period)}' : '';
    return _unwrapRaw('/api/hr/payroll/report$qs');
  }

  // ── Org / settings / notifications ────────────────────────────
  Future<Map<String, dynamic>> orgChart() =>
      _unwrap('GET', '/api/hr/org-chart');

  Future<List<Map<String, dynamic>>> notifications() =>
      _unwrapList('/api/hr/notifications');

  Future<Map<String, dynamic>> settings() async {
    final raw = await _unwrapRaw('/api/hr/settings');
    final data = raw['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return raw;
  }

  Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> body) =>
      _unwrap('PUT', '/api/hr/settings', body: body);

  // ── HCM ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> ess() => _unwrap('GET', '/api/hr/hcm/ess');

  Future<Map<String, dynamic>> myTeam() => _unwrap('GET', '/api/hr/hcm/team');

  Future<List<Map<String, dynamic>>> departments() =>
      _unwrapList('/api/hr/org/departments');

  Future<Map<String, dynamic>> saveDepartment(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/org/departments', body: body);

  Future<List<Map<String, dynamic>>> designations() =>
      _unwrapList('/api/hr/org/designations');

  Future<Map<String, dynamic>> saveDesignation(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/org/designations', body: body);

  Future<List<Map<String, dynamic>>> shiftPlans() =>
      _unwrapList('/api/hr/shift-plans');

  Future<Map<String, dynamic>> saveShiftPlan(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/shift-plans', body: body);

  Future<List<Map<String, dynamic>>> holidayCalendar({int? year}) =>
      _unwrapList(
        '/api/hr/holiday-calendar${year != null ? '?year=$year' : ''}',
      );

  Future<Map<String, dynamic>> saveHoliday(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/holiday-calendar', body: body);

  Future<List<Map<String, dynamic>>> leaveTypes() =>
      _unwrapList('/api/hr/leave-types');

  Future<Map<String, dynamic>> saveLeaveType(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/leave-types', body: body);

  Future<List<Map<String, dynamic>>> leaveBalances({String? employeeId}) =>
      _unwrapList(
        '/api/hr/leave-balances${employeeId != null ? '?employeeId=$employeeId' : ''}',
      );

  Future<List<Map<String, dynamic>>> roster({String? from, String? to}) {
    final qs = <String>[];
    if (from != null) qs.add('from=${Uri.encodeComponent(from)}');
    if (to != null) qs.add('to=${Uri.encodeComponent(to)}');
    final q = qs.isEmpty ? '' : '?${qs.join('&')}';
    return _unwrapList('/api/hr/roster$q');
  }

  Future<Map<String, dynamic>> saveRoster(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/roster', body: body);

  Future<List<Map<String, dynamic>>> loans() => _unwrapList('/api/hr/loans');

  Future<Map<String, dynamic>> saveLoan(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/loans', body: body);

  Future<Map<String, dynamic>> updateLoan(String id, String status) =>
      _unwrap('PUT', '/api/hr/loans/$id', body: {'status': status});

  Future<Map<String, dynamic>> requestLoan({
    required double amount,
    required int installments,
    String kind = 'advance',
    String reason = '',
  }) =>
      saveLoan({
        'amount': amount,
        'installments': installments,
        'kind': kind,
        'reason': reason,
      });

  Future<List<Map<String, dynamic>>> bonuses() =>
      _unwrapList('/api/hr/bonuses');

  Future<Map<String, dynamic>> saveBonus(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/bonuses', body: body);

  Future<Map<String, dynamic>> updateBonus(String id, String status) =>
      _unwrap('PUT', '/api/hr/bonuses/$id', body: {'status': status});

  Future<List<Map<String, dynamic>>> documents({String? employeeId}) =>
      _unwrapList(
        '/api/hr/documents${employeeId != null ? '?employeeId=$employeeId' : ''}',
      );

  Future<List<Map<String, dynamic>>> myDocuments() => documents();

  Future<Map<String, dynamic>> saveDocument(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/documents', body: body);

  Future<List<Map<String, dynamic>>> lifecycle({String? employeeId}) =>
      _unwrapList(
        '/api/hr/lifecycle${employeeId != null ? '?employeeId=$employeeId' : ''}',
      );

  Future<Map<String, dynamic>> saveLifecycle(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/lifecycle', body: body);

  Future<List<Map<String, dynamic>>> approvals() =>
      _unwrapList('/api/hr/approvals');

  Future<Map<String, dynamic>> updateApproval(String id, String status) =>
      _unwrap('PUT', '/api/hr/approvals/$id', body: {'status': status});
}
