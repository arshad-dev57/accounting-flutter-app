import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:BisonsTechs_app/Services/auth_logout_service.dart';
import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showDeleteAccountDialog() {
  Get.dialog(
    const _DeleteAccountDialog(),
    barrierDismissible: false,
  );
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _deleting = false;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() => _deleting = true);

    try {
      final api = Get.find<ApiClient>();
      final response = await api.delete('/api/users/me');

      if (!response.success) {
        AppSnackbar.error(
          kDanger,
          'Error',
          response.data?['message'] ??
              response.message ??
              'Failed to delete account. Please try again.',
        );
        if (mounted) setState(() => _deleting = false);
        return;
      }

      await AuthLogoutService.clearPushSession();
      await PermissionService.to.clearUserData();
      await api.clearToken();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Get.offAll(() => const LoginScreen());
      AppSnackbar.success(
        kSuccess,
        'Account deleted',
        'Your account has been permanently deleted.',
      );
    } catch (_) {
      AppSnackbar.error(
        kDanger,
        'Error',
        'Failed to delete account. Please try again.',
      );
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Delete account',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      content: const Text(
        'This will permanently delete your account and you will not be able to log in again. This cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _deleting ? null : _delete,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
