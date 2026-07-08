// lib/Services/stripe_web_helper.dart
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;

// ✅ Browser ko Stripe checkout page par redirect karo
void redirectToStripe(String url) {
  html.window.location.href = url;
}