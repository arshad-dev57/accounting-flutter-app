import 'package:LedgerPro_app/Services/api_client.dart';
import 'package:get/get.dart';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role;
  final String? roleId;
  final bool isActive;
  final String createdAt;
  final String? managerId;
  final UserRole? userRole;
  final List<UserPermission> permissions;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    this.roleId,
    required this.isActive,
    required this.createdAt,
    this.managerId,
    this.userRole,
    this.permissions = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'user',
      roleId: json['roleId'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      managerId: json['managerId'],
      userRole: json['userRole'] != null ? UserRole.fromJson(json['userRole']) : null,
      permissions: (json['permissions'] as List?)
              ?.map((p) => UserPermission.fromJson(p))
              .toList() ??
          [],
    );
  }

  String get fullName => '$firstName $lastName';
}

class UserRole {
  final String id;
  final String name;
  final String? description;

  UserRole({
    required this.id,
    required this.name,
    this.description,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

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
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
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
      'page': page,
      'canView': canView,
      'canCreate': canCreate,
      'canEdit': canEdit,
      'canDelete': canDelete,
    };
  }
}

class Role {
  final String id;
  final String name;
  final String? description;

  Role({
    required this.id,
    required this.name,
    this.description,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class UserManagementController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<User> users = <User>[].obs;
  final RxList<Role> roles = <Role>[].obs;

  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
    loadRoles();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final response = await _apiClient.get(
        '/api/admin/users',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as List;
        users.value = data.map((item) => User.fromJson(item)).toList();
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadRoles() async {
    try {
      final response = await _apiClient.get(
        '/api/admin/users/roles',
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final data = response.data['data'] as List;
        roles.value = data.map((item) => Role.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading roles: $e');
    }
  }

  Future<bool> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? country,
    String? role,
    String? roleId,
    String? managerId,
    List<UserPermission>? permissions,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiClient.post(
        '/api/admin/users',
        requiresAuth: true,
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
          if (country != null) 'country': country,
          if (role != null) 'role': role,
          if (roleId != null) 'roleId': roleId,
          if (managerId != null) 'managerId': managerId,
          if (permissions != null)
            'permissions': permissions.map((p) => p.toJson()).toList(),
        },
      );

      if (response.success) {
        await loadUsers();
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateUser({
    required String id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? country,
    String? role,
    String? roleId,
    String? managerId,
    bool? isActive,
    List<UserPermission>? permissions,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiClient.put(
        '/api/admin/users/$id',
        requiresAuth: true,
        body: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (country != null) 'country': country,
          if (role != null) 'role': role,
          if (roleId != null) 'roleId': roleId,
          if (managerId != null) 'managerId': managerId,
          if (isActive != null) 'isActive': isActive,
          if (permissions != null)
            'permissions': permissions.map((p) => p.toJson()).toList(),
        },
      );

      if (response.success) {
        await loadUsers();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      isLoading.value = true;

      final response = await _apiClient.delete(
        '/api/admin/users/$id',
        requiresAuth: true,
      );

      if (response.success) {
        await loadUsers();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateUserPermissions({
    required String userId,
    required List<UserPermission> permissions,
  }) async {
    try {
      isLoading.value = true;

      final response = await _apiClient.put(
        '/api/admin/users/$userId/permissions',
        requiresAuth: true,
        body: {
          'permissions': permissions.map((p) => p.toJson()).toList(),
        },
      );

      if (response.success) {
        await loadUsers();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating permissions: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  List<User> get filteredUsers {
    var result = users.toList();

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((user) {
        return user.fullName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.phone?.contains(query) ?? false);
      }).toList();
    }

    if (statusFilter.value != 'all') {
      if (statusFilter.value == 'active') {
        result = result.where((user) => user.isActive).toList();
      } else if (statusFilter.value == 'inactive') {
        result = result.where((user) => !user.isActive).toList();
      }
    }

    return result;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setStatusFilter(String status) {
    statusFilter.value = status;
  }

  void refresh() {
    loadUsers();
    loadRoles();
  }
}
