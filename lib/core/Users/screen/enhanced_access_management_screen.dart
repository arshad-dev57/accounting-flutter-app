import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/core/Users/controller/user_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EnhancedAccessManagementScreen extends StatefulWidget {
  final String? userId;

  const EnhancedAccessManagementScreen({super.key, this.userId});

  @override
  State<EnhancedAccessManagementScreen> createState() => _EnhancedAccessManagementScreenState();
}

class _EnhancedAccessManagementScreenState extends State<EnhancedAccessManagementScreen> {
  late final UserManagementController _controller;
  User? _selectedUser;
  String? _selectedModule;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<UserManagementController>()
        ? Get.find<UserManagementController>()
        : Get.put(UserManagementController());
    _loadUserData();
  }

  void _loadUserData() {
    if (widget.userId == null || widget.userId!.isEmpty) {
      return;
    }
    _selectedUser = _controller.users.firstWhereOrNull((u) => u.id == widget.userId);
    if (_selectedUser != null) {
      _controller.initializeModulePermissions(_selectedUser!);
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

    final permissionsList = _controller.buildPermissionsList(widget.userId!);
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
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to update permissions',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedUser == null) {
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
        leading: _selectedModule != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedModule = null;
                  });
                },
              )
            : null,
        title: Text(
          _selectedModule != null
              ? '${UserManagementController.moduleConfigs.firstWhere((c) => c.module == _selectedModule).displayName} Permissions'
              : 'Manage Access - ${_selectedUser!.fullName}',
        ),
        actions: [
          if (_selectedModule == null)
            TextButton.icon(
              onPressed: _savePermissions,
              icon: const Icon(Icons.save, color: kPrimary),
              label: const Text('Save', style: TextStyle(color: kPrimary)),
            ),
        ],
      ),
      body: _selectedModule == null
          ? _buildModulesList()
          : _buildSubPagesList(),
    );
  }

  Widget _buildModulesList() {
    return Column(
      children: [
        _buildUserInfoHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: UserManagementController.moduleConfigs.length,
            itemBuilder: (context, index) {
              final config = UserManagementController.moduleConfigs[index];
              final modulePerm = _controller.modulePermissions[config.module];
              
              return _ModulePermissionCard(
                config: config,
                permission: modulePerm,
                onAccessChanged: (hasAccess) {
                  setState(() {
                    _controller.updateModuleAccess(config.module, hasAccess);
                  });
                },
                onTap: () {
                  if (modulePerm?.hasAccess == true) {
                    setState(() {
                      _selectedModule = config.module;
                    });
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubPagesList() {
    final config = UserManagementController.moduleConfigs.firstWhere(
      (c) => c.module == _selectedModule,
    );
    final subPages = _controller.subPagePermissions[_selectedModule];

    return Column(
      children: [
        _buildModuleInfoHeader(config),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: config.subPages.length,
            itemBuilder: (context, index) {
              final subPage = config.subPages[index];
              final perm = subPages?[subPage.page];
              
              return _SubPagePermissionCard(
                subPage: subPage,
                permission: perm,
                onPermissionChanged: (canView) {
                  setState(() {
                    _controller.updateSubPagePermission(
                      config.module,
                      subPage.page,
                      canView,
                    );
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kPrimary,
            child: Text(
              _selectedUser!.fullName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedUser!.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedUser!.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.shield, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      _selectedUser!.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleInfoHeader(ModuleConfig config) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(config.icon, color: kPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure sub-page access permissions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulePermissionCard extends StatelessWidget {
  final ModuleConfig config;
  final ModulePermission? permission;
  final Function(bool) onAccessChanged;
  final VoidCallback onTap;

  const _ModulePermissionCard({
    required this.config,
    required this.permission,
    required this.onAccessChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccess = permission?.hasAccess ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAccess ? kPrimary.withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: hasAccess ? kPrimary.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            config.icon,
            color: hasAccess ? kPrimary : Colors.grey[600],
            size: 24,
          ),
        ),
        title: Text(
          config.displayName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasAccess ? Colors.black87 : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          '${config.subPages.length} sub-pages',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: hasAccess,
              onChanged: onAccessChanged,
              activeColor: kPrimary,
            ),
            if (hasAccess)
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
          ],
        ),
        onTap: hasAccess ? onTap : null,
      ),
    );
  }
}

class _SubPagePermissionCard extends StatelessWidget {
  final SubPagePermission subPage;
  final SubPagePermission? permission;
  final Function(bool) onPermissionChanged;

  const _SubPagePermissionCard({
    required this.subPage,
    required this.permission,
    required this.onPermissionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canView = permission?.canView ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: canView ? kPrimary.withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            canView ? Icons.check_circle : Icons.circle_outlined,
            color: canView ? kPrimary : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subPage.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: canView ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
          Switch(
            value: canView,
            onChanged: onPermissionChanged,
            activeColor: kPrimary,
          ),
        ],
      ),
    );
  }
}