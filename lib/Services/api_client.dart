// lib/Services/api_client.dart

import 'dart:async';
import 'dart:convert';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/FiscalYear/utils/fiscal_year_dates.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';

class ApiResponse {
  final int statusCode;
  final dynamic data;
  final bool success;
  final String message;
  final bool isFiscalYearError;

  ApiResponse({
    required this.statusCode,
    required this.data,
    required this.success,
    required this.message,
    this.isFiscalYearError = false,
  });
}

class ApiClient extends GetxService {
  final String baseUrl = Apiconfig().baseUrl;
  String? _cachedToken;
  String? _cachedRefreshToken;
  bool _isRefreshing = false;
  final List<Completer<String>> _pendingRequests = [];

  // ✅ Clean token helper
  String? _cleanToken(String? token) {
    if (token == null || token.isEmpty) return null;
    return token.trim().replaceAll('"', '').replaceAll(RegExp(r'\s'), '');
  }

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final refresh = prefs.getString('refresh_token');

    _cachedToken = _cleanToken(token);
    _cachedRefreshToken = _cleanToken(refresh);
  }

  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = _cleanToken(token) ?? token;
    await prefs.setString('auth_token', clean);
    _cachedToken = clean;
  }

  Future<void> setRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = _cleanToken(refreshToken) ?? refreshToken;
    await prefs.setString('refresh_token', clean);
    _cachedRefreshToken = clean;
  }

  Future<void> setBothTokens(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanToken = _cleanToken(token) ?? token;
    final cleanRefresh = _cleanToken(refreshToken) ?? refreshToken;

    await prefs.setString('auth_token', cleanToken);
    await prefs.setString('refresh_token', cleanRefresh);

    _cachedToken = cleanToken;
    _cachedRefreshToken = cleanRefresh;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    _cachedToken = null;
    _cachedRefreshToken = null;
    try {
      if (Get.isRegistered<FiscalYearController>()) {
        await Get.find<FiscalYearController>().clearSession();
      }
    } catch (_) {}
  }

  Future<String?> getToken() async {
    if (_cachedToken == null || _cachedToken!.isEmpty) {
      await _loadToken();
    }
    return _cachedToken;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken == null || _cachedRefreshToken!.isEmpty) {
      await _loadToken();
    }
    return _cachedRefreshToken;
  }

  Future<ApiResponse> _refreshTokenRequest() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return ApiResponse(
        statusCode: 401,
        data: null,
        success: false,
        message: 'No refresh token available',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/users/refresh-token'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      final decodedData = json.decode(response.body);

      if (response.statusCode == 200 && decodedData['success'] == true) {
        final newToken = decodedData['token']?.toString() ?? '';
        final newRefreshToken = decodedData['refreshToken']?.toString() ?? '';

        if (newToken.isNotEmpty) {
          await setBothTokens(newToken, newRefreshToken);
          return ApiResponse(
            statusCode: 200,
            data: decodedData,
            success: true,
            message: 'Token refreshed successfully',
          );
        }
      }

      await clearToken();
      return ApiResponse(
        statusCode: response.statusCode,
        data: decodedData,
        success: false,
        message: decodedData['message'] ?? 'Failed to refresh token',
      );
    } catch (e) {
      await clearToken();
      return ApiResponse(
        statusCode: 500,
        data: null,
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse> _executeRequest(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
    int retryCount = 0,
  }) async {
    if (!requiresAuth) {
      return _makeRequest(
        method,
        endpoint,
        body: body,
        queryParameters: queryParameters,
        requiresAuth: false,
      );
    }

    final token = await getToken();
    if (token == null || token.isEmpty) {
      return ApiResponse(
        statusCode: 401,
        data: null,
        success: false,
        message: 'No authentication token available',
      );
    }

    ApiResponse response = await _makeRequest(
      method,
      endpoint,
      body: body,
      queryParameters: queryParameters,
      requiresAuth: true,
    );

    if (response.statusCode == 401 && retryCount == 0) {
      final message = response.message?.toLowerCase() ?? '';
      final isTokenExpired =
          message.contains('expired') ||
          message.contains('invalid token') ||
          message.contains('malformed');

      if (isTokenExpired) {
        if (_isRefreshing) {
          final completer = Completer<String>();
          _pendingRequests.add(completer);
          await completer.future;
          return _makeRequest(
            method,
            endpoint,
            body: body,
            queryParameters: queryParameters,
            requiresAuth: true,
          );
        }

        _isRefreshing = true;
        try {
          final refreshResponse = await _refreshTokenRequest();
          if (refreshResponse.success) {
            final newToken = await getToken() ?? '';
            for (var completer in _pendingRequests) {
              completer.complete(newToken);
            }
            _pendingRequests.clear();

            return await _makeRequest(
              method,
              endpoint,
              body: body,
              queryParameters: queryParameters,
              requiresAuth: true,
            );
          } else {
            await clearToken();
            for (var completer in _pendingRequests) {
              completer.completeError('Session expired');
            }
            _pendingRequests.clear();

            return ApiResponse(
              statusCode: 401,
              data: null,
              success: false,
              message: 'Session expired. Please login again.',
            );
          }
        } finally {
          _isRefreshing = false;
        }
      }
    }

    return response;
  }

  Future<ApiResponse> _makeRequest(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(requiresAuth);
      Uri uri = Uri.parse('$baseUrl$endpoint');

      // Keep any query already on the endpoint (e.g. /api/sales/invoices?page=1)
      var params = <String, dynamic>{
        ...uri.queryParameters,
        if (queryParameters != null) ...queryParameters,
      };

      // Attach selected fiscal year on whitelisted GETs (mirrors Next.js interceptor)
      if (method.toUpperCase() == 'GET' && shouldAttachFiscalYear(endpoint)) {
        if (!params.containsKey('fiscalYearId') ||
            params['fiscalYearId'] == null ||
            params['fiscalYearId'].toString().isEmpty) {
          final fyId = _resolveSelectedFiscalYearId();
          if (fyId != null && fyId.isNotEmpty) {
            params['fiscalYearId'] = fyId;
          }
        }
      }

      if (params.isNotEmpty) {
        final stringParams = params.map(
          (key, value) => MapEntry(key, value.toString()),
        );
        uri = uri.replace(queryParameters: stringParams);
      }

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method');
      }

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        data: null,
        success: false,
        message: e.toString(),
      );
    }
  }

  String? _resolveSelectedFiscalYearId() {
    try {
      if (!Get.isRegistered<FiscalYearController>()) return null;
      return Get.find<FiscalYearController>().selectedFiscalYearId;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _getHeaders(bool requiresAuth) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  ApiResponse _processResponse(http.Response response) {
    try {
      final decodedData = json.decode(response.body);

      // Handle 403 errors (Fiscal year or Subscription)
      if (response.statusCode == 403) {
        final message = decodedData['message'] ?? '';
        final code = decodedData['code'] ?? '';

        // Handle subscription expiry/required errors
        if (code == 'SUBSCRIPTION_REQUIRED') {
          // Show warning toast
          AppSnackbar.error(
            kDanger,
            'Subscription Required',
            message.isNotEmpty ? message : 'Your subscription has expired.',
          );

          Future.delayed(const Duration(milliseconds: 300), () {
            Get.offAll(() => const SelectPlanScreen());
          });

          return ApiResponse(
            statusCode: 403,
            data: decodedData,
            success: false,
            message: message,
          );
        }

        // Handle fiscal year errors
        if (message.toLowerCase().contains('fiscal year') ||
            message.toLowerCase().contains('closed')) {
          return ApiResponse(
            statusCode: 403,
            data: decodedData,
            success: false,
            message: message,
            isFiscalYearError: true,
          );
        }
      }

      if (response.statusCode == 401) {
        return ApiResponse(
          statusCode: 401,
          data: decodedData,
          success: false,
          message:
              decodedData['message'] ?? 'Session expired. Please login again.',
        );
      }

      final isSuccess =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          (decodedData is Map && decodedData.containsKey('success')
              ? decodedData['success'] == true
              : true);

      return ApiResponse(
        statusCode: response.statusCode,
        data: decodedData,
        success: isSuccess,
        message: decodedData is Map && decodedData.containsKey('message')
            ? decodedData['message']
            : '',
      );
    } catch (e) {
      return ApiResponse(
        statusCode: response.statusCode,
        data: response.body,
        success: response.statusCode >= 200 && response.statusCode < 300,
        message: 'Non-JSON response',
      );
    }
  }

  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    return _executeRequest(
      'GET',
      endpoint,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> post(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _executeRequest(
      'POST',
      endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> put(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _executeRequest(
      'PUT',
      endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> patch(
    String endpoint, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _executeRequest(
      'PATCH',
      endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  Future<ApiResponse> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    return _executeRequest('DELETE', endpoint, requiresAuth: requiresAuth);
  }

  // Multipart POST request
  Future<ApiResponse> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, String>? filePaths, // key: fieldName, value: filePath
    Map<String, List<String>>? multiFilePaths, // multiple files same field (e.g. images)
    bool requiresAuth = true,
  }) async {
    return _executeMultipartRequest(
      'POST',
      endpoint,
      fields,
      filePaths,
      multiFilePaths,
      requiresAuth,
    );
  }

  // Multipart PUT request
  Future<ApiResponse> putMultipart(
    String endpoint, {
    required Map<String, String> fields,
    Map<String, String>? filePaths, // key: fieldName, value: filePath
    Map<String, List<String>>? multiFilePaths,
    bool requiresAuth = true,
  }) async {
    return _executeMultipartRequest(
      'PUT',
      endpoint,
      fields,
      filePaths,
      multiFilePaths,
      requiresAuth,
    );
  }

  Future<ApiResponse> _executeMultipartRequest(
    String method,
    String endpoint,
    Map<String, String> fields,
    Map<String, String>? filePaths,
    Map<String, List<String>>? multiFilePaths,
    bool requiresAuth,
  ) async {
    try {
      Uri uri = Uri.parse('$baseUrl$endpoint');
      var request = http.MultipartRequest(method, uri);

      if (requiresAuth) {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Add text fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add single files
      if (filePaths != null) {
        for (var entry in filePaths.entries) {
          if (entry.value.isNotEmpty) {
            request.files.add(
              await http.MultipartFile.fromPath(entry.key, entry.value),
            );
          }
        }
      }

      // Add multi files (same field name, e.g. images[])
      if (multiFilePaths != null) {
        for (var entry in multiFilePaths.entries) {
          for (final path in entry.value) {
            if (path.isNotEmpty) {
              request.files.add(
                await http.MultipartFile.fromPath(entry.key, path),
              );
            }
          }
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } catch (e) {
      return ApiResponse(
        statusCode: 500,
        data: null,
        success: false,
        message: e.toString(),
      );
    }
  }
}
