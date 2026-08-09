import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/Users/controller/user_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccessManagementScreen extends StatefulWidget {
  final String? userId;

  const AccessManagementScreen({super.key, this.userId});

  @override
  State<AccessManagementScreen> createState() => _AccessManagementScreenState();
}

class _AccessManagementScreenState extends State<AccessManagementScreen> {
  late final UserManagementController _controller;
  User? _user;
  final Map<String, UserPermission> _permissions = {};

  final List<_PageAccess> _availablePages = [
    // ========== WAREHOUSE MODULE ==========
    _PageAccess(
      name: 'Warehouse Dashboard',
      route: '/warehouse/dashboard',
      icon: Icons.warehouse,
    ),
    _PageAccess(
      name: 'Products',
      route: '/warehouse/products',
      icon: Icons.inventory_2,
    ),
    _PageAccess(
      name: 'Categories',
      route: '/warehouse/categories',
      icon: Icons.category,
    ),
    _PageAccess(
      name: 'Suppliers',
      route: '/warehouse/suppliers',
      icon: Icons.local_shipping,
    ),
    _PageAccess(
      name: 'Customers',
      route: '/warehouse/customers',
      icon: Icons.people,
    ),
    _PageAccess(
      name: 'Invoices',
      route: '/warehouse/invoices',
      icon: Icons.receipt,
    ),
    _PageAccess(
      name: 'Stock Movement',
      route: '/warehouse/stock',
      icon: Icons.swap_horiz,
    ),
    _PageAccess(
      name: 'Inventory Valuation',
      route: '/warehouse/inventory',
      icon: Icons.inventory,
    ),
    _PageAccess(
      name: 'Stock Summary Report',
      route: '/warehouse/reports/stock-summary',
      icon: Icons.bar_chart,
    ),
    _PageAccess(
      name: 'Low Stock Report',
      route: '/warehouse/reports/low-stock',
      icon: Icons.warning,
    ),
    _PageAccess(
      name: 'Expiry Report',
      route: '/warehouse/reports/expiry',
      icon: Icons.event,
    ),
    _PageAccess(
      name: 'All Reports',
      route: '/warehouse/reports',
      icon: Icons.assessment,
    ),
    // ========== SALES MODULE ==========
    _PageAccess(
      name: 'Sales Orders',
      route: '/sales/orders',
      icon: Icons.shopping_cart,
    ),
    _PageAccess(
      name: 'Sales Quotations',
      route: '/sales/quotations',
      icon: Icons.description,
    ),
    _PageAccess(
      name: 'Sales Customers',
      route: '/sales/warehouse-customers',
      icon: Icons.people_outline,
    ),
    _PageAccess(
      name: 'Deliveries',
      route: '/sales/delivery',
      icon: Icons.local_shipping,
    ),
    _PageAccess(
      name: 'Sales Invoices',
      route: '/sales-invoices',
      icon: Icons.receipt_long,
    ),
    _PageAccess(
      name: 'Sales Payments',
      route: '/sales-payments',
      icon: Icons.payment,
    ),
    _PageAccess(
      name: 'Sales Returns',
      route: '/sales/returns',
      icon: Icons.assignment_return,
    ),
    _PageAccess(
      name: 'Refunds',
      route: '/sales/refunds',
      icon: Icons.money_off,
    ),
    _PageAccess(
      name: 'Sales Credits',
      route: 'sales-credits',
      icon: Icons.note_alt_outlined,
    ),
    _PageAccess(
      name: 'Purchase Dashboard',
      route: '/warehouse/purchase',
      icon: Icons.dashboard,
    ),
    _PageAccess(
      name: 'Purchase Orders',
      route: '/purchase-order',
      icon: Icons.receipt,
    ),
    _PageAccess(
      name: 'Goods Receiving',
      route: '/purchase/goods-receiving',
      icon: Icons.inventory_2,
    ),
    _PageAccess(
      name: 'Purchase Invoices',
      route: '/purchase/invoices',
      icon: Icons.description,
    ),
    _PageAccess(
      name: 'Purchase Payments',
      route: '/purchase/purchase-payment',
      icon: Icons.payment,
    ),
    _PageAccess(
      name: 'Purchase Returns',
      route: '/purchase/purchase-return',
      icon: Icons.assignment_return,
    ),
    _PageAccess(
      name: 'Accounting Dashboard',
      route: '/accounting/dashboard',
      icon: Icons.account_balance,
    ),
    _PageAccess(
      name: 'Chart of Accounts',
      route: '/chart-of-accounts',
      icon: Icons.account_tree,
    ),
    _PageAccess(
      name: 'Journal Entries',
      route: '/journal-entries',
      icon: Icons.book,
    ),
    _PageAccess(
      name: 'General Ledger',
      route: '/general-ledger',
      icon: Icons.menu_book,
    ),
    _PageAccess(
      name: 'Trial Balance',
      route: '/trial-balance',
      icon: Icons.balance,
    ),
    _PageAccess(
      name: 'Bank Accounts',
      route: '/bank-accounts',
      icon: Icons.account_balance_wallet,
    ),
    _PageAccess(
      name: 'Currency Settings',
      route: '__currency',
      icon: Icons.attach_money,
    ),
    _PageAccess(name: 'My Profile', route: '__profile', icon: Icons.person),
    _PageAccess(
      name: 'Change Password',
      route: '__changepassword',
      icon: Icons.lock,
    ),
    _PageAccess(
      name: 'Users Management',
      route: '/admin/users',
      icon: Icons.admin_panel_settings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : Get.put(UserManagementController());
    _loadUserData();
  }

  void _loadUserData() {
    if (widget.userId == null || widget.userId!.isEmpty) return;

    _user = _controller.users.firstWhereOrNull((u) => u.id == widget.userId);

    if (_user != null) {
      for (var perm in _user!.permissions) {
        _permissions[perm.page] = perm;
      }
      for (var page in _availablePages) {
        if (!_permissions.containsKey(page.route)) {
          _permissions[page.route] = UserPermission(
            id: '',
            page: page.route,
            canView: true,
            canCreate: false,
            canEdit: false,
            canDelete: false,
          );
        }
      }
    }
    setState(() {});
  }

  Future<void> _savePermissions() async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid user ID',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final permissionsList = _permissions.values.toList();
    final success = await _controller.updateUserPermissions(
      userId: widget.userId!,
      permissions: permissionsList,
    );

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        'Access permissions updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to update permissions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Manage Access'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Manage Access',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _savePermissions,
            child: Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kPrimary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildUserInfo(),
          const SizedBox(height: 16),
          _buildPermissionLegend(),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _availablePages.length,
              itemBuilder: (context, index) {
                final page = _availablePages[index];
                final permission = _permissions[page.route]!;
                return _PermissionCard(
                  page: page,
                  permission: permission,
                  onPermissionChanged: (updated) {
                    setState(() {
                      _permissions[page.route] = updated;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _user!.fullName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: kPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user!.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _LegendItem(label: 'View', color: Colors.blue),
          const SizedBox(width: 16),
          _LegendItem(label: 'Create', color: Colors.green),
          const SizedBox(width: 16),
          _LegendItem(label: 'Edit', color: Colors.orange),
          const SizedBox(width: 16),
          _LegendItem(label: 'Delete', color: Colors.red),
        ],
      ),
    );
  }
}

// ============== PERMISSION CARD ==============
class _PermissionCard extends StatelessWidget {
  final _PageAccess page;
  final UserPermission permission;
  final Function(UserPermission) onPermissionChanged;

  const _PermissionCard({
    required this.page,
    required this.permission,
    required this.onPermissionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(page.icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  page.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PermissionToggle(
                label: 'View',
                value: permission.canView,
                color: Colors.blue,
                onChanged: (value) {
                  onPermissionChanged(
                    UserPermission(
                      id: permission.id,
                      page: permission.page,
                      canView: value,
                      canCreate: permission.canCreate,
                      canEdit: permission.canEdit,
                      canDelete: permission.canDelete,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _PermissionToggle(
                label: 'Create',
                value: permission.canCreate,
                color: Colors.green,
                onChanged: (value) {
                  onPermissionChanged(
                    UserPermission(
                      id: permission.id,
                      page: permission.page,
                      canView: permission.canView,
                      canCreate: value,
                      canEdit: permission.canEdit,
                      canDelete: permission.canDelete,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _PermissionToggle(
                label: 'Edit',
                value: permission.canEdit,
                color: Colors.orange,
                onChanged: (value) {
                  onPermissionChanged(
                    UserPermission(
                      id: permission.id,
                      page: permission.page,
                      canView: permission.canView,
                      canCreate: permission.canCreate,
                      canEdit: value,
                      canDelete: permission.canDelete,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _PermissionToggle(
                label: 'Delete',
                value: permission.canDelete,
                color: Colors.red,
                onChanged: (value) {
                  onPermissionChanged(
                    UserPermission(
                      id: permission.id,
                      page: permission.page,
                      canView: permission.canView,
                      canCreate: permission.canCreate,
                      canEdit: permission.canEdit,
                      canDelete: value,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PermissionToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _PermissionToggle({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: value ? color.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: value ? color : Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                value ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: value ? color : Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: value ? color : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

class _PageAccess {
  final String name;
  final String route;
  final IconData icon;

  _PageAccess({required this.name, required this.route, required this.icon});
}
