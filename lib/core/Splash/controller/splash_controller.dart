// lib/core/Splash/controller/splash_controller.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/Onboarding/views/Onboarding_screen.dart';
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

    if (token != null && token.isNotEmpty) {
      final fy = Get.isRegistered<FiscalYearController>()
          ? Get.find<FiscalYearController>()
          : Get.put(FiscalYearController(), permanent: true);
      // Force so we always hydrate FY before dashboard (avoids empty first paint).
      await fy.ensureFiscalYearsLoaded(force: true);
    }

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
