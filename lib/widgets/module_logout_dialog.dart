import 'package:BisonsTechs_app/Services/auth_logout_service.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void showModuleLogoutDialog() {
  Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Sign out',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            await AuthLogoutService.clearLocalSession();
            Get.offAll(() => const LoginScreen());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
          ),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
}
