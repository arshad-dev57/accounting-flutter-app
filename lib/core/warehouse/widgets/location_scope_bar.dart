import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/warehouse/widgets/location_switcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocationScopeController extends GetxController {
  final route = ''.obs;

  void setRoute(String value) {
    if (route.value == value) return;
    // routingCallback fires during navigator build — defer Rx update.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route.value != value) route.value = value;
    });
  }

  bool get shouldShow {
    final r = route.value;
    if (r.isEmpty || r == '/') return false;
    const hidden = [
      '/login',
      '/register',
      '/onboarding',
      '/plans',
      '/forgot-password',
      '/reset-password',
      '/otp',
      '/login-otp',
    ];
    for (final path in hidden) {
      if (r == path || r.startsWith('$path/')) return false;
    }
    return true;
  }
}

/// Persistent location header for every signed-in screen (Next.js layout parity).
class LocationScopeHost extends StatelessWidget {
  final Widget child;
  const LocationScopeHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<LocationScopeController>()) {
      Get.put(LocationScopeController(), permanent: true);
    }
    final scope = Get.find<LocationScopeController>();

    return Obx(() {
      final show = scope.shouldShow;
      return Column(
        children: [
          if (show)
            Material(
              color: Colors.white,
              elevation: 0.4,
              child: SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE8EBF0)),
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: LocationSwitcher(
                      compact: true,
                      showManageLink: true,
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: show,
              child: child,
            ),
          ),
        ],
      );
    });
  }
}
