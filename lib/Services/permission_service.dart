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
    final role = (json['role'] ?? '').toString().trim();
    return UserData(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: role.isNotEmpty ? role : 'user',
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
      final userDataString =
          prefs.getString('user') ?? prefs.getString('user_data');

      if (userDataString != null) {
        final userData = UserData.fromJson(
          json.decode(userDataString) as Map<String, dynamic>,
        );
        user.value = userData;
        print('🔍 [PermissionService] User data loaded: ${userData.fullName}');
        print('🔍 [PermissionService] User role: "${userData.role}" | isAdmin: $isAdmin');
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

  bool get isAdmin {
    final role = user.value?.role.toLowerCase().trim() ?? '';
    return role == 'admin' ||
        role == 'owner' ||
        role == 'superadmin' ||
        role == 'company_admin';
  }

  /// Admin / owner always sees every module. Staff still needs page permissions.
  bool canAccessModule(String module) {
    if (isAdmin) return true;
    return hasModuleAccess(module);
  }

  bool hasPermission(String page) {
    if (isAdmin) return true;
    if (user.value == null) return false;
    
    // Check specific permission
    final permission = user.value!.permissions.firstWhereOrNull(
      (p) => p.page.toLowerCase() == page.toLowerCase(),
    );
    
    return permission?.canView ?? false;
  }

  bool hasModuleAccess(String module) {
    if (isAdmin) return true;
    if (user.value == null) return false;
    
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
    if (isAdmin) return true;
    if (user.value == null) return false;
    
    final moduleLower = module.toLowerCase();
    final sub = subPage.toLowerCase().replaceAll(' ', '-');
    // Accept common stored formats used by access management + legacy doubles
    final candidates = <String>{
      '$moduleLower-$sub', // sales-credits
      sub, // credits
      '$moduleLower-$moduleLower-$sub', // sales-sales-credits (legacy)
      if (sub.startsWith('$moduleLower-')) sub,
      if (sub.startsWith('$moduleLower-')) '$moduleLower-$sub',
    };

    final permission = user.value!.permissions.firstWhereOrNull(
      (p) => candidates.contains(p.page.toLowerCase()),
    );
    
    return permission?.canView ?? false;
  }

  bool hasAnyModuleAccess() {
    if (isAdmin) return true;
    if (user.value == null) return false;
    
    // Check if user has any permissions at all
    return user.value!.permissions.isNotEmpty;
  }
}
