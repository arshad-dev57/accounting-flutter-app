import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:get/get.dart';

bool isEmployeeRole([String? role]) {
  final resolved = (role ??
          (Get.isRegistered<PermissionService>()
              ? PermissionService.to.user.value?.role
              : null) ??
          '')
      .toLowerCase()
      .trim();
  return resolved == 'employee';
}

bool isHrAdminRole([String? role]) {
  final resolved = (role ??
          (Get.isRegistered<PermissionService>()
              ? PermissionService.to.user.value?.role
              : null) ??
          '')
      .toLowerCase()
      .trim();
  return resolved == 'admin' ||
      resolved == 'owner' ||
      resolved == 'superadmin' ||
      resolved == 'company_admin' ||
      resolved == 'manager' ||
      resolved == 'hr' ||
      resolved == 'hr_manager';
}
