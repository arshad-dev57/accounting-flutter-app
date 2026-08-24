// core/warehouse/locations/screen/locations_screen.dart

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/controller/location_controller.dart';
import 'package:BisonsTechs_app/core/warehouse/locations/model/location_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<LocationController>()
        ? Get.find<LocationController>()
        : Get.put(LocationController(), permanent: true);
    return _LocationsBody(controller: controller);
  }
}

class _LocationsBody extends StatefulWidget {
  final LocationController controller;
  const _LocationsBody({required this.controller});

  @override
  State<_LocationsBody> createState() => _LocationsBodyState();
}

class _LocationsBodyState extends State<_LocationsBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = Get.isRegistered<PermissionService>() &&
          PermissionService.to.isAdmin;
      if (!isAdmin) {
        Get.offNamed('/warehouse/dashboard');
        return;
      }
      widget.controller.ensureLocationsLoaded(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.locations.isEmpty) {
                return Center(
                  child: LoadingAnimationWidget.discreteCircle(
                    color: kPrimary,
                    size: 40,
                  ),
                );
              }

              if (controller.locations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 72,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.error.value.isNotEmpty
                              ? 'Could not load locations'
                              : 'No Locations Found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.error.value.isNotEmpty
                              ? controller.error.value
                              : 'Create your first warehouse or shop location',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: controller.error.value.isNotEmpty
                              ? () => controller.ensureLocationsLoaded(
                                    force: true,
                                  )
                              : () => _showLocationDialog(controller),
                          icon: Icon(
                            controller.error.value.isNotEmpty
                                ? Icons.refresh
                                : Icons.add,
                          ),
                          label: Text(
                            controller.error.value.isNotEmpty
                                ? 'Retry'
                                : 'Create Location',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () =>
                    controller.ensureLocationsLoaded(force: true),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  itemCount: controller.locations.length,
                  itemBuilder: (context, index) {
                    final loc = controller.locations[index];
                    return _buildLocationCard(loc, controller);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocationDialog(controller),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTopHeader(LocationController controller) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Warehouses, shops & POS stores',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () =>
                    controller.ensureLocationsLoaded(force: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(
    WarehouseLocation loc,
    LocationController controller,
  ) {
    final isSelected = controller.selectedLocation.value?.id == loc.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: kPrimary, width: 2)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.selectLocation(loc),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1D2E),
                      ),
                    ),
                  ),
                  if (loc.isDefault)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Selected',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showLocationDialog(controller, existing: loc);
                      } else if (value == 'delete') {
                        _confirmDelete(controller, loc);
                      } else if (value == 'select') {
                        controller.selectLocation(loc);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'select',
                        child: Text('Select'),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      if (!loc.isDefault)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _chip(loc.code, Icons.tag),
                  _chip(loc.typeDisplay, Icons.store_mall_directory_outlined),
                  _chip(
                    loc.isActive ? 'Active' : 'Inactive',
                    Icons.circle,
                    color: loc.isActive
                        ? const Color(0xFF047857)
                        : Colors.grey,
                  ),
                ],
              ),
              if (loc.address != null && loc.address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  loc.address!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon, {Color? color}) {
    final c = color ?? Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    LocationController controller,
    WarehouseLocation loc,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Delete "${loc.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.delete(loc.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(
    LocationController controller, {
    WarehouseLocation? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    String type = existing?.type ?? 'Shop';
    bool isDefault = existing?.isDefault ?? false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(existing == null ? 'Create Location' : 'Edit Location'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Code *',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. WH-01',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: LocationController.locationTypes.contains(type)
                        ? type
                        : 'Shop',
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: LocationController.locationTypes
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t == 'POS_Store' ? 'POS Store' : t,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => type = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Default location'),
                    value: isDefault,
                    activeColor: kPrimary,
                    onChanged: (v) => setDialogState(() => isDefault = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  if (name.isEmpty || code.isEmpty) {
                    Get.snackbar('Validation', 'Name and code are required');
                    return;
                  }
                  Get.back();
                  if (existing == null) {
                    await controller.create(
                      name: name,
                      code: code,
                      type: type,
                      isDefault: isDefault,
                    );
                  } else {
                    await controller.updateLocation(
                      id: existing.id,
                      name: name,
                      code: code,
                      type: type,
                      isDefault: isDefault,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                ),
                child: Text(existing == null ? 'Create' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
