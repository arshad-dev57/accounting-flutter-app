import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPermission {
  final String id;
  final String page;
  final bool canView;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;

  UserPermission({
    required this.id,
    required this.page,
    required this.canView,
    this.canCreate = false,
    this.canEdit = false,
    this.canDelete = false,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      id: json['id'] ?? '',
      page: json['page'] ?? '',
      canView: json['canView'] ?? true,
      canCreate: json['canCreate'] ?? false,
      canEdit: json['canEdit'] ?? false,
      canDelete: json['canDelete'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'page': page,
      'canView': canView,
      'canCreate': canCreate,
      'canEdit': canEdit,
      'canDelete': canDelete,
    };
  }
}

class UserData {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final List<UserPermission> permissions;

  UserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.permissions = const [],
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      permissions: (json['permissions'] as List?)
              ?.map((p) => UserPermission.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'permissions': permissions.map((p) => p.toJson()).toList(),
    };
  }

  String get fullName => '$firstName $lastName';
}

class PermissionService extends GetxController {
  static PermissionService get to => Get.find();

  final Rx<UserData?> user = Rx<UserData?>(null);
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      loading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user');
      
      if (userDataString != null) {
        final userData = UserData.fromJson(
          json.decode(userDataString) as Map<String, dynamic>,
        );
        user.value = userData;
        print('🔍 [PermissionService] User data loaded: ${userData.fullName}');
        print('🔍 [PermissionService] User role: ${userData.role}');
        print('🔍 [PermissionService] Permissions count: ${userData.permissions.length}');
      } else {
        print('⚠️ [PermissionService] No user data found in SharedPreferences');
      }
    } catch (e) {
      print('❌ [PermissionService] Error loading user data: $e');
    } finally {
      loading.value = false;
    }
  }

  Future<void> saveUserData(UserData userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(userData.toJson()));
      user.value = userData;
      print('✅ [PermissionService] User data saved');
    } catch (e) {
      print('❌ [PermissionService] Error saving user data: $e');
    }
  }

  Future<void> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      user.value = null;
      print('✅ [PermissionService] User data cleared');
    } catch (e) {
      print('❌ [PermissionService] Error clearing user data: $e');
    }
  }

  bool get isAdmin => user.value?.role == 'admin';

  bool hasPermission(String page) {
    if (user.value == null) return false;
    
    // Admin has all permissions
    if (isAdmin) return true;
    
    // Check specific permission
    final permission = user.value!.permissions.firstWhereOrNull(
      (p) => p.page.toLowerCase() == page.toLowerCase(),
    );
    
    return permission?.canView ?? false;
  }

  bool hasModuleAccess(String module) {
    if (user.value == null) return false;
    
    // Admin has all module access
    if (isAdmin) return true;
    
    print('🔍 [hasModuleAccess] Checking module access for: $module');
    print('🔍 [hasModuleAccess] User role: ${user.value!.role}');
    print('🔍 [hasModuleAccess] User permissions: ${user.value!.permissions.map((p) => p.page).toList()}');
    
    // Check if user has any permission for this module
    final hasModulePermission = user.value!.permissions.any((p) {
      final pageLower = p.page.toLowerCase();
      final moduleLower = module.toLowerCase();
      final matches = pageLower.startsWith(moduleLower) || pageLower == moduleLower;
      print('🔍 [hasModuleAccess] Checking permission: ${p.page} against $module -> $matches (canView: ${p.canView})');
      return matches && p.canView;
    });
    
    print('🔍 [hasModuleAccess] Has module permission: $hasModulePermission');
    return hasModulePermission;
  }

  bool hasSubPageAccess(String module, String subPage) {
    if (user.value == null) return false;
    
    // Admin has all sub-page access
    if (isAdmin) return true;
    
    // Check specific sub-page permission
    final pageIdentifier = '${module}-${subPage.toLowerCase().replaceAll(' ', '-')}';
    final permission = user.value!.permissions.firstWhereOrNull(
      (p) => p.page.toLowerCase() == pageIdentifier,
    );
    
    return permission?.canView ?? false;
  }

  bool hasAnyModuleAccess() {
    if (user.value == null) return false;
    
    // Admin has all module access
    if (isAdmin) return true;
    
    // Check if user has any permissions at all
    return user.value!.permissions.isNotEmpty;
  }
}
