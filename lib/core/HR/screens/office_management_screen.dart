// screens/office_management_screen.dart - OFFICE/BRANCH MANAGEMENT

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';

class OfficeManagementScreen extends StatefulWidget {
  const OfficeManagementScreen({super.key});

  @override
  State<OfficeManagementScreen> createState() => _OfficeManagementScreenState();
}

class _OfficeManagementScreenState extends State<OfficeManagementScreen> {
  // Sample office data
  final List<Map<String, dynamic>> _offices = [
    {
      'id': 'OFF-001',
      'name': 'Head Office',
      'address': 'Karachi, Pakistan',
      'latitude': 24.8607,
      'longitude': 67.0011,
      'radius': 200,
      'employeeCount': 45,
      'status': 'Active',
    },
    {
      'id': 'OFF-002',
      'name': 'North Branch',
      'address': 'Lahore, Pakistan',
      'latitude': 31.5204,
      'longitude': 74.3587,
      'radius': 300,
      'employeeCount': 28,
      'status': 'Active',
    },
    {
      'id': 'OFF-003',
      'name': 'South Branch',
      'address': 'Karachi, Pakistan',
      'latitude': 24.8607,
      'longitude': 67.0011,
      'radius': 500,
      'employeeCount': 12,
      'status': 'Active',
    },
    {
      'id': 'OFF-004',
      'name': 'East Branch',
      'address': 'Islamabad, Pakistan',
      'latitude': 33.6844,
      'longitude': 73.0479,
      'radius': 200,
      'employeeCount': 8,
      'status': 'Inactive',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  _buildSearchAndFilter(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildOfficeList()),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddOfficeDialog(context),
          backgroundColor: kPrimary,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offices & Branches',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_offices.length} offices',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Refresh
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH & FILTER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Search Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search offices...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: GestureDetector(
                  onTap: () {
                    // Clear search
                  },
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All Offices', true),
                const SizedBox(width: 6),
                _filterChip('Active', false),
                const SizedBox(width: 6),
                _filterChip('Inactive', false),
                const SizedBox(width: 6),
                _filterChip('Head Office', false),
                const SizedBox(width: 6),
                _filterChip('Branches', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // Filter logic
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kPrimary : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : kSubText,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OFFICE LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOfficeList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _offices.length,
      itemBuilder: (context, index) {
        final office = _offices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOfficeCard(office, context),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OFFICE CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOfficeCard(Map<String, dynamic> office, BuildContext context) {
    final isActive = office['status'] == 'Active';
    final statusColor = isActive ? kSuccess : kDanger;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: statusColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showOfficeDetails(office, context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kPrimary.withValues(alpha: 0.15),
                            kPrimary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: kPrimary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.business_center,
                        size: 24,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  office['name'],
                                  style:  TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: kText,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      office['status'],
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            office['address'],
                            style: TextStyle(
                              fontSize: 12,
                              color: kSubText,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 12),
                // Stats Row
                Row(
                  children: [
                    _statItem(
                      Icons.people_outline_rounded,
                      '${office['employeeCount']}',
                      'Employees',
                    ),
                    _statItem(
                      Icons.radio_button_checked_rounded,
                      '${office['radius']}m',
                      'Geofence',
                    ),
                    _statItem(
                      Icons.location_on_outlined,
                      '${office['latitude'].toStringAsFixed(4)}, ${office['longitude'].toStringAsFixed(4)}',
                      'Coordinates',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showEditOfficeDialog(context, office);
                        },
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: kSubText,
                        ),
                        label: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 11,
                            color: kText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showGeofencePreview(office, context);
                        },
                        icon: Icon(
                          Icons.map_outlined,
                          size: 14,
                          color: kPrimary,
                        ),
                        label: Text(
                          'Geofence',
                          style: TextStyle(
                            fontSize: 11,
                            color: kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: kPrimary.withValues(alpha: 0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 14, color: kSubText),
          const SizedBox(height: 2),
          Text(
            value,
            style:  TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ADD OFFICE DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showAddOfficeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final latitudeController = TextEditingController(text: '24.8607');
    final longitudeController = TextEditingController(text: '67.0011');
    String selectedRadius = '200';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: 500,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business_center,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text(
                                'Add Office',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a new office location',
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormField(
                              controller: nameController,
                              label: 'Office Name *',
                              hint: 'Enter office name',
                              icon: Icons.business_outlined,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter office name' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: addressController,
                              label: 'Address *',
                              hint: 'Enter full address',
                              icon: Icons.location_on_outlined,
                              maxLines: 2,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter address' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: latitudeController,
                                    label: 'Latitude *',
                                    hint: 'e.g., 24.8607',
                                    icon: Icons.north_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (double.tryParse(value!) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    controller: longitudeController,
                                    label: 'Longitude *',
                                    hint: 'e.g., 67.0011',
                                    icon: Icons.east_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (double.tryParse(value!) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Map Preview Placeholder
                            Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.map_outlined,
                                      size: 32,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to select location on map',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRadiusSelector(
                              selectedRadius,
                              (value) => setState(() => selectedRadius = value),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: kPrimary.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 14,
                                    color: kPrimary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Geofence radius determines the attendance zone around this office',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: kSubText,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer Buttons
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: const BorderSide(color: kPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Office created successfully!'),
                                    backgroundColor: kSuccess,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Create Office',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EDIT OFFICE DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showEditOfficeDialog(BuildContext context, Map<String, dynamic> office) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: office['name']);
    final addressController = TextEditingController(text: office['address']);
    final latitudeController =
        TextEditingController(text: office['latitude'].toString());
    final longitudeController =
        TextEditingController(text: office['longitude'].toString());
    String selectedRadius = office['radius'].toString();
    String selectedStatus = office['status'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: 500,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Office',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                office['name'],
                                style: TextStyle(fontSize: 12, color: kSubText),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFormField(
                              controller: nameController,
                              label: 'Office Name *',
                              hint: 'Enter office name',
                              icon: Icons.business_outlined,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter office name' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: addressController,
                              label: 'Address *',
                              hint: 'Enter full address',
                              icon: Icons.location_on_outlined,
                              maxLines: 2,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter address' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: latitudeController,
                                    label: 'Latitude *',
                                    hint: 'e.g., 24.8607',
                                    icon: Icons.north_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (double.tryParse(value!) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    controller: longitudeController,
                                    label: 'Longitude *',
                                    hint: 'e.g., 67.0011',
                                    icon: Icons.east_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (double.tryParse(value!) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildRadiusSelector(
                              selectedRadius,
                              (value) => setState(() => selectedRadius = value),
                            ),
                            const SizedBox(height: 16),
                            _buildStatusDropdown(
                              selectedStatus,
                              (value) => setState(() => selectedStatus = value!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: const BorderSide(color: kPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Office updated successfully!'),
                                    backgroundColor: kSuccess,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Update Office',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RADIUS SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildRadiusSelector(String selected, void Function(String) onChanged) {
    final radii = ['100', '200', '300', '500', 'Custom'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Geofence Radius *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: radii.map((radius) {
            final isSelected = selected == radius;
            return GestureDetector(
              onTap: () => onChanged(radius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? kPrimary : Colors.grey.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kPrimary.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  radius == 'Custom' ? 'Custom' : '$radius m',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : kSubText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (selected == 'Custom') ...[
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Enter custom radius (meters)',
              suffixText: 'm',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => onChanged(value),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS DROPDOWN
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatusDropdown(String value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
        labelStyle:  TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      items: const ['Active', 'Inactive']
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FORM FIELD HELPER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: kSubText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDanger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        labelStyle:  TextStyle(fontSize: 12, color: kSubText),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        errorStyle: const TextStyle(fontSize: 10),
      ),
      validator: validator,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // OFFICE DETAILS
  // ═══════════════════════════════════════════════════════════════

  void _showOfficeDetails(Map<String, dynamic> office, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.business_center,
                              size: 26,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  office['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  office['address'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kSubText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 16),
                      _detailRow('Office ID', office['id']),
                      _detailRow('Status', office['status'],
                          valueColor: office['status'] == 'Active'
                              ? kSuccess
                              : kDanger),
                      _detailRow('Employees', '${office['employeeCount']}'),
                      _detailRow('Geofence Radius', '${office['radius']} meters'),
                      _detailRow('Latitude', office['latitude'].toStringAsFixed(6)),
                      _detailRow('Longitude', office['longitude'].toStringAsFixed(6)),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Geofence Zone Preview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Map View (${office['radius']}m radius)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? kText,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GEOFENCE PREVIEW
  // ═══════════════════════════════════════════════════════════════

  void _showGeofencePreview(Map<String, dynamic> office, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.radio_button_checked, color: kPrimary),
            const SizedBox(width: 8),
            Text('Geofence Zone'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kPrimary.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: kPrimary,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${office['radius']}m',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                                Text(
                                  'Radius',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: kSubText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${office['name']} Geofence Zone',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Employees within ${office['radius']}m radius will be auto-checked in',
                      style: TextStyle(
                        fontSize: 11,
                        color: kSubText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSuccess.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kSuccess.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: kSuccess),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Auto check-in will be triggered when employee stays inside geofence for 2-3 minutes',
                      style: TextStyle(
                        fontSize: 10,
                        color: kSubText,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: kSubText),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditOfficeDialog(context, office);
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Geofence'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}