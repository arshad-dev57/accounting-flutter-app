// screens/live_employee_tracking_screen.dart - LIVE EMPLOYEE TRACKING MAP

import 'dart:async';

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/config/maps_config.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class LiveEmployeeTrackingScreen extends StatefulWidget {
  const LiveEmployeeTrackingScreen({super.key});

  @override
  State<LiveEmployeeTrackingScreen> createState() =>
      _LiveEmployeeTrackingScreenState();
}

class _LiveEmployeeTrackingScreenState
    extends State<LiveEmployeeTrackingScreen> {
  String _selectedFilter = 'All';
  String _selectedEmployeeId = '';
  bool _isMapLoading = true;
  bool _usingLiveFeed = false;
  GoogleMapController? _mapController;
  Timer? _pollTimer;

  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadLiveFeed();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadLiveFeed());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadLiveFeed() async {
    try {
      final live = await HrApiService.instance.liveTracking();
      if (!mounted) return;
      setState(() {
        _usingLiveFeed = true;
        _isMapLoading = false;
        _employees
          ..clear()
          ..addAll(live.map((e) {
            final status = e['status']?.toString() ?? 'offline';
            final checkInRaw = e['checkIn'];
            String? checkInLabel;
            if (checkInRaw != null) {
              final parsed = DateTime.tryParse(checkInRaw.toString());
              checkInLabel = parsed != null
                  ? DateFormat('hh:mm a').format(parsed.toLocal())
                  : checkInRaw.toString();
            }
            return {
              'id': e['employeeId']?.toString() ?? '',
              'name': e['employeeName']?.toString() ?? 'Employee',
              'department': e['department']?.toString() ?? '',
              'designation': e['designation']?.toString() ?? '',
              'status': status == 'working'
                  ? 'WORKING'
                  : status == 'field'
                      ? 'FIELD_WORK'
                      : status == 'offline'
                          ? 'OFFLINE'
                          : 'OUTSIDE_OFFICE',
              'location': e['locationLabel']?.toString() ?? '',
              'latitude': (e['latitude'] as num?)?.toDouble() ?? 0,
              'longitude': (e['longitude'] as num?)?.toDouble() ?? 0,
              'lastUpdated': DateTime.tryParse(e['lastPingAt']?.toString() ?? '') ??
                  DateTime.now(),
              'checkIn': checkInLabel,
              'workingHours': e['attendanceStatus']?.toString() ?? '',
              'type': e['insideGeofence'] == true ? 'Office' : 'Field',
              'image': null,
            };
          }));
      });

      if (_employees.isNotEmpty && _mapController != null) {
        final first = _employees.first;
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(
              (first['latitude'] as num).toDouble(),
              (first['longitude'] as num).toDouble(),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isMapLoading = false;
          _usingLiveFeed = false;
        });
      }
    }
  }

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> employees) {
    return employees.map((employee) {
      final id = employee['id'] as String;
      final lat = (employee['latitude'] as num).toDouble();
      final lng = (employee['longitude'] as num).toDouble();
      final selected = _selectedEmployeeId == id;
      return Marker(
        markerId: MarkerId(id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: employee['name']?.toString() ?? '',
          snippet: employee['location']?.toString() ?? '',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selected
              ? BitmapDescriptor.hueAzure
              : (employee['type'] == 'Office'
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueOrange),
        ),
        onTap: () {
          setState(() {
            _selectedEmployeeId = selected ? '' : id;
          });
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEmployees = _getFilteredEmployees();

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          if (!_usingLiveFeed)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF7ED),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                'Demo markers — open Employee dashboard to start live GPS pings',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          _buildFilterChips(),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildMapView(filteredEmployees),
                ),
                Expanded(
                  flex: 1,
                  child: _buildEmployeeList(filteredEmployees),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader(BuildContext context) {
    final filteredCount = _getFilteredEmployees().length;

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
                      'Live Employee Tracking',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '$filteredCount employees • ${DateFormat('hh:mm a').format(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: kSuccess,
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilterChips() {
    final filters = ['All', 'Sales', 'Delivery', 'Field Staff', 'Office Staff'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? kPrimary
                          : Colors.grey.withValues(alpha: 0.3),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (filter != 'All') ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : _getFilterColor(filter),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        filter,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : kSubText,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MAP VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMapView(List<Map<String, dynamic>> employees) {
    final markers = _buildMarkers(employees);
    final initial = employees.isNotEmpty
        ? LatLng(
            (employees.first['latitude'] as num).toDouble(),
            (employees.first['longitude'] as num).toDouble(),
          )
        : const LatLng(31.5204, 74.3587);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: initial, zoom: 12),
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              setState(() => _isMapLoading = false);
            },
          ),
          if (_isMapLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Loading Google Maps...',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              children: [
                _mapControlButton(Icons.my_location, () {
                  if (employees.isEmpty) return;
                  final e = employees.first;
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(
                        (e['latitude'] as num).toDouble(),
                        (e['longitude'] as num).toDouble(),
                      ),
                      14,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                _mapControlButton(Icons.refresh, () => _loadLiveFeed()),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendItem('Office', kSuccess),
                  const SizedBox(width: 10),
                  _legendItem('Field', kWarning),
                  const SizedBox(width: 10),
                  Text(
                    MapsConfig.googleMapsApiKey.isNotEmpty ? 'Google Maps' : 'No key',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: kSubText,
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w500,
            color: kSubText,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPLOYEE LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmployeeList(List<Map<String, dynamic>> employees) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                 Text(
                  'Employees',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const Spacer(),
                Text(
                  '${employees.length} online',
                  style: TextStyle(
                    fontSize: 11,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                final isSelected = _selectedEmployeeId == employee['id'];
                return _buildEmployeeListItem(employee, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeListItem(
    Map<String, dynamic> employee,
    bool isSelected,
  ) {
    final status = employee['status'] as String;
    final statusData = _getStatusData(status);
    final isOnline = status == 'WORKING' ||
        status == 'FIELD_WORK' ||
        status == 'ON_BREAK' ||
        status == 'OUTSIDE_OFFICE';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmployeeId = isSelected ? '' : employee['id'] as String;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimary.withValues(alpha: 0.04)
              : Colors.transparent,
          border: isSelected
              ? Border.all(
                  color: kPrimary.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusData['color'].withValues(alpha: 0.2),
                    statusData['color'].withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: statusData['color'].withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _getInitials(employee['name'] as String),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: statusData['color'],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          employee['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusData['color'].withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: statusData['color'].withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isOnline ? statusData['color'] : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              statusData['label'],
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: isOnline ? statusData['color'] : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${employee['designation']} • ${employee['department']}',
                    style: TextStyle(
                      fontSize: 10,
                      color: kSubText,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 10,
                        color: kSubText,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          employee['location'] as String,
                          style: TextStyle(
                            fontSize: 9,
                            color: kSubText,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.access_time,
                        size: 10,
                        color: kSubText,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _getTimeAgo(employee['lastUpdated'] as DateTime),
                        style: TextStyle(
                          fontSize: 9,
                          color: kSubText,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status Dot
            if (isOnline) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusData['color'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                employee['workingHours'] as String,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusData['color'],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _getFilteredEmployees() {
    if (_selectedFilter == 'All') return _employees;

    final typeMap = {
      'Sales': 'Sales',
      'Delivery': 'Delivery',
      'Field Staff': 'Field',
      'Office Staff': 'Office',
    };

    final filterType = typeMap[_selectedFilter];
    if (filterType == null) return _employees;

    return _employees
        .where((e) => e['type'] == filterType)
        .toList();
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'WORKING':
        return {
          'label': 'WORKING',
          'color': kSuccess,
          'icon': Icons.check_circle_rounded,
        };
      case 'FIELD_WORK':
        return {
          'label': 'FIELD',
          'color': Colors.blue,
          'icon': Icons.location_on_rounded,
        };
      case 'ON_BREAK':
        return {
          'label': 'BREAK',
          'color': Colors.orange,
          'icon': Icons.free_breakfast_rounded,
        };
      case 'OUTSIDE_OFFICE':
        return {
          'label': 'OUTSIDE',
          'color': kWarning,
          'icon': Icons.warning_rounded,
        };
      case 'ABSENT':
        return {
          'label': 'ABSENT',
          'color': kDanger,
          'icon': Icons.person_off_rounded,
        };
      case 'LEAVE':
        return {
          'label': 'LEAVE',
          'color': Colors.purple,
          'icon': Icons.beach_access_rounded,
        };
      default:
        return {
          'label': 'OFFLINE',
          'color': Colors.grey,
          'icon': Icons.circle_rounded,
        };
    }
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Sales':
        return Colors.teal;
      case 'Delivery':
        return Colors.orange;
      case 'Field Staff':
        return Colors.blue;
      case 'Office Staff':
        return kPrimary;
      default:
        return kSubText;
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}