// screens/employee_attendance_screen.dart - EMPLOYEE ATTENDANCE (Mobile)

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:BisonsTechs_app/core/HR/services/location_tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  State<EmployeeAttendanceScreen> createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen>
    with SingleTickerProviderStateMixin {
  // Attendance State
  String _currentStatus = 'NOT_CHECKED_IN'; // NOT_CHECKED_IN | WORKING | ON_BREAK | CHECKED_OUT
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  DateTime? _breakStartTime;
  List<Map<String, dynamic>> breakHistory = [];
  Duration totalWorkingDuration = Duration.zero;
  Duration _currentBreakDuration = Duration.zero;
  late AnimationController _pulseController;
  bool isInsideGeofence = true;

  String _officeName = '';
  String _employeeName = 'Employee';
  String _shiftStart = '';
  String _shiftEnd = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadToday();
  }

  Future<void> _loadToday() async {
    try {
      final data = await HrApiService.instance.myAttendance();
      if (!mounted) return;
      final emp = data['employee'] as Map<String, dynamic>? ?? {};
      final att = data['attendance'] as Map<String, dynamic>?;
      setState(() {
        _employeeName = emp['name']?.toString() ?? 'Employee';
        _officeName = emp['office']?.toString() ?? '';
        _shiftStart = emp['shift']?.toString() ?? '';
        _shiftEnd = '';
        if (att == null) {
          _currentStatus = 'NOT_CHECKED_IN';
          _checkInTime = null;
          _checkOutTime = null;
        } else if (att['isCheckedIn'] == true) {
          _currentStatus = 'WORKING';
          _checkInTime = DateTime.tryParse(att['checkIn']?.toString() ?? '');
          _checkOutTime = null;
        } else if (att['checkOut'] != null) {
          _currentStatus = 'CHECKED_OUT';
          _checkInTime = DateTime.tryParse(att['checkIn']?.toString() ?? '');
          _checkOutTime = DateTime.tryParse(att['checkOut']?.toString() ?? '');
        } else {
          _currentStatus = 'NOT_CHECKED_IN';
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // MAIN BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    _buildShiftCard(),
                    const SizedBox(height: 16),
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    _buildTodayStats(),
                    const SizedBox(height: 16),
                    _buildBreakHistory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopHeader() {
    return Container(
      color: kPrimary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            // Back Button
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            // Employee Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Profile
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _getInitials(_employeeName),
                  style: const TextStyle(
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHIFT CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildShiftCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: kPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Today\'s Shift',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kSubText,
                      ),
                    ),
                     SizedBox(height: 2),
                    Text(
                      '$_shiftStart - $_shiftEnd',
                      style:  TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kText,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isInsideGeofence
                      ? kSuccess.withValues(alpha: 0.08)
                      : kWarning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isInsideGeofence
                        ? kSuccess.withValues(alpha: 0.2)
                        : kWarning.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isInsideGeofence ? kSuccess : kWarning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isInsideGeofence ? 'Inside' : 'Outside',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isInsideGeofence ? kSuccess : kWarning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: kSubText,
              ),
              const SizedBox(width: 6),
              Text(
                _officeName,
                style: TextStyle(
                  fontSize: 12,
                  color: kSubText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_checkInTime != null) ...[
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: kSubText,
                ),
                const SizedBox(width: 6),
                Text(
                  'Check-in: ${DateFormat('hh:mm a').format(_checkInTime!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STATUS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatusCard() {
    final statusData = _getStatusData(_currentStatus);
    final workingHours = _getWorkingHours();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusData['color'].withValues(alpha: 0.12),
            statusData['color'].withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusData['color'].withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusData['color'].withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Icon & Label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentStatus == 'WORKING' || _currentStatus == 'ON_BREAK')
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 12 + (_pulseController.value * 6),
                      height: 12 + (_pulseController.value * 6),
                      decoration: BoxDecoration(
                        color: statusData['color'].withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusData['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              if (_currentStatus != 'WORKING' && _currentStatus != 'ON_BREAK')
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusData['color'],
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                statusData['label'],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: statusData['color'],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Working Hours
          if (_currentStatus != 'NOT_CHECKED_IN' &&
              _currentStatus != 'CHECKED_OUT')
            Text(
              workingHours,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: statusData['color'],
                letterSpacing: -0.5,
              ),
            ),
          if (_currentStatus == 'NOT_CHECKED_IN')
             Text(
              'Not Checked In Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kSubText,
              ),
            ),
          if (_currentStatus == 'CHECKED_OUT')
             Text(
              'Have a great day! 👋',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kSubText,
              ),
            ),
          if (_currentStatus == 'ON_BREAK') ...[
            const SizedBox(height: 4),
            Text(
              'Break: ${_formatDuration(_currentBreakDuration)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: statusData['color'],
              ),
            ),
          ],
          // Check-in/out info
          if (_checkInTime != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✅ Checked in at ${DateFormat('hh:mm a').format(_checkInTime!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: kSubText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_checkOutTime != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• Checked out at ${DateFormat('hh:mm a').format(_checkOutTime!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: kSubText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          // Main Actions Row
          Row(
            children: [
              if (_currentStatus == 'NOT_CHECKED_IN')
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.login_rounded,
                    label: 'CHECK IN',
                    color: kSuccess,
                    onTap: _handleCheckIn,
                  ),
                ),
              if (_currentStatus == 'WORKING') ...[
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.free_breakfast_rounded,
                    label: 'START BREAK',
                    color: Colors.orange,
                    onTap: _handleStartBreak,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.logout_rounded,
                    label: 'CHECK OUT',
                    color: kDanger,
                    onTap: _handleCheckOut,
                  ),
                ),
              ],
              if (_currentStatus == 'ON_BREAK')
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.play_arrow_rounded,
                    label: 'RESUME WORK',
                    color: kPrimary,
                    onTap: _handleResumeWork,
                    isLarge: true,
                  ),
                ),
              if (_currentStatus == 'CHECKED_OUT')
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: kSuccess,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Checked Out',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Auto-attendance notification (for demo)
          if (_currentStatus == 'WORKING' && _checkInTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kPrimary.withValues(alpha: 0.1),
                  width: 1,
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
                      'Auto attendance marked via geofence at ${DateFormat('hh:mm a').format(_checkInTime!)}',
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
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: isLarge ? 16 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: isLarge ? 28 : 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 13 : 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TODAY'S STATS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTodayStats() {
    return Container(
      padding: const EdgeInsets.all(16),
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
           Text(
            'Today\'s Stats',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statItem(
                icon: Icons.work_history_rounded,
                label: 'Worked',
                value: _getWorkingHours(),
                color: kPrimary,
              ),
              _statItem(
                icon: Icons.free_breakfast_rounded,
                label: 'Breaks',
                value: '${breakHistory.length}',
                color: Colors.orange,
              ),
              _statItem(
                icon: Icons.timer_rounded,
                label: 'Break Time',
                value: _getTotalBreakDuration(),
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BREAK HISTORY
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBreakHistory() {
    if (breakHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
           Text(
            'Break History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 10),
          ...breakHistory.map((breakItem) {
            final start = breakItem['start'] as DateTime;
            final end = breakItem['end'] as DateTime?;
            final duration = end != null
                ? end.difference(start)
                : DateTime.now().difference(start);
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.free_breakfast_rounded,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Break #${breakHistory.indexOf(breakItem) + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kText,
                            ),
                          ),
                          Text(
                            '${DateFormat('hh:mm a').format(start)} - ${end != null ? DateFormat('hh:mm a').format(end) : 'On Break...'}',
                            style: TextStyle(
                              fontSize: 10,
                              color: kSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      end != null ? _formatDuration(duration) : '...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: end != null ? kSuccess : kWarning,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTION HANDLERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _handleCheckIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final tracking = Get.isRegistered<LocationTrackingService>()
          ? Get.find<LocationTrackingService>()
          : Get.put(LocationTrackingService(), permanent: true);
      final pos = await tracking.currentPosition();
      if (pos == null) {
        _showSnackbar('Could not read GPS. Enable location and try again.', kDanger);
        return;
      }
      await HrApiService.instance.checkIn(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      await _loadToday();
      _showSnackbar('Checked in successfully!', kSuccess);
    } catch (e) {
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''), kDanger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _handleStartBreak() {
    setState(() {
      _currentStatus = 'ON_BREAK';
      _breakStartTime = DateTime.now();
      _currentBreakDuration = Duration.zero;
      _showSnackbar('⏸️ Break started!', Colors.orange);
    });
  }

  void _handleResumeWork() {
    if (_breakStartTime != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_breakStartTime!);
      setState(() {
        _currentStatus = 'WORKING';
        breakHistory.add({
          'start': _breakStartTime!,
          'end': endTime,
        });
        _currentBreakDuration = duration;
        _breakStartTime = null;
        _showSnackbar('▶️ Resumed work!', kPrimary);
      });
    }
  }

  Future<void> _handleCheckOut() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final tracking = Get.isRegistered<LocationTrackingService>()
          ? Get.find<LocationTrackingService>()
          : Get.put(LocationTrackingService(), permanent: true);
      final pos = await tracking.currentPosition();
      if (pos == null) {
        _showSnackbar('Could not read GPS. Enable location and try again.', kDanger);
        return;
      }
      await HrApiService.instance.checkOut(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
      await _loadToday();
      _showSnackbar('Checked out successfully!', kDanger);
    } catch (e) {
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''), kDanger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'NOT_CHECKED_IN':
        return {
          'label': 'NOT CHECKED IN',
          'color': Colors.grey,
          'icon': Icons.circle_outlined,
        };
      case 'WORKING':
        return {
          'label': 'WORKING',
          'color': kSuccess,
          'icon': Icons.check_circle_rounded,
        };
      case 'ON_BREAK':
        return {
          'label': 'ON BREAK',
          'color': Colors.orange,
          'icon': Icons.free_breakfast_rounded,
        };
      case 'CHECKED_OUT':
        return {
          'label': 'CHECKED OUT',
          'color': kDanger,
          'icon': Icons.logout_rounded,
        };
      default:
        return {
          'label': 'UNKNOWN',
          'color': Colors.grey,
          'icon': Icons.help_rounded,
        };
    }
  }

  String _getWorkingHours() {
    if (_checkInTime == null) return '00h 00m';
    final end = _checkOutTime ?? DateTime.now();
    final duration = end.difference(_checkInTime!);
    // Subtract break times
    Duration totalBreak = Duration.zero;
    for (final breakItem in breakHistory) {
      if (breakItem['end'] != null) {
        totalBreak += (breakItem['end'] as DateTime)
            .difference(breakItem['start'] as DateTime);
      }
    }
    if (_currentStatus == 'ON_BREAK' && _breakStartTime != null) {
      totalBreak += DateTime.now().difference(_breakStartTime!);
    }
    final working = duration - totalBreak;
    final hours = working.inHours;
    final minutes = working.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _getTotalBreakDuration() {
    Duration total = Duration.zero;
    for (final breakItem in breakHistory) {
      if (breakItem['end'] != null) {
        total += (breakItem['end'] as DateTime)
            .difference(breakItem['start'] as DateTime);
      }
    }
    if (_currentStatus == 'ON_BREAK' && _breakStartTime != null) {
      total += DateTime.now().difference(_breakStartTime!);
    }
    return _formatDuration(total);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}