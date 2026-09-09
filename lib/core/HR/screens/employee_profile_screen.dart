// screens/employee_profile_screen.dart - EMPLOYEE PROFILE & SELF-SERVICE

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final String? employeeId;
  const EmployeeProfileScreen({super.key, this.employeeId});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTab = 'Profile';
  late TabController _tabController;
  bool _isEditing = false;
  bool _isDarkMode = false;

  // Employee Data
  final Map<String, dynamic> _employeeData = {
    'id': 'EMP-001',
    'name': 'Ahmed Khan',
    'email': 'ahmed.khan@company.com',
    'phone': '+92 300 1234567',
    'designation': 'Senior Software Engineer',
    'department': 'IT',
    'office': 'Head Office',
    'joiningDate': DateTime(2024, 1, 15),
    'employeeType': 'Full Time',
    'status': 'Active',
    'shift': 'Regular Shift (9-6)',
    'basicSalary': 120000,
    'profileImage': null,
    'dateOfBirth': DateTime(1992, 5, 10),
    'gender': 'Male',
    'bloodGroup': 'B+',
    'emergencyContact': '+92 300 7654321',
    'emergencyName': 'Fatima Khan',
    'relationship': 'Spouse',
    'address': 'House #12, Street 5, Clifton, Karachi',
    'city': 'Karachi',
    'country': 'Pakistan',
    'about': 'Passionate software engineer with 8+ years of experience in building scalable enterprise applications. Specialized in Flutter, React Native, and Node.js.',
  };

  // Leave Balance Data
  final List<Map<String, dynamic>> _leaveBalance = [
    {'type': 'Casual Leave', 'used': 4, 'total': 12, 'color': Colors.blue},
    {'type': 'Sick Leave', 'used': 2, 'total': 8, 'color': Colors.orange},
    {'type': 'Annual Leave', 'used': 8, 'total': 15, 'color': Colors.green},
    {'type': 'Emergency Leave', 'used': 1, 'total': 3, 'color': Colors.purple},
  ];

  // Attendance Summary
  final Map<String, dynamic> _attendanceSummary = {
    'present': 18,
    'late': 2,
    'absent': 0,
    'leave': 2,
    'holiday': 4,
    'weeklyOff': 4,
    'overtime': 12.5,
    'workingHours': 142,
  };

  // Documents
  final List<Map<String, dynamic>> _documents = [
    {
      'name': 'CV/Resume',
      'type': 'PDF',
      'size': '2.4 MB',
      'date': DateTime(2026, 8, 10),
      'icon': Icons.description_rounded,
      'color': Colors.red,
    },
    {
      'name': 'Offer Letter',
      'type': 'PDF',
      'size': '1.8 MB',
      'date': DateTime(2026, 1, 15),
      'icon': Icons.assignment_rounded,
      'color': Colors.blue,
    },
    {
      'name': 'ID Card',
      'type': 'PNG',
      'size': '856 KB',
      'date': DateTime(2026, 1, 20),
      'icon': Icons.credit_card_rounded,
      'color': Colors.green,
    },
    {
      'name': 'Payroll Slip - Sep 2026',
      'type': 'PDF',
      'size': '1.2 MB',
      'date': DateTime(2026, 9, 30),
      'icon': Icons.receipt_long_rounded,
      'color': Colors.purple,
    },
  ];

  // Achievements
  final List<Map<String, dynamic>> _achievements = [
    {
      'title': 'Employee of the Month',
      'date': DateTime(2026, 8, 1),
      'description': 'Outstanding performance and dedication',
      'icon': Icons.emoji_events_rounded,
      'color': Colors.amber,
    },
    {
      'title': 'Best Team Player',
      'date': DateTime(2026, 6, 15),
      'description': 'Exceptional collaboration skills',
      'icon': Icons.people_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'Innovation Award',
      'date': DateTime(2026, 4, 10),
      'description': 'Introduced new process improvements',
      'icon': Icons.lightbulb_rounded,
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          _buildProfileHeader(),
          _buildTabBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _buildProfileView(),
                  _buildAttendanceView(),
                  _buildDocumentsView(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? Container(
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
                onPressed: () {
                  setState(() {
                    _isEditing = !_isEditing;
                  });
                },
                backgroundColor: _isEditing ? kSuccess : kPrimary,
                elevation: 0,
                child: Icon(
                  _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          : null,
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
                      'My Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _employeeData['name'] as String,
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
                  setState(() {});
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showSettingsMenu(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
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
  // PROFILE HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimary.withValues(alpha: 0.2),
                      kPrimary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimary.withValues(alpha: 0.3),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _employeeData['profileImage'] != null
                      ? Image.network(
                          _employeeData['profileImage'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                        )
                      : _buildAvatarPlaceholder(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: kSuccess,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employeeData['name'] as String,
                  style:  TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_employeeData['designation']} • ${_employeeData['department']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: kSubText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kSuccess.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: kSuccess.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: kSuccess,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: kSuccess,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _employeeData['employeeType'] as String,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _employeeData['id'] as String,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
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

  Widget _buildAvatarPlaceholder() {
    final name = _employeeData['name'] as String;
    final initials = name.split(' ').map((e) => e[0]).join('').toUpperCase();
    return Container(
      color: kPrimary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: kPrimary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: kPrimary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: kPrimary,
        unselectedLabelColor: kSubText,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline_rounded, size: 16),
                SizedBox(width: 4),
                Text('Profile'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fingerprint_rounded, size: 16),
                SizedBox(width: 4),
                Text('Attendance'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_rounded, size: 16),
                SizedBox(width: 4),
                Text('Documents'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PROFILE VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Leave Balance
          _buildLeaveBalanceCard(),
          const SizedBox(height: 12),
          // Personal Info
          _buildPersonalInfoCard(),
          const SizedBox(height: 12),
          // Emergency Contact
          _buildEmergencyContactCard(),
          const SizedBox(height: 12),
          // Achievements
          _buildAchievementsCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE BALANCE CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLeaveBalanceCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                'Leave Balance',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // View all leaves
                },
                child: Text(
                  'Apply Leave',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._leaveBalance.map((leave) {
            final used = (leave['used'] as int) / (leave['total'] as int);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: leave['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          leave['type'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                      ),
                      Text(
                        '${leave['used']}/${leave['total']}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: used,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(leave['color']),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PERSONAL INFO CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPersonalInfoCard() {
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
            'Personal Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline_rounded, 'Full Name', _employeeData['name']),
          _infoRow(Icons.email_outlined, 'Email', _employeeData['email']),
          _infoRow(Icons.phone_outlined, 'Phone', _employeeData['phone']),
          _infoRow(Icons.cake_rounded, 'Date of Birth',
              DateFormat('dd MMM yyyy').format(_employeeData['dateOfBirth'])),
          _infoRow(Icons.male_rounded, 'Gender', _employeeData['gender']),
          _infoRow(Icons.bloodtype_rounded, 'Blood Group', _employeeData['bloodGroup']),
          _infoRow(Icons.location_on_outlined, 'Address', _employeeData['address']),
          _infoRow(Icons.location_city_rounded, 'City', _employeeData['city']),
          _infoRow(Icons.public_rounded, 'Country', _employeeData['country']),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About Me',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kSubText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _employeeData['about'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: kText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kSubText),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: kText,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMERGENCY CONTACT CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmergencyContactCard() {
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
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency_rounded, color: Colors.red, size: 16),
              const SizedBox(width: 8),
               Text(
                'Emergency Contact',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.person_outline_rounded,
            'Name',
            _employeeData['emergencyName'],
          ),
          _infoRow(
            Icons.phone_outlined,
            'Phone',
            _employeeData['emergencyContact'],
          ),
          _infoRow(
            Icons.family_restroom_rounded,
            'Relationship',
            _employeeData['relationship'],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACHIEVEMENTS CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAchievementsCard() {
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
            'Achievements',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
          const SizedBox(height: 12),
          ..._achievements.map((achievement) {
            return Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: achievement['color'].withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: achievement['color'].withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: achievement['color'].withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      achievement['icon'],
                      size: 16,
                      color: achievement['color'],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement['title'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kText,
                          ),
                        ),
                        Text(
                          achievement['description'],
                          style: TextStyle(
                            fontSize: 10,
                            color: kSubText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM yyyy').format(achievement['date']),
                    style: TextStyle(
                      fontSize: 9,
                      color: kSubText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ATTENDANCE VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAttendanceView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Attendance Summary
          Container(
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
                  'This Month Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _attendanceStatItem(
                      'Present',
                      '${_attendanceSummary['present']}',
                      kSuccess,
                      Icons.check_circle_rounded,
                    ),
                    _attendanceStatItem(
                      'Late',
                      '${_attendanceSummary['late']}',
                      kWarning,
                      Icons.warning_rounded,
                    ),
                    _attendanceStatItem(
                      'Absent',
                      '${_attendanceSummary['absent']}',
                      kDanger,
                      Icons.person_off_rounded,
                    ),
                    _attendanceStatItem(
                      'Leave',
                      '${_attendanceSummary['leave']}',
                      Colors.purple,
                      Icons.beach_access_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _attendanceStatItem(
                      'Holiday',
                      '${_attendanceSummary['holiday']}',
                      Colors.blue,
                      Icons.celebration_rounded,
                    ),
                    _attendanceStatItem(
                      'Weekly Off',
                      '${_attendanceSummary['weeklyOff']}',
                      Colors.orange,
                      Icons.weekend_rounded,
                    ),
                    _attendanceStatItem(
                      'Overtime',
                      '${_attendanceSummary['overtime']}h',
                      Colors.purple,
                      Icons.access_time_rounded,
                    ),
                    _attendanceStatItem(
                      'Hours',
                      '${_attendanceSummary['workingHours']}h',
                      Colors.teal,
                      Icons.work_history_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Recent Attendance
          Container(
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
                  'Recent Attendance',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(7, (index) {
                  final date = DateTime.now().subtract(Duration(days: index));
                  final statuses = ['Present', 'Present', 'Late', 'Present', 'Leave', 'Present', 'Weekly Off'];
                  final status = statuses[index % statuses.length];
                  final statusData = _getAttendanceStatusData(status);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: statusData['color'].withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            statusData['icon'],
                            size: 18,
                            color: statusData['color'],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, dd MMM').format(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              Text(
                                'Check-in: ${DateFormat('hh:mm a').format(DateTime(2026, 9, 1, 9, 3 + index))}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: kSubText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusData['color'].withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusData['color'].withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: statusData['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _attendanceStatItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 7,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getAttendanceStatusData(String status) {
    switch (status) {
      case 'Present':
        return {
          'label': 'PRESENT',
          'color': kSuccess,
          'icon': Icons.check_circle_rounded,
        };
      case 'Late':
        return {
          'label': 'LATE',
          'color': kWarning,
          'icon': Icons.warning_rounded,
        };
      case 'Absent':
        return {
          'label': 'ABSENT',
          'color': kDanger,
          'icon': Icons.person_off_rounded,
        };
      case 'Leave':
        return {
          'label': 'LEAVE',
          'color': Colors.purple,
          'icon': Icons.beach_access_rounded,
        };
      case 'Weekly Off':
        return {
          'label': 'WEEKLY OFF',
          'color': Colors.orange,
          'icon': Icons.weekend_rounded,
        };
      default:
        return {
          'label': 'UNKNOWN',
          'color': Colors.grey,
          'icon': Icons.help_rounded,
        };
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DOCUMENTS VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDocumentsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     Text(
                      'My Documents',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kText,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Upload document
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: kPrimary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.upload_file_rounded,
                              size: 14,
                              color: kPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Upload',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._documents.map((doc) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: kBgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: doc['color'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            doc['icon'],
                            size: 18,
                            color: doc['color'],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc['name'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${doc['type']} • ${doc['size']} • ${DateFormat('dd MMM yyyy').format(doc['date'])}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: kSubText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.download_rounded,
                            size: 18,
                            color: kSubText,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📄 Downloading document...'),
                                backgroundColor: kSuccess,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Quick Actions
          Container(
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
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _quickActionItem(
                      Icons.description_rounded,
                      'Request\nDocument',
                      Colors.blue,
                      () {},
                    ),
                    _quickActionItem(
                      Icons.receipt_long_rounded,
                      'Request\nPayslip',
                      Colors.purple,
                      () {},
                    ),
                    _quickActionItem(
                      Icons.print_rounded,
                      'Print\nDocuments',
                      Colors.orange,
                      () {},
                    ),
                    _quickActionItem(
                      Icons.share_rounded,
                      'Share\nDocuments',
                      Colors.green,
                      () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _quickActionItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: kText,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SETTINGS MENU
  // ═══════════════════════════════════════════════════════════════

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
             Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 16),
            _settingsMenuItem(
              Icons.notifications_outlined,
              'Notifications',
              'Manage notification preferences',
              () {
                Navigator.pop(context);
              },
            ),
            _settingsMenuItem(
              Icons.lock_outlined,
              'Privacy',
              'Manage privacy settings',
              () {
                Navigator.pop(context);
              },
            ),
            _settingsMenuItem(
              Icons.dark_mode_outlined,
              'Dark Mode',
              'Switch theme preference',
              () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
                Navigator.pop(context);
              },
            ),
            _settingsMenuItem(
              Icons.info_outlined,
              'About',
              'App version 2.0.1',
              () {
                Navigator.pop(context);
              },
            ),
            _settingsMenuItem(
              Icons.logout_rounded,
              'Logout',
              'Sign out of your account',
              () {
                Navigator.pop(context);
                _showLogoutConfirmation(context);
              },
              isDanger: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _settingsMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger
              ? kDanger.withValues(alpha: 0.08)
              : kPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDanger ? kDanger : kPrimary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDanger ? kDanger : kText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: kSubText,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: kSubText,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
                  content: Text('✅ Logged out successfully!'),
                  backgroundColor: kSuccess,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}