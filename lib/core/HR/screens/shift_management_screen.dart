// screens/shift_management_screen.dart - SHIFT MANAGEMENT

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  // Sample shift data
  final List<Map<String, dynamic>> _shifts = [
    {
      'id': 'SHIFT-001',
      'name': 'Regular Shift',
      'startTime': '09:00 AM',
      'endTime': '06:00 PM',
      'gracePeriod': 15,
      'lateThreshold': 30,
      'absentThreshold': '11:00 AM',
      'breakStart': '01:00 PM',
      'breakEnd': '02:00 PM',
      'workingDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      'weeklyOff': 'Sunday',
      'employeeCount': 78,
    },
    {
      'id': 'SHIFT-002',
      'name': 'Morning Shift',
      'startTime': '08:00 AM',
      'endTime': '04:00 PM',
      'gracePeriod': 10,
      'lateThreshold': 20,
      'absentThreshold': '10:00 AM',
      'breakStart': '12:00 PM',
      'breakEnd': '01:00 PM',
      'workingDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      'weeklyOff': 'Sat-Sun',
      'employeeCount': 32,
    },
    {
      'id': 'SHIFT-003',
      'name': 'Evening Shift',
      'startTime': '02:00 PM',
      'endTime': '10:00 PM',
      'gracePeriod': 15,
      'lateThreshold': 30,
      'absentThreshold': '04:00 PM',
      'breakStart': '06:00 PM',
      'breakEnd': '07:00 PM',
      'workingDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      'weeklyOff': 'Sunday',
      'employeeCount': 15,
    },
    {
      'id': 'SHIFT-004',
      'name': 'Field Shift',
      'startTime': '09:00 AM',
      'endTime': '06:00 PM',
      'gracePeriod': 20,
      'lateThreshold': 45,
      'absentThreshold': '12:00 PM',
      'breakStart': '01:00 PM',
      'breakEnd': '02:00 PM',
      'workingDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      'weeklyOff': 'Sunday',
      'employeeCount': 24,
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
                  Expanded(child: _buildShiftList()),
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
          onPressed: () => _showAddShiftDialog(context),
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
                      'Shifts & Schedules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_shifts.length} shifts',
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
                hintText: 'Search shifts...',
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
                _filterChip('All Shifts', true),
                const SizedBox(width: 6),
                _filterChip('Regular', false),
                const SizedBox(width: 6),
                _filterChip('Morning', false),
                const SizedBox(width: 6),
                _filterChip('Evening', false),
                const SizedBox(width: 6),
                _filterChip('Field', false),
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
  // SHIFT LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildShiftList() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _shifts.length,
      itemBuilder: (context, index) {
        final shift = _shifts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildShiftCard(shift, context),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHIFT CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildShiftCard(Map<String, dynamic> shift, BuildContext context) {
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
          color: kPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showShiftDetails(shift, context);
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
                        Icons.schedule_rounded,
                        size: 24,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shift['name'],
                            style:  TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kText,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${shift['startTime']} - ${shift['endTime']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: kPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${shift['employeeCount']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
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
                // Details Row
                Row(
                  children: [
                    _detailChip(
                      Icons.timer_outlined,
                      'Grace: ${shift['gracePeriod']}m',
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _detailChip(
                      Icons.warning_outlined,
                      'Late: ${shift['lateThreshold']}m',
                      kWarning,
                    ),
                    const SizedBox(width: 8),
                    _detailChip(
                      Icons.person_off_outlined,
                      'Absent: ${shift['absentThreshold']}',
                      kDanger,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Working Days
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ..._buildWorkingDays(shift['workingDays']),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Off: ${shift['weeklyOff']}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: kDanger,
                        ),
                      ),
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
                          _showEditShiftDialog(context, shift);
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
                          _showAssignEmployees(shift, context);
                        },
                        icon: Icon(
                          Icons.assignment_ind_outlined,
                          size: 14,
                          color: kPrimary,
                        ),
                        label: Text(
                          'Assign',
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

  Widget _detailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWorkingDays(List<String> days) {
    const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return allDays.map((day) {
      final isWorking = days.contains(day);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isWorking ? kSuccess.withValues(alpha: 0.08) : kDanger.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isWorking ? kSuccess.withValues(alpha: 0.2) : kDanger.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Text(
          day,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isWorking ? kSuccess : kDanger,
          ),
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // ADD SHIFT DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showAddShiftDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final startTimeController = TextEditingController(text: '09:00 AM');
    final endTimeController = TextEditingController(text: '06:00 PM');
    final graceController = TextEditingController(text: '15');
    final lateController = TextEditingController(text: '30');
    final absentController = TextEditingController(text: '11:00 AM');
    final breakStartController = TextEditingController(text: '01:00 PM');
    final breakEndController = TextEditingController(text: '02:00 PM');
    String weeklyOff = 'Sunday';
    List<String> selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

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
                maxHeight: MediaQuery.of(context).size.height * 0.92,
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
                  _buildDialogHeader(
                    icon: Icons.schedule_rounded,
                    title: 'Add Shift',
                    subtitle: 'Create a new work schedule',
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
                              label: 'Shift Name *',
                              hint: 'e.g., Regular Shift',
                              icon: Icons.title_rounded,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter shift name' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimePickerField(
                                    controller: startTimeController,
                                    label: 'Start Time *',
                                    hint: '09:00 AM',
                                    icon: Icons.play_arrow_rounded,
                                    validator: (value) =>
                                        value?.isEmpty ?? true ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTimePickerField(
                                    controller: endTimeController,
                                    label: 'End Time *',
                                    hint: '06:00 PM',
                                    icon: Icons.stop_rounded,
                                    validator: (value) =>
                                        value?.isEmpty ?? true ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: graceController,
                                    label: 'Grace Period (min) *',
                                    hint: '15',
                                    icon: Icons.timer_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (int.tryParse(value!) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    controller: lateController,
                                    label: 'Late Threshold (min) *',
                                    hint: '30',
                                    icon: Icons.warning_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (int.tryParse(value!) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: absentController,
                              label: 'Absent Threshold *',
                              hint: '11:00 AM',
                              icon: Icons.person_off_outlined,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildBreakSection(
                              breakStartController,
                              breakEndController,
                            ),
                            const SizedBox(height: 16),
                            _buildWorkingDaysSection(
                              selectedDays,
                              (day) => setState(() {
                                if (selectedDays.contains(day)) {
                                  selectedDays.remove(day);
                                } else {
                                  selectedDays.add(day);
                                }
                              }),
                            ),
                            const SizedBox(height: 16),
                            _buildWeeklyOffDropdown(
                              weeklyOff,
                              (value) => setState(() => weeklyOff = value!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer Buttons
                  _buildDialogFooter(
                    onCancel: () => Navigator.pop(context),
                    onSave: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Shift created successfully!'),
                            backgroundColor: kSuccess,
                          ),
                        );
                      }
                    },
                    buttonText: 'Create Shift',
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
  // EDIT SHIFT DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showEditShiftDialog(BuildContext context, Map<String, dynamic> shift) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: shift['name']);
    final startTimeController = TextEditingController(text: shift['startTime']);
    final endTimeController = TextEditingController(text: shift['endTime']);
    final graceController = TextEditingController(text: shift['gracePeriod'].toString());
    final lateController = TextEditingController(text: shift['lateThreshold'].toString());
    final absentController = TextEditingController(text: shift['absentThreshold']);
    final breakStartController = TextEditingController(text: shift['breakStart']);
    final breakEndController = TextEditingController(text: shift['breakEnd']);
    String weeklyOff = shift['weeklyOff'];
    List<String> selectedDays = List<String>.from(shift['workingDays']);

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
                maxHeight: MediaQuery.of(context).size.height * 0.92,
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
                  _buildDialogHeader(
                    icon: Icons.edit_rounded,
                    title: 'Edit Shift',
                    subtitle: 'Update shift schedule',
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
                              label: 'Shift Name *',
                              hint: 'e.g., Regular Shift',
                              icon: Icons.title_rounded,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter shift name' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTimePickerField(
                                    controller: startTimeController,
                                    label: 'Start Time *',
                                    hint: '09:00 AM',
                                    icon: Icons.play_arrow_rounded,
                                    validator: (value) =>
                                        value?.isEmpty ?? true ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTimePickerField(
                                    controller: endTimeController,
                                    label: 'End Time *',
                                    hint: '06:00 PM',
                                    icon: Icons.stop_rounded,
                                    validator: (value) =>
                                        value?.isEmpty ?? true ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    controller: graceController,
                                    label: 'Grace Period (min) *',
                                    hint: '15',
                                    icon: Icons.timer_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (int.tryParse(value!) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildFormField(
                                    controller: lateController,
                                    label: 'Late Threshold (min) *',
                                    hint: '30',
                                    icon: Icons.warning_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Required';
                                      if (int.tryParse(value!) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: absentController,
                              label: 'Absent Threshold *',
                              hint: '11:00 AM',
                              icon: Icons.person_off_outlined,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildBreakSection(
                              breakStartController,
                              breakEndController,
                            ),
                            const SizedBox(height: 16),
                            _buildWorkingDaysSection(
                              selectedDays,
                              (day) => setState(() {
                                if (selectedDays.contains(day)) {
                                  selectedDays.remove(day);
                                } else {
                                  selectedDays.add(day);
                                }
                              }),
                            ),
                            const SizedBox(height: 16),
                            _buildWeeklyOffDropdown(
                              weeklyOff,
                              (value) => setState(() => weeklyOff = value!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildDialogFooter(
                    onCancel: () => Navigator.pop(context),
                    onSave: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Shift updated successfully!'),
                            backgroundColor: kSuccess,
                          ),
                        );
                      }
                    },
                    buttonText: 'Update Shift',
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
  // SHIFT DETAILS
  // ═══════════════════════════════════════════════════════════════

  void _showShiftDetails(Map<String, dynamic> shift, BuildContext context) {
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
                              Icons.schedule_rounded,
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
                                  shift['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${shift['startTime']} - ${shift['endTime']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kPrimary,
                                    fontWeight: FontWeight.w600,
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
                      _detailRow('Shift ID', shift['id']),
                      _detailRow('Employees Assigned', '${shift['employeeCount']}'),
                      _detailRow('Grace Period', '${shift['gracePeriod']} minutes'),
                      _detailRow('Late Threshold', '${shift['lateThreshold']} minutes'),
                      _detailRow('Absent Threshold', shift['absentThreshold']),
                      _detailRow('Break Time', '${shift['breakStart']} - ${shift['breakEnd']}'),
                      _detailRow('Weekly Off', shift['weeklyOff']),
                      const SizedBox(height: 12),
                      Text(
                        'Working Days',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _buildWorkingDays(shift['workingDays']),
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

  // ═══════════════════════════════════════════════════════════════
  // ASSIGN EMPLOYEES
  // ═══════════════════════════════════════════════════════════════

  void _showAssignEmployees(Map<String, dynamic> shift, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.assignment_ind, color: kPrimary),
            const SizedBox(width: 8),
            Text('Assign Employees'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shift: ${shift['name']}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: 8,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final employees = [
                    'Ahmed Khan',
                    'Sara Ali',
                    'Usman Raza',
                    'Fatima Noor',
                    'Ali Raza',
                    'Zain Ahmed',
                    'Ayesha Malik',
                    'Bilal Sheikh',
                  ];
                  return Row(
                    children: [
                      Checkbox(
                        value: index < 4,
                        onChanged: (_) {},
                        activeColor: kPrimary,
                      ),
                      Expanded(
                        child: Text(
                          employees[index],
                          style: TextStyle(
                            fontSize: 13,
                            color: kText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'EMP-00${index + 1}',
                          style: TextStyle(
                            fontSize: 9,
                            color: kSubText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kPrimary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '4 employees currently assigned to this shift',
                      style: TextStyle(
                        fontSize: 11,
                        color: kSubText,
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
              'Cancel',
              style: TextStyle(color: kSubText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Employees assigned successfully!'),
                  backgroundColor: kSuccess,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOG HELPERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDialogHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:  TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }

  Widget _buildDialogFooter({
    required VoidCallback onCancel,
    required VoidCallback onSave,
    required String buttonText,
  }) {
    return Container(
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
              onPressed: onCancel,
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
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
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

  Widget _buildTimePickerField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FormFieldValidator<String>? validator,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (picked != null) {
          final timeString = DateFormat('hh:mm a').format(
            DateTime(2024, 1, 1, picked.hour, picked.minute),
          );
          controller.text = timeString;
        }
      },
      child: TextFormField(
        controller: controller,
        enabled: false,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: kSubText),
          suffixIcon: const Icon(Icons.access_time, size: 18),
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
      ),
    );
  }

  Widget _buildBreakSection(
    TextEditingController breakStart,
    TextEditingController breakEnd,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Break Time',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimePickerField(
                controller: breakStart,
                label: 'Break Start',
                hint: '01:00 PM',
                icon: Icons.free_breakfast_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimePickerField(
                controller: breakEnd,
                label: 'Break End',
                hint: '02:00 PM',
                icon: Icons.free_breakfast_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkingDaysSection(
    List<String> selectedDays,
    void Function(String) onToggle,
  ) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Working Days *',
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
          children: days.map((day) {
            final isSelected = selectedDays.contains(day);
            return GestureDetector(
              onTap: () => onToggle(day),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
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
                  day,
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
      ],
    );
  }

  Widget _buildWeeklyOffDropdown(
    String value,
    void Function(String?) onChanged,
  ) {
    final options = ['Sunday', 'Saturday', 'Friday', 'Thursday', 'Wed-Sun', 'Sat-Sun'];
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Weekly Off *',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        labelStyle:  TextStyle(fontSize: 12, color: kSubText),
      ),
      style: const TextStyle(
        fontSize: 13,
        color: Colors.black87,
      ),
      items: options.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select weekly off' : null,
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
}