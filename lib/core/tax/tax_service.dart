import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:get/get.dart';

class TaxService {
  final ApiClient _api = Get.find<ApiClient>();

  Future<ApiResponse> context() => _api.get('/api/tax/context');
  Future<ApiResponse> overview() => _api.get('/api/tax/overview');
  Future<ApiResponse> setEnabled(bool enabled) =>
      _api.put('/api/tax/enabled', body: {'enabled': enabled});
  Future<ApiResponse> setup(Map<String, dynamic> body) =>
      _api.post('/api/tax/setup', body: body);
  Future<ApiResponse> saveProfile(Map<String, dynamic> body) =>
      _api.put('/api/tax/profile', body: body);

  Future<ApiResponse> types() => _api.get('/api/tax/types');
  Future<ApiResponse> createType(Map<String, dynamic> body) =>
      _api.post('/api/tax/types', body: body);

  Future<ApiResponse> jurisdictions() => _api.get('/api/tax/jurisdictions');
  Future<ApiResponse> createJurisdiction(Map<String, dynamic> body) =>
      _api.post('/api/tax/jurisdictions', body: body);

  Future<ApiResponse> rates() => _api.get('/api/tax/rates');
  Future<ApiResponse> createRate(Map<String, dynamic> body) =>
      _api.post('/api/tax/rates', body: body);
  Future<ApiResponse> updateRate(String id, Map<String, dynamic> body) =>
      _api.put('/api/tax/rates/$id', body: body);

  Future<ApiResponse> exemptionTypes() => _api.get('/api/tax/exemption-types');
  Future<ApiResponse> createExemptionType(Map<String, dynamic> body) =>
      _api.post('/api/tax/exemption-types', body: body);
  Future<ApiResponse> exemptions() => _api.get('/api/tax/exemptions');
  Future<ApiResponse> createExemption(Map<String, dynamic> body) =>
      _api.post('/api/tax/exemptions', body: body);

  Future<ApiResponse> liability({String? startDate, String? endDate}) {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    return _api.get('/api/tax/reports/liability', queryParameters: params);
  }
}
