import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store review / account-ban guardrails.
///
/// Apple 3.1.1 and Google Play Billing: digital subscriptions sold or
/// unlocked from the iOS/Android binary must go through the store.
/// This app bills on the website, so release store builds must not
/// activate a paid plan from an in-app button.
class StoreCompliance {
  StoreCompliance._();

  static bool get isMobileStoreBinary =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static bool get blocksInAppDigitalPurchase =>
      kReleaseMode && isMobileStoreBinary;

  /// Returns `true` when the caller must stop (web checkout was opened).
  static Future<bool> redirectPaidCheckoutIfRequired() async {
    if (!blocksInAppDigitalPurchase) return false;

    final uri = Uri.parse(Apiconfig().webAppUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    AppSnackbar.info(
      'Subscribe on the web',
      opened
          ? 'Paid plans are billed on our website. After you subscribe, return to the app and log in.'
          : 'Open ${Apiconfig().webAppUrl} in a browser to subscribe, then log in here.',
    );
    return true;
  }
}
