import 'package:flutter/material.dart';

/// Light BisonsTechs logo centered on module dashboard hero cards.
class DashboardHeroWatermark extends StatelessWidget {
  const DashboardHeroWatermark({
    super.key,
    this.opacity = 0.10,
    this.size = 120,
    this.assetPath = 'assets/app_icon.png',
  });

  final double opacity;
  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
