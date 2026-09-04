import 'dart:io';

/// Mobile/desktop: verify real internet via DNS lookup (not just Wi‑Fi/cellular up).
Future<bool> probeDnsReachability() async {
  try {
    final result = await InternetAddress.lookup('one.one.one.one')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  } catch (_) {
    return false;
  }
}
