// lib/utils/app_snackbar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  
  static void success(Color color, String title, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: color,
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  static void error(Color color, String title, String message,
      {Duration duration = const Duration(seconds: 4)}) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: color,
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  static void warning(String title, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning_amber_outlined,
      duration: duration,
    );
  }

  static void info(String title, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  static void show({
    required String title,
    required String message,
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    _showSnackbar(
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      duration: duration,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }

  static void _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    Color textColor = Colors.white,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    // Agar pehle se koi snackbar open ho to band karo
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP, // web pe top sahi lagta hai
      backgroundColor: backgroundColor,
      colorText: textColor,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackStyle: SnackStyle.FLOATING,
      icon: icon != null
          ? Icon(icon, color: textColor, size: 24)
          : null,
      mainButton: buttonText != null && onButtonPressed != null
          ? TextButton(
              onPressed: onButtonPressed,
              child: Text(
                buttonText,
                style: TextStyle(color: textColor),
              ),
            )
          : null,
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
}