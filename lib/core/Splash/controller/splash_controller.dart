// lib/core/Splash/controller/splash_controller.dart

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
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
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      if (token == null || token.isEmpty) {
        if (kIsWeb) {
          Get.offAllNamed('/login');
        } else if (hasSeenOnboarding) {
          Get.offAllNamed('/login');
        } else {
          Get.offAll(() => const OnboardingScreen());
        }
        return;
      }

      final sub = Get.isRegistered<SubscriptionController>()
          ? Get.find<SubscriptionController>()
          : Get.put(SubscriptionController(), permanent: true);

      // Splash only: live subscription check → route. FY / locations load later on screens.
      final statusOk = await sub.checkSubscriptionStatus();

      if (!statusOk) {
        AppSnackbar.error(
          kDanger,
          'Connection issue',
          'Could not verify your plan. Please login again.',
        );
        Get.offAllNamed('/login');
        return;
      }

      if (!sub.hasAccess) {
        Get.offAll(() => const SelectPlanScreen());
      } else {
        if (Get.isRegistered<PermissionService>()) {
          await PermissionService.to.loadUserData();
        }
        sub.goToAppHome();
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      Get.offAllNamed('/login');
    }
  }
}
