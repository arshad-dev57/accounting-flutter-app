import 'package:BisonsTechs_app/Services/network_lookup.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkConnectivity {
  NetworkConnectivity._();

  static final Connectivity _connectivity = Connectivity();
  static DateTime? _lastOnlineAt;
  static DateTime? _lastOfflineToastAt;

  static const _onlineCacheTtl = Duration(seconds: 6);
  static const _toastCooldown = Duration(seconds: 4);
  static const _checkTimeout = Duration(seconds: 2);

  static const offlineMessage =
      'No internet connection. Please check your network and try again.';

  /// Returns true when the device has a usable network path.
  ///
  /// Fail-open: if the plugin / DNS probe hangs or errors, return true so
  /// the real HTTP call can proceed (and surface its own timeout/error).
  static Future<bool> hasConnection({bool forceCheck = false}) async {
    try {
      if (!forceCheck &&
          _lastOnlineAt != null &&
          DateTime.now().difference(_lastOnlineAt!) < _onlineCacheTtl) {
        return true;
      }

      final results = await _connectivity
          .checkConnectivity()
          .timeout(_checkTimeout);
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _lastOnlineAt = null;
        return false;
      }

      final reachable = await probeDnsReachability().timeout(_checkTimeout);
      if (reachable) {
        _lastOnlineAt = DateTime.now();
        return true;
      }

      _lastOnlineAt = null;
      return false;
    } catch (_) {
      // Plugin hang/timeout/error — don't block API calls.
      return true;
    }
  }

  static void notifyOffline({String? message}) {
    final now = DateTime.now();
    if (_lastOfflineToastAt != null &&
        now.difference(_lastOfflineToastAt!) < _toastCooldown) {
      return;
    }
    _lastOfflineToastAt = now;
    AppSnackbar.error(
      kDanger,
      'No Internet',
      message ?? offlineMessage,
    );
  }

  static bool looksLikeNetworkError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused') ||
        text.contains('connection reset') ||
        text.contains('connection timed out') ||
        text.contains('timed out') ||
        text.contains('clientexception') ||
        text.contains('xmlhttprequest error') ||
        text.contains('networkerror') ||
        text.contains('failed to fetch');
  }
}
