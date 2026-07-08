// lib/core/Splash/controller/splash_controller.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:LedgerPro_app/core/Onboarding/views/Onboarding_screen.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    checkToken();
  }

  void checkToken() async {
    await Future.delayed(const Duration(seconds: 2));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');
    bool? hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (kIsWeb) {
      // Web Flow
      if (token != null && token.isNotEmpty) {
        Get.offAllNamed('/dashboard');
      } else {
        Get.offAllNamed('/login');
      }
    } else {
      // Mobile Flow
      if (token != null && token.isNotEmpty) {
        Get.offAllNamed('/dashboard');
      } else if (hasSeenOnboarding) {
        Get.offAllNamed('/login');
      } else {
        Get.offAll(() => const OnboardingScreen());
      }
    }
  }
}
