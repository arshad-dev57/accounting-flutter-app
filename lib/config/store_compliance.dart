import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store billing rules.
/// Android: Google Play Billing (required for digital subscriptions).
/// iOS release: no website checkout button (StoreKit not wired yet).
class StoreCompliance {
  StoreCompliance._();

  static const playPackageName = 'com.bisonstechs.app';

  static bool get usesPlayBilling =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get mustChargeViaPlay => usesPlayBilling && kReleaseMode;

  static bool get blocksInAppDigitalPurchase =>
      kReleaseMode &&
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS;

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

  static Future<void> openPlaySubscriptionManagement() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions?package=$playPackageName',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
