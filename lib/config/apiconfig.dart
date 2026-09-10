import 'package:flutter/foundation.dart';

class Apiconfig {
  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');
  static const String _webFromEnv = String.fromEnvironment('WEB_APP_URL');
  static const String productionApiUrl =
      'https://accountbackend-production-eaf5.up.railway.app';
  static const String productionWebAppUrl =
      'https://app.bisonstechs.com';
  static const String localApiUrl = 'http://192.168.18.8:5000';

  String get baseUrl {
    if (_fromEnv.isNotEmpty) {
      return _fromEnv;
    }
    if (kDebugMode) {
      return localApiUrl;
    }
    return productionApiUrl;
  }

  String get webAppUrl {
    if (_webFromEnv.isNotEmpty) {
      return _webFromEnv;
    }
    if (kDebugMode) {
      return 'http://192.168.18.8:3000';
    }
    return productionWebAppUrl;
  }
}