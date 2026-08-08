import 'package:BisonsTechs_app/Services/api_client.dart';
import 'package:flutter/material.dart';
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
      userRole: json['userRole'] != null
          ? UserRole.fromJson(json['userRole'])
          : null,
      permissions:
          (json['permissions'] as List?)
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

  UserRole({required this.id, required this.name, this.description});

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

// Module-based permission models
class ModulePermission {
  final String module;
  final String displayName;
  final bool hasAccess;
  final bool canView;
  final IconData icon;

  ModulePermission({
    required this.module,
    required this.displayName,
    this.hasAccess = false,
    this.canView = false,
    required this.icon,
  });

  ModulePermission copyWith({
    String? module,
    String? displayName,
    bool? hasAccess,
    bool? canView,
    IconData? icon,
  }) {
    return ModulePermission(
      module: module ?? this.module,
      displayName: displayName ?? this.displayName,
      hasAccess: hasAccess ?? this.hasAccess,
      canView: canView ?? this.canView,
      icon: icon ?? this.icon,
    );
  }
}

class SubPagePermission {
  final String page;
  final String displayName;
  final bool canView;
  final IconData icon;

  SubPagePermission({
    required this.page,
    required this.displayName,
    this.canView = false,
    required this.icon,
  });

  SubPagePermission copyWith({
    String? page,
    String? displayName,
    bool? canView,
    IconData? icon,
  }) {
    return SubPagePermission(
      page: page ?? this.page,
      displayName: displayName ?? this.displayName,
      canView: canView ?? this.canView,
      icon: icon ?? this.icon,
    );
  }
}

class ModuleConfig {
  final String module;
  final String displayName;
  final String description;
  final IconData icon;
  final List<SubPagePermission> subPages;

  ModuleConfig({
    required this.module,
    required this.displayName,
    required this.description,
    required this.icon,
    required this.subPages,
  });
}

class Role {
  final String id;
  final String name;
  final String? description;

  Role({required this.id, required this.name, this.description});

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
  final RxString roleFilter = 'all'.obs;

  // Module permissions state
  final RxMap<String, ModulePermission> modulePermissions =
      <String, ModulePermission>{}.obs;
  final RxMap<String, Map<String, SubPagePermission>> subPagePermissions =
      <String, Map<String, SubPagePermission>>{}.obs;

  // Module configurations
  static final List<ModuleConfig> moduleConfigs = [
    ModuleConfig(
      module: 'accounting',
      displayName: 'Accounting',
      description: 'Manage financial records, invoices, and reports',
      icon: Icons.account_balance,
      subPages: [
        SubPagePermission(
          page: 'dashboard',
          displayName: 'Dashboard',
          icon: Icons.dashboard,
        ),
        SubPagePermission(
          page: 'chart-of-accounts',
          displayName: 'Chart of Accounts',
          icon: Icons.account_tree,
        ),
        SubPagePermission(
          page: 'bank-accounts',
          displayName: 'Bank Accounts',
          icon: Icons.account_balance,
        ),
        SubPagePermission(
          page: 'invoices',
          displayName: 'Invoices',
          icon: Icons.receipt_long,
        ),
        SubPagePermission(
          page: 'payments',
          displayName: 'Payments',
          icon: Icons.payment,
        ),
        SubPagePermission(
          page: 'payments-received',
          displayName: 'Payments Received',
          icon: Icons.arrow_downward,
        ),
        SubPagePermission(
          page: 'payments-made',
          displayName: 'Payments Made',
          icon: Icons.arrow_upward,
        ),
        SubPagePermission(
          page: 'accounts-receivable',
          displayName: 'Accounts Receivable',
          icon: Icons.receipt,
        ),
        SubPagePermission(
          page: 'accounts-payable',
          displayName: 'Accounts Payable',
          icon: Icons.send,
        ),
        SubPagePermission(
          page: 'credit-notes',
          displayName: 'Credit Notes',
          icon: Icons.note,
        ),
        SubPagePermission(
          page: 'bills',
          displayName: 'Bills',
          icon: Icons.description,
        ),
        SubPagePermission(
          page: 'expenses',
          displayName: 'Expenses',
          icon: Icons.money_off,
        ),
        SubPagePermission(
          page: 'revenue',
          displayName: 'Revenue',
          icon: Icons.trending_up,
        ),
        SubPagePermission(
          page: 'income',
          displayName: 'Income',
          icon: Icons.attach_money,
        ),
        SubPagePermission(
          page: 'journal-entries',
          displayName: 'Journal Entries',
          icon: Icons.book,
        ),
        SubPagePermission(
          page: 'general-ledger',
          displayName: 'General Ledger',
          icon: Icons.menu_book,
        ),
        SubPagePermission(
          page: 'trial-balance',
          displayName: 'Trial Balance',
          icon: Icons.balance,
        ),
        SubPagePermission(
          page: 'fixed-assets',
          displayName: 'Fixed Assets',
          icon: Icons.business,
        ),
        SubPagePermission(
          page: 'loans-borrowings',
          displayName: 'Loans & Borrowings',
          icon: Icons.savings,
        ),
        SubPagePermission(
          page: 'capital-equity',
          displayName: 'Capital & Equity',
          icon: Icons.pie_chart,
        ),
        SubPagePermission(
          page: 'balance-sheet',
          displayName: 'Balance Sheet',
          icon: Icons.table_chart,
        ),
        SubPagePermission(
          page: 'profit-loss',
          displayName: 'Profit & Loss',
          icon: Icons.show_chart,
        ),
        SubPagePermission(
          page: 'cash-flow',
          displayName: 'Cash Flow',
          icon: Icons.swap_horiz,
        ),
        SubPagePermission(
          page: 'aged-receivables',
          displayName: 'Aged Receivables',
          icon: Icons.history,
        ),
      ],
    ),
    ModuleConfig(
      module: 'warehouse',
      displayName: 'Warehouse',
      description: 'Manage inventory, products, and stock',
      icon: Icons.warehouse,
      subPages: [
        SubPagePermission(
          page: 'products',
          displayName: 'Products',
          icon: Icons.inventory_2,
        ),
        SubPagePermission(
          page: 'categories',
          displayName: 'Categories',
          icon: Icons.category,
        ),
        SubPagePermission(
          page: 'suppliers',
          displayName: 'Suppliers',
          icon: Icons.local_shipping,
        ),
        SubPagePermission(
          page: 'stock-movement',
          displayName: 'Stock Movement',
          icon: Icons.swap_vert,
        ),
        SubPagePermission(
          page: 'customers',
          displayName: 'Customers',
          icon: Icons.people,
        ),
        SubPagePermission(
          page: 'orders',
          displayName: 'Orders',
          icon: Icons.shopping_bag,
        ),
        SubPagePermission(
          page: 'returns',
          displayName: 'Returns',
          icon: Icons.assignment_return,
        ),
        SubPagePermission(
          page: 'refunds',
          displayName: 'Refunds',
          icon: Icons.money_off,
        ),
      ],
    ),
    ModuleConfig(
      module: 'sales',
      displayName: 'Sales',
      description: 'Manage sales orders, quotations, and customers',
      icon: Icons.shopping_cart,
      subPages: [
        SubPagePermission(
          page: 'dashboard',
          displayName: 'Dashboard',
          icon: Icons.dashboard,
        ),
        SubPagePermission(
          page: 'products',
          displayName: 'Products',
          icon: Icons.inventory_2,
        ),
        SubPagePermission(
          page: 'orders',
          displayName: 'Orders',
          icon: Icons.shopping_bag,
        ),
        SubPagePermission(
          page: 'quotations',
          displayName: 'Quotations',
          icon: Icons.description,
        ),
        SubPagePermission(
          page: 'customers',
          displayName: 'Customers',
          icon: Icons.people,
        ),
        SubPagePermission(
          page: 'deliveries',
          displayName: 'Deliveries',
          icon: Icons.local_shipping,
        ),
        SubPagePermission(
          page: 'invoices',
          displayName: 'Invoices',
          icon: Icons.receipt_long,
        ),
        SubPagePermission(
          page: 'sales-payments',
          displayName: 'Sales Payments',
          icon: Icons.payment,
        ),
        SubPagePermission(
          page: 'sales-returns',
          displayName: 'Sales Returns',
          icon: Icons.assignment_return,
        ),
        SubPagePermission(
          page: 'refunds',
          displayName: 'Refunds',
          icon: Icons.money_off,
        ),
      ],
    ),
    ModuleConfig(
      module: 'purchases',
      displayName: 'Purchases',
      description: 'Manage purchase orders and suppliers',
      icon: Icons.receipt,
      subPages: [
        SubPagePermission(
          page: 'dashboard',
          displayName: 'Dashboard',
          icon: Icons.dashboard,
        ),
        SubPagePermission(
          page: 'purchase-orders',
          displayName: 'Purchase Orders',
          icon: Icons.receipt,
        ),
        SubPagePermission(
          page: 'suppliers',
          displayName: 'Suppliers',
          icon: Icons.local_shipping,
        ),
        SubPagePermission(
          page: 'goods-receiving',
          displayName: 'Goods Receiving',
          icon: Icons.inventory,
        ),
        SubPagePermission(
          page: 'purchase-invoices',
          displayName: 'Purchase Invoices',
          icon: Icons.description,
        ),
        SubPagePermission(
          page: 'purchase-payments',
          displayName: 'Purchase Payments',
          icon: Icons.payment,
        ),
        SubPagePermission(
          page: 'purchase-returns',
          displayName: 'Purchase Returns',
          icon: Icons.assignment_return,
        ),
      ],
    ),
    ModuleConfig(
      module: 'users',
      displayName: 'Users',
      description: 'Manage user accounts and permissions',
      icon: Icons.admin_panel_settings,
      subPages: [
        SubPagePermission(
          page: 'user-management',
          displayName: 'User Management',
          icon: Icons.people,
        ),
        SubPagePermission(
          page: 'roles',
          displayName: 'Roles',
          icon: Icons.admin_panel_settings,
        ),
        SubPagePermission(
          page: 'permissions',
          displayName: 'Permissions',
          icon: Icons.security,
        ),
      ],
    ),
  ];

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
        body: {'permissions': permissions.map((p) => p.toJson()).toList()},
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

    if (roleFilter.value != 'all') {
      result = result.where((user) => user.role == roleFilter.value).toList();
    }

    return result;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setStatusFilter(String status) {
    statusFilter.value = status;
  }

  void setRoleFilter(String role) {
    roleFilter.value = role;
  }

  void refresh() {
    loadUsers();
    loadRoles();
  }

  // Initialize module permissions for a user
  void initializeModulePermissions(User user) {
    // Reset module permissions
    modulePermissions.clear();
    subPagePermissions.clear();

    // Initialize default module permissions
    for (var config in UserManagementController.moduleConfigs) {
      modulePermissions[config.module] = ModulePermission(
        module: config.module,
        displayName: config.displayName,
        hasAccess: false,
        canView: false,
        icon: config.icon,
      );

      // Initialize sub-page permissions
      subPagePermissions[config.module] = {};
      for (var subPage in config.subPages) {
        subPagePermissions[config.module]![subPage.page] = SubPagePermission(
          page: subPage.page,
          displayName: subPage.displayName,
          canView: false,
          icon: subPage.icon,
        );
      }
    }

    // Load user's existing permissions
    if (user.permissions.isNotEmpty) {
      _loadUserPermissions(user.permissions);
    }
  }

  void _loadUserPermissions(List<UserPermission> permissions) {
    for (var perm in permissions) {
      final page = perm.page.toLowerCase();

      // Check if this is a module-level permission
      final moduleConfig = UserManagementController.moduleConfigs
          .firstWhereOrNull((config) => config.module == page);

      if (moduleConfig != null) {
        // Module-level permission
        if (modulePermissions.containsKey(page)) {
          modulePermissions[page] = modulePermissions[page]!.copyWith(
            hasAccess: perm.canView,
            canView: perm.canView,
          );
        }
      } else {
        // Check if this is a sub-page permission (format: module-subpage)
        final parts = page.split('-');
        if (parts.length >= 2) {
          final module = parts[0];
          final subPageSlug = parts.sublist(1).join('-');

          if (subPagePermissions.containsKey(module)) {
            // Find matching sub-page
            final config = UserManagementController.moduleConfigs
                .firstWhereOrNull((c) => c.module == module);

            if (config != null) {
              final matchingSubPage = config.subPages.firstWhereOrNull(
                (sp) => sp.page.toLowerCase() == subPageSlug,
              );

              if (matchingSubPage != null) {
                subPagePermissions[module]![matchingSubPage.page] =
                    subPagePermissions[module]![matchingSubPage.page]!.copyWith(
                      canView: perm.canView,
                    );
              }
            }
          }
        }
      }
    }
  }

  // Update module access
  void updateModuleAccess(String module, bool hasAccess) {
    if (modulePermissions.containsKey(module)) {
      modulePermissions[module] = modulePermissions[module]!.copyWith(
        hasAccess: hasAccess,
        canView: hasAccess,
      );
    }
  }

  // Update sub-page permission
  void updateSubPagePermission(String module, String subPage, bool canView) {
    if (subPagePermissions.containsKey(module) &&
        subPagePermissions[module]!.containsKey(subPage)) {
      subPagePermissions[module]![subPage] =
          subPagePermissions[module]![subPage]!.copyWith(canView: canView);
    }
  }

  // Convert current permissions state to UserPermission list
  List<UserPermission> buildPermissionsList(String userId) {
    final permissions = <UserPermission>[];

    // Add module-level permissions
    for (var entry in modulePermissions.entries) {
      if (entry.value.hasAccess) {
        permissions.add(
          UserPermission(
            id: '$userId-${entry.key}',
            page: entry.key,
            canView: entry.value.canView,
            canCreate: false,
            canEdit: false,
            canDelete: false,
          ),
        );
      }
    }

    // Add sub-page permissions
    for (var moduleEntry in subPagePermissions.entries) {
      for (var subPageEntry in moduleEntry.value.entries) {
        if (subPageEntry.value.canView) {
          final pageIdentifier = '${moduleEntry.key}-${subPageEntry.key}';
          permissions.add(
            UserPermission(
              id: '$userId-$pageIdentifier',
              page: pageIdentifier,
              canView: true,
              canCreate: false,
              canEdit: false,
              canDelete: false,
            ),
          );
        }
      }
    }

    return permissions;
  }
}
