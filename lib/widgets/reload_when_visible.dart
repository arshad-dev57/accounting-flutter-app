import 'package:flutter/material.dart';
import 'package:get/get.dart';

final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Reloads when the page is first shown and when the user returns to it.
mixin ReloadWhenVisible<T extends StatefulWidget> on State<T>, RouteAware {
  void reloadOnOpen();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) reloadOnOpen();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() => reloadOnOpen();
}

/// Drops a cached GetX controller so the next [Get.put] runs [onInit] again.
void openFresh<C extends GetxController>(Widget page) {
  if (Get.isRegistered<C>()) {
    Get.delete<C>(force: true);
  }
  Get.to(() => page);
}
