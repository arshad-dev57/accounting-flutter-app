import 'package:flutter/foundation.dart';

class Apiconfig {
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');
  static const String _webFromEnv = String.fromEnvironment('WEB_APP_URL');

  static const String productionApiUrl =
      'https://accountbackend-production-eaf5.up.railway.app';
  static const String productionWebAppUrl = 'https://app.bisonstechs.com';
  static const String localApiUrl = 'http://localhost:5000';

  /// Release / store builds always hit production unless `--dart-define` overrides.
  /// Debug keeps localhost so local backend still works.
  String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (kReleaseMode) return productionApiUrl;
    return localApiUrl;
  }

  String get webAppUrl {
    if (_webFromEnv.isNotEmpty) return _webFromEnv;
    return productionWebAppUrl;
  }
}
