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

  Future<Map<String, dynamic>> me() => _unwrap('GET', '/api/hr/me');

  Future<Map<String, dynamic>> dashboard() =>
      _unwrap('GET', '/api/hr/dashboard');

  Future<List<Map<String, dynamic>>> offices() =>
      _unwrapList('/api/hr/offices');

  Future<Map<String, dynamic>> createOffice(Map<String, dynamic> body) =>
      _unwrap('POST', '/api/hr/offices', body: body);

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

  Future<Map<String, dynamic>> myAttendance() =>
      _unwrap('GET', '/api/hr/attendance/me');

  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    String source = 'manual',
  }) =>
      _unwrap('POST', '/api/hr/attendance/check-in', body: {
        'latitude': latitude,
        'longitude': longitude,
        'source': source,
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

  Future<List<Map<String, dynamic>>> myLeaves() =>
      _unwrapList('/api/hr/leaves/me');

  Future<Map<String, dynamic>> applyLeave({
    required String type,
    required String from,
    required String to,
    required String reason,
  }) =>
      _unwrap('POST', '/api/hr/leaves', body: {
        'type': type,
        'from': from,
        'to': to,
        'reason': reason,
      });

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

  Future<Map<String, dynamic>> ess() => _unwrap('GET', '/api/hr/hcm/ess');

  Future<Map<String, dynamic>> myTeam() => _unwrap('GET', '/api/hr/hcm/team');

  Future<List<Map<String, dynamic>>> leaveBalances() =>
      _unwrapList('/api/hr/leave-balances');

  Future<List<Map<String, dynamic>>> myDocuments() =>
      _unwrapList('/api/hr/documents');

  Future<List<Map<String, dynamic>>> holidayCalendar() =>
      _unwrapList('/api/hr/holiday-calendar');

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

  Future<Map<String, dynamic>> requestLoan({
    required double amount,
    required int installments,
    String kind = 'advance',
    String reason = '',
  }) =>
      _unwrap('POST', '/api/hr/loans', body: {
        'amount': amount,
        'installments': installments,
        'kind': kind,
        'reason': reason,
      });
}
