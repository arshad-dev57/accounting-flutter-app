import 'dart:convert';
import 'package:BisonsTechs_app/core/Users/controller/user_management_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService extends GetxService {
  static PermissionService get to => Get.find<PermissionService>();

  User? _currentUser;
  final RxBool isLoading = false.obs;

  User? get currentUser => _currentUser;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');

      if (userData != null) {
        final userMap = Map<String, dynamic>.from(jsonDecode(userData));
        _currentUser = User.fromJson(userMap);
      }
    } catch (e) {
      print('Error loading current user: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCurrentUser() async {
    await _loadCurrentUser();
  }

  void setCurrentUser(User user) {
    _currentUser = user;
  }

  // Check if user has permission for a specific page
  bool hasPermission(String page) {
    if (_currentUser == null) return false;

    // Admin has all permissions
    if (_currentUser!.role == 'admin') return true;

    // Check specific permission
    final permission = _currentUser!.permissions.firstWhereOrNull(
      (p) => p.page.toLowerCase() == page.toLowerCase(),
    );

    return permission?.canView ?? false;
  }

  // Check if user has access to a module
  bool hasModuleAccess(String module) {
    if (_currentUser == null) return false;

    // Admin has all module access
    if (_currentUser!.role == 'admin') return true;

    // Check if user has any permission for this module
    final hasModulePermission = _currentUser!.permissions.any((p) {
      final pageLower = p.page.toLowerCase();
      final moduleLower = module.toLowerCase();
      return pageLower.startsWith(moduleLower) && p.canView;
    });

    return hasModulePermission;
  }

  // Check if user has access to a specific sub-page
  bool hasSubPageAccess(String module, String subPage) {
    if (_currentUser == null) return false;

    // Admin has all sub-page access
    if (_currentUser!.role == 'admin') return true;

    final moduleLower = module.toLowerCase();
    final sub = subPage.toLowerCase().replaceAll(' ', '-');
    final candidates = <String>{
      '$moduleLower-$sub',
      sub,
      '$moduleLower-$moduleLower-$sub',
      if (sub.startsWith('$moduleLower-')) sub,
      if (sub.startsWith('$moduleLower-')) '$moduleLower-$sub',
    };

    final permission = _currentUser!.permissions.firstWhereOrNull(
      (p) => candidates.contains(p.page.toLowerCase()),
    );

    return permission?.canView ?? false;
  }

  // Check if user has any module access at all
  bool hasAnyModuleAccess() {
    if (_currentUser == null) return false;

    // Admin has all module access
    if (_currentUser!.role == 'admin') return true;

    // Check if user has any permissions at all
    return _currentUser!.permissions.isNotEmpty;
  }

  // Get all modules the user has access to
  List<String> getAccessibleModules() {
    if (_currentUser == null) return [];

    // Admin has access to all modules
    if (_currentUser!.role == 'admin') {
      return UserManagementController.moduleConfigs
          .map((config) => config.module)
          .toList();
    }

    // Get modules from user's permissions
    final modules = <String>{};
    for (var perm in _currentUser!.permissions) {
      if (perm.canView) {
        final parts = perm.page.split('-');
        if (parts.isNotEmpty) {
          modules.add(parts[0]);
        }
      }
    }

    return modules.toList();
  }

  // Get all accessible sub-pages for a module
  List<String> getAccessibleSubPages(String module) {
    if (_currentUser == null) return [];

    // Admin has access to all sub-pages
    if (_currentUser!.role == 'admin') {
      final config = UserManagementController.moduleConfigs.firstWhereOrNull(
        (c) => c.module == module,
      );
      return config?.subPages.map((sp) => sp.page).toList() ?? [];
    }

    // Get sub-pages from user's permissions
    final subPages = <String>[];
    for (var perm in _currentUser!.permissions) {
      if (perm.canView && perm.page.startsWith('$module-')) {
        final subPage = perm.page.substring(module.length + 1);
        subPages.add(subPage);
      }
    }

    return subPages;
  }

  bool get isAdmin => _currentUser?.role == 'admin';
}
