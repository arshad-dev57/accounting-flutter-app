import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// This automatically overrides colors everywhere without changing any screen
class ThemeOverride extends StatelessWidget {
  final Widget child;
  
  const ThemeOverride({Key? key, required this.child}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = Get.find<ThemeController>().isDarkMode.value;
      
      // Override the theme globally
      return Theme(
        data: Theme.of(context).copyWith(
          scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : kBg,
          cardColor: isDark ? const Color(0xFF1E1E1E) : kCardBg,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            surface: isDark ? const Color(0xFF1E1E1E) : kCardBg,
          ),
        ),
        child: child,
      );
    });
  }
}