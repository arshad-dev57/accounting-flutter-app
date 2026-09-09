import 'dart:async';
import 'dart:convert';

import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HrTrackingApi {
  HrTrackingApi._();
  static final HrTrackingApi instance = HrTrackingApi._();

  final _config = Apiconfig();

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Uri _uri(String path) {
    final base = _config.webAppUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path');
  }

  Future<Map<String, dynamic>> pingLocation({
    required String employeeId,
    required String employeeName,
    required double latitude,
    required double longitude,
    String? officeName,
    double? accuracy,
    double? speed,
    double? battery,
    double? heading,
    bool isBackground = false,
  }) async {
    final token = await _token();
    final res = await http.post(
      _uri('/api/hr/tracking'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'employeeId': employeeId,
        'employeeName': employeeName,
        'officeName': officeName,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'battery': battery,
        'heading': heading,
        'isBackground': isBackground,
      }),
    );

    final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
    if (res.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Location ping failed (${res.statusCode})');
    }
    return Map<String, dynamic>.from(body['data'] ?? body);
  }

  Future<List<Map<String, dynamic>>> fetchLive() async {
    final token = await _token();
    final res = await http.get(
      _uri('/api/hr/tracking'),
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
    if (res.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load live tracking');
    }
    final live = body['data']?['live'];
    if (live is! List) return [];
    return live.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
