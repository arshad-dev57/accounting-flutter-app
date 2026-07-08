import 'dart:convert';
import 'package:LedgerPro_app/Utils/stripe_web_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/apiconfig.dart';

// ✅ Web only import — Android/iOS par error nahi dega

class SubscriptionService {
  final String baseUrl = Apiconfig().baseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get subscription plans
  Future<Map<String, dynamic>> getPlans() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/plans'),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Check current subscription status
  Future<Map<String, dynamic>> checkSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/status'),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  Future<Map<String, dynamic>> createStripeCheckout({
    required String plan,
  }) async {
    if (!kIsWeb) {
      return {
        'success': false,
        'message': 'Stripe checkout is only available on web',
      };
    }

    try {
      final headers = await _getHeaders();

      final apiUrl = '$baseUrl/api/subscription/stripe/checkout';

      print("🌐 BASE URL => $baseUrl");
      print("🚀 API URL => $apiUrl");
      print("📋 PLAN => $plan");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode({'plan': plan}),
      );

      print("📡 STATUS CODE => ${response.statusCode}");
      print("📨 RAW RESPONSE => ${response.body}");

      final data = json.decode(response.body);

      print("✅ DECODED RESPONSE => $data");

      if (data['success'] == true) {
        final checkoutUrl = data['data']?['checkoutUrl'];

        print("💳 CHECKOUT URL => $checkoutUrl");

        if (checkoutUrl == null || checkoutUrl.toString().isEmpty) {
          print("❌ checkoutUrl null ya empty hai");
          return {
            'success': false,
            'message': 'Checkout URL missing',
          };
        }



        if (!checkoutUrl.toString().startsWith('http')) {
          print("❌ Invalid URL Schema => $checkoutUrl");
          return {
            'success': false,
            'message': 'Invalid checkout URL',
          };
        }

        print("➡️ Redirecting to Stripe...");
        redirectToStripe(checkoutUrl);
      } else {
        print("❌ Backend Success False");
      }

      return data;
    } catch (e) {
      print("🔥 ERROR IN STRIPE CHECKOUT => $e");

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Manual subscription (fallback / admin use)
  Future<Map<String, dynamic>> createSubscription({
    required String plan,
    required double amount,
    String? paymentMethod,
    String? transactionId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/subscription/create'),
        headers: headers,
        body: json.encode({
          'plan': plan,
          'amount': amount,
          'paymentMethod': paymentMethod ?? 'in_app_purchase',
          'transactionId': transactionId ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}',
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/subscription/cancel'),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get subscription history
  Future<Map<String, dynamic>> getSubscriptionHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscription/history'),
        headers: headers,
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}