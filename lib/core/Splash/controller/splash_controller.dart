// lib/core/Splash/controller/splash_controller.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

import 'package:BisonsTechs_app/core/FiscalYear/controller/fiscal_year_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/location_query.dart';
import 'package:BisonsTechs_app/core/Onboarding/views/Onboarding_screen.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
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

      // Prefer companyId from user blob if present
      try {
        final raw = prefs.getString('user') ?? prefs.getString('user_data');
        if (raw != null && raw.isNotEmpty) {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final companyId = map['companyId']?.toString();
          if (companyId != null && companyId.isNotEmpty) {
            final loc = ensureLocationController();
            await loc?.ensureLocationsLoaded(force: true);
          }
        } else {
          final loc = ensureLocationController();
          await loc?.ensureLocationsLoaded(force: true);
        }
      } catch (_) {
        final loc = ensureLocationController();
        await loc?.ensureLocationsLoaded(force: true);
      }

      final sub = Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : Get.put(SubscriptionController(), permanent: true);
      await sub.checkSubscriptionStatus();

      if (!sub.hasAccess) {
        Get.offAll(() => const SelectPlanScreen());
      } else {
        sub.goToAppHome();
      }
      return;
    }

    if (kIsWeb) {
      Get.offAllNamed('/login');
    } else if (hasSeenOnboarding) {
      Get.offAllNamed('/login');
    } else {
      Get.offAll(() => const OnboardingScreen());
    }
  }
}
