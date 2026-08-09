import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/Users/controller/user_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EnhancedAccessManagementScreen extends StatefulWidget {
  final String? userId;

  const EnhancedAccessManagementScreen({super.key, this.userId});

  @override
  State<EnhancedAccessManagementScreen> createState() =>
      _EnhancedAccessManagementScreenState();
}

class _EnhancedAccessManagementScreenState
    extends State<EnhancedAccessManagementScreen> {
  late final UserManagementController _controller;
  User? _selectedUser;
  String? _selectedModule;
  final RxBool _isSaving = false.obs;

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
    _selectedUser = _controller.users.firstWhereOrNull(
      (u) => u.id == widget.userId,
    );
    if (_selectedUser != null) {
      _controller.initializeModulePermissions(_selectedUser!);
    }
    setState(() {});
  }

  Future<void> _savePermissions() async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      Get.snackbar('Error', 'Invalid user ID', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_isSaving.value) return;

    _isSaving.value = true;
    final permissionsList = _controller.buildPermissionsList(widget.userId!);
    final success = await _controller.updateUserPermissions(
      userId: widget.userId!,
      permissions: permissionsList,
    );
    _isSaving.value = false;

    if (success) {
      Get.back();
      Get.snackbar(
        'Saved',
        'Permissions updated. Ask the user to log in again to see new access.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to update permissions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kDanger,
        colorText: Colors.white,
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
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Set Permissions',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final inModule = _selectedModule != null;
    final moduleName = inModule
        ? UserManagementController.moduleConfigs
            .firstWhere((c) => c.module == _selectedModule)
            .displayName
        : '';

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
          onPressed: () {
            if (inModule) {
              setState(() => _selectedModule = null);
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          inModule ? '$moduleName screens' : 'Set Permissions',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          if (!inModule)
            Obx(() {
              final saving = _isSaving.value;
              return TextButton(
                onPressed: saving ? null : _savePermissions,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              );
            }),
        ],
      ),
      body: inModule ? _buildSubPagesList() : _buildModulesList(),
      bottomNavigationBar: inModule
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Obx(() {
                  final saving = _isSaving.value;
                  return SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saving ? null : _savePermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        disabledBackgroundColor: kPrimary.withValues(alpha: 0.7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save permissions',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ),
    );
  }

  Widget _buildModulesList() {
    return Column(
      children: [
        _buildUserInfoHeader(),
        _buildStepsBanner(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: UserManagementController.moduleConfigs.length,
            itemBuilder: (context, index) {
              final config = UserManagementController.moduleConfigs[index];
              final modulePerm = _controller.modulePermissions[config.module];
              final enabledCount = _controller.subPagePermissions[config.module]
                      ?.values
                      .where((p) => p.canView)
                      .length ??
                  0;

              return _ModulePermissionCard(
                config: config,
                permission: modulePerm,
                enabledCount: enabledCount,
                onAccessChanged: (hasAccess) {
                  setState(() {
                    _controller.updateModuleAccess(config.module, hasAccess);
                  });
                },
                onTap: () {
                  if (modulePerm?.hasAccess == true) {
                    setState(() => _selectedModule = config.module);
                  } else {
                    Get.snackbar(
                      'Turn module on first',
                      'Enable the switch for ${config.displayName}, then tap to choose screens.',
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                    );
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
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => setState(() => _selectedModule = null),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to modules',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsBanner() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick steps',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            SizedBox(height: 6),
            Text(
              '1. Turn ON a module (Sales, Accounting…)\n'
              '2. Tap the module card to pick screens (e.g. Sales Credits)\n'
              '3. Tap Save permissions at the bottom',
              style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF4A5568)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kPrimary,
            child: Text(
              _selectedUser!.fullName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
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
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Choose what ${_selectedUser!.firstName} can open in the app',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _selectedUser!.role.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.purple.shade600,
              ),
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
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(config.icon, color: kPrimary, size: 22),
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
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toggle screens this user can open',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
  final int enabledCount;
  final Function(bool) onAccessChanged;
  final VoidCallback onTap;

  const _ModulePermissionCard({
    required this.config,
    required this.permission,
    required this.enabledCount,
    required this.onAccessChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccess = permission?.hasAccess ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAccess ? kPrimary.withValues(alpha: 0.35) : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasAccess
                      ? kPrimary.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  config.icon,
                  color: hasAccess ? kPrimary : Colors.grey.shade500,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: hasAccess ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasAccess
                          ? '$enabledCount screens on · tap to edit'
                          : 'Off · turn switch on to allow access',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Switch(
                value: hasAccess,
                onChanged: onAccessChanged,
                activeThumbColor: kPrimary,
              ),
              if (hasAccess)
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: canView ? kPrimary.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            canView ? Icons.check_circle : Icons.circle_outlined,
            color: canView ? kPrimary : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subPage.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: canView ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ),
          Switch(
            value: canView,
            onChanged: onPermissionChanged,
            activeThumbColor: kPrimary,
          ),
        ],
      ),
    );
  }
}
