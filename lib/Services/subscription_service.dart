import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:LedgerPro_app/config/apiconfig.dart';

class SubscriptionService {
  final String baseUrl = Apiconfig().baseUrl;

  // ─── Get Auth Token ──────────────────────────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ─── Build Auth Headers ───────────────────────────────────────────
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1️⃣ GET SUBSCRIPTION PLANS
  // GET /api/subscription/plans
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getPlans() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/plans'),
        headers: headers,
      );
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 2️⃣ CHECK SUBSCRIPTION STATUS
  // GET /api/subscription/status
  // Returns: { success, data: { hasAccess, subscription: { plan, status,
  //            trialDaysRemaining, subscriptionDaysRemaining, ... } } }
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> checkSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/status'),
        headers: headers,
      );
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 3️⃣ START 30-DAY FREE TRIAL
  // POST /api/subscription/trial/start
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> startTrial() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/subscription/trial/start'),
        headers: headers,
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'] ?? '30-day trial started! 🎉',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to start trial',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 4️⃣ DIRECT SUBSCRIPTION — NO STRIPE
  // POST /api/subscription/subscribe
  // Body: { plan: 'monthly'|'yearly', amount: double }
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> subscribeDirect({
    required String plan,
    required double amount,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      final headers = await _getHeaders();

      print('[SubscriptionService] Subscribing to plan: $plan (amount: $amount)');

      final response = await http.post(
        Uri.parse('$baseUrl/api/subscription/subscribe'),
        headers: headers,
        body: json.encode({
          'plan': plan,
          'amount': amount,
          'paymentMethod': paymentMethod ?? 'direct',
          'transactionId':
              transactionId ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      print('[SubscriptionService] Response ${response.statusCode}: ${response.body}');

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'] ?? data,
          'message': data['message'] ?? 'Subscription activated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to activate subscription',
        };
      }
    } catch (e) {
      print('[SubscriptionService] Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 5️⃣ CANCEL SUBSCRIPTION
  // POST /api/subscription/cancel
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/subscription/cancel'),
        headers: headers,
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Subscription cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to cancel subscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 6️⃣ GET SUBSCRIPTION HISTORY
  // GET /api/subscription/history
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getSubscriptionHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/history'),
        headers: headers,
      );
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 7️⃣ VALIDATE SUBSCRIPTION ACCESS (lightweight)
  // GET /api/subscription/validate
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> validateAccess() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/validate'),
        headers: headers,
      );
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'hasAccess': false,
        'message': e.toString(),
      };
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // 8️⃣ GET DETAILED SUBSCRIPTION INFO
  // GET /api/subscription/details
  // ═══════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getSubscriptionDetails() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/details'),
        headers: headers,
      );
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}