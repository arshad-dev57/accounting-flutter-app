import 'package:BisonsTechs_app/core/warehouse/locations/location_query.dart';
import 'package:BisonsTechs_app/core/warehouse/widgets/location_switcher.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocationScopeController extends GetxController {
  final route = ''.obs;

  void setRoute(String value) {
    if (route.value == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (route.value != value) route.value = value;
    });
  }

  bool shouldShow(String route) {
    if (route.isEmpty || route == '/') return false;

    final r = route.toLowerCase();

    // Named routes + unnamed Get.to(() => Widget) routes like /LoginScreen
    const hiddenFragments = [
      'login',
      'register',
      'registration',
      'onboarding',
      'splash',
      'forgot',
      'reset-password',
      'resetpassword',
      'otp',
      'selectplan',
      'subscription',
      '/plans',
    ];
    for (final fragment in hiddenFragments) {
      if (r.contains(fragment)) return false;
    }

    if (_routeHasOwnLocationHeader(route)) return false;
    return true;
  }
}

bool _routeHasOwnLocationHeader(String route) {
  const ownHeader = [
    '/accounting/dashboard',
    '/warehouse/dashboard',
    '/warehouse/sales',
    '/purchase/dashboard',
  ];
  for (final path in ownHeader) {
    if (route == path || route.startsWith('$path/')) return true;
  }
  return false;
}

/// Persistent location header (web layout parity — all module screens).
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
      final r = scope.route.value;
      final show = scope.shouldShow(r);
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: LocationSwitcher(
                      compact: true,
                      showManageLink: true,
                      allowAll: routeAllowsAllLocations(r),
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
