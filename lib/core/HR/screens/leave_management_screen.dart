// screens/leave_management_screen.dart - LEAVE MANAGEMENT

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen>
    with SingleTickerProviderStateMixin {
  String _selectedTab = 'Pending';
  String _selectedFilter = 'All';
  late TabController _tabController;

  // Sample leave data
  final List<Map<String, dynamic>> _leaves = [
    {
      'id': 'LV-001',
      'employeeId': 'EMP-001',
      'employeeName': 'Ahmed Khan',
      'department': 'Sales',
      'type': 'Casual Leave',
      'fromDate': DateTime(2026, 9, 10),
      'toDate': DateTime(2026, 9, 11),
      'days': 2,
      'reason': 'Personal family event',
      'status': 'Pending',
      'appliedOn': DateTime(2026, 9, 5),
      'image': null,
    },
    {
      'id': 'LV-002',
      'employeeId': 'EMP-002',
      'employeeName': 'Sara Ali',
      'department': 'IT',
      'type': 'Sick Leave',
      'fromDate': DateTime(2026, 9, 8),
      'toDate': DateTime(2026, 9, 8),
      'days': 1,
      'reason': 'Fever and flu',
      'status': 'Approved',
      'appliedOn': DateTime(2026, 9, 7),
      'image': null,
    },
    {
      'id': 'LV-003',
      'employeeId': 'EMP-003',
      'employeeName': 'Usman Raza',
      'department': 'Sales',
      'type': 'Emergency Leave',
      'fromDate': DateTime(2026, 9, 12),
      'toDate': DateTime(2026, 9, 13),
      'days': 2,
      'reason': 'Urgent family matter',
      'status': 'Pending',
      'appliedOn': DateTime(2026, 9, 6),
      'image': null,
    },
    {
      'id': 'LV-004',
      'employeeId': 'EMP-004',
      'employeeName': 'Fatima Noor',
      'department': 'HR',
      'type': 'Annual Leave',
      'fromDate': DateTime(2026, 9, 15),
      'toDate': DateTime(2026, 9, 19),
      'days': 5,
      'reason': 'Annual vacation',
      'status': 'Pending',
      'appliedOn': DateTime(2026, 9, 1),
      'image': null,
    },
    {
      'id': 'LV-005',
      'employeeId': 'EMP-005',
      'employeeName': 'Ali Raza',
      'department': 'Finance',
      'type': 'Casual Leave',
      'fromDate': DateTime(2026, 9, 6),
      'toDate': DateTime(2026, 9, 6),
      'days': 1,
      'reason': 'Personal work',
      'status': 'Rejected',
      'appliedOn': DateTime(2026, 9, 3),
      'image': null,
    },
    {
      'id': 'LV-006',
      'employeeId': 'EMP-006',
      'employeeName': 'Zain Ahmed',
      'department': 'Operations',
      'type': 'Sick Leave',
      'fromDate': DateTime(2026, 9, 14),
      'toDate': DateTime(2026, 9, 15),
      'days': 2,
      'reason': 'Medical appointment',
      'status': 'Pending',
      'appliedOn': DateTime(2026, 9, 8),
      'image': null,
    },
    {
      'id': 'LV-007',
      'employeeId': 'EMP-007',
      'employeeName': 'Ayesha Malik',
      'department': 'Marketing',
      'type': 'Annual Leave',
      'fromDate': DateTime(2026, 9, 22),
      'toDate': DateTime(2026, 9, 26),
      'days': 5,
      'reason': 'Family trip to Murree',
      'status': 'Approved',
      'appliedOn': DateTime(2026, 9, 2),
      'image': null,
    },
    {
      'id': 'LV-008',
      'employeeId': 'EMP-008',
      'employeeName': 'Bilal Sheikh',
      'department': 'Sales',
      'type': 'Unpaid Leave',
      'fromDate': DateTime(2026, 9, 18),
      'toDate': DateTime(2026, 9, 20),
      'days': 3,
      'reason': 'Personal reasons',
      'status': 'Pending',
      'appliedOn': DateTime(2026, 9, 9),
      'image': null,
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
    final filteredLeaves = _getFilteredLeaves();

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          _buildTabBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  Expanded(child: _buildLeaveList(filteredLeaves)),
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
          onPressed: () => _showApplyLeaveDialog(context),
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
    final pendingCount = _leaves.where((l) => l['status'] == 'Pending').length;

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
                      'Leave Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '$pendingCount pending requests',
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
  // TAB BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _selectedTab = ['Pending', 'History', 'Calendar'][index];
          });
        },
        indicatorColor: kPrimary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: kPrimary,
        unselectedLabelColor: kSubText,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'History'),
          Tab(text: 'Calendar'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilterChips() {
    final filters = ['All', 'Casual', 'Sick', 'Annual', 'Emergency', 'Unpaid'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? kPrimary
                        : Colors.grey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : kSubText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLeaveList(List<Map<String, dynamic>> leaves) {
    if (leaves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.beach_access_rounded,
              size: 64,
              color: kSubText.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedTab == 'Pending'
                  ? 'No pending leave requests'
                  : 'No leave history',
              style: TextStyle(
                fontSize: 14,
                color: kSubText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: leaves.length,
      itemBuilder: (context, index) {
        final leave = leaves[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildLeaveCard(leave, context),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLeaveCard(Map<String, dynamic> leave, BuildContext context) {
    final status = leave['status'] as String;
    final statusData = _getStatusData(status);
    final isPending = status == 'Pending';

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
          color: isPending
              ? kWarning.withValues(alpha: 0.2)
              : statusData['color'].withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isPending) {
              _showLeaveDetailDialog(leave, context);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            statusData['color'].withValues(alpha: 0.2),
                            statusData['color'].withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusData['color'].withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getLeaveIcon(leave['type'] as String),
                        size: 20,
                        color: statusData['color'],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  leave['employeeName'] as String,
                                  style:  TextStyle(
                                    fontSize: 14,
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
                                  color: statusData['color']
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: statusData['color']
                                        .withValues(alpha: 0.15),
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
                                        color: statusData['color'],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusData['label'],
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: statusData['color'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${leave['department']} • ${leave['type']}',
                            style: TextStyle(
                              fontSize: 11,
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
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 10),
                // Details Row
                Row(
                  children: [
                    _detailChip(
                      Icons.calendar_today_rounded,
                      DateFormat('dd MMM').format(leave['fromDate']),
                    ),
                    const SizedBox(width: 4),
                     Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: kSubText,
                    ),
                    const SizedBox(width: 4),
                    _detailChip(
                      Icons.calendar_today_rounded,
                      DateFormat('dd MMM').format(leave['toDate']),
                    ),
                    const SizedBox(width: 8),
                    _detailChip(
                      Icons.numbers_rounded,
                      '${leave['days']} ${leave['days'] == 1 ? 'day' : 'days'}',
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yy').format(leave['appliedOn']),
                      style: TextStyle(
                        fontSize: 9,
                        color: kSubText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Reason
                Text(
                  leave['reason'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: kSubText,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Action Buttons (for pending)
                if (isPending) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showLeaveDetailDialog(leave, context);
                          },
                          icon: Icon(
                            Icons.visibility_outlined,
                            size: 14,
                            color: kSubText,
                          ),
                          label: Text(
                            'Details',
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _handleApproveLeave(leave);
                          },
                          icon: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Approve',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kSuccess,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _handleRejectLeave(leave);
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: kDanger,
                          ),
                          label: Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kDanger,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: kDanger.withValues(alpha: 0.3),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: kSubText),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: kSubText,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // LEAVE DETAIL DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showLeaveDetailDialog(Map<String, dynamic> leave, BuildContext context) {
    final status = leave['status'] as String;
    final statusData = _getStatusData(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
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
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: statusData['color'].withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              _getLeaveIcon(leave['type'] as String),
                              size: 26,
                              color: statusData['color'],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leave['employeeName'] as String,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${leave['department']} • ${leave['type']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kSubText,
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
                              color: statusData['color'].withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusData['color'].withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                                  statusData['label'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusData['color'],
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
                      // Details
                      _detailRow('Leave ID', leave['id']),
                      _detailRow(
                        'Duration',
                        '${DateFormat('dd MMM yyyy').format(leave['fromDate'])} - ${DateFormat('dd MMM yyyy').format(leave['toDate'])}',
                      ),
                      _detailRow('Days', '${leave['days']} days'),
                      _detailRow('Leave Type', leave['type']),
                      _detailRow('Applied On', DateFormat('dd MMM yyyy, hh:mm a').format(leave['appliedOn'])),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBgLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kSubText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              leave['reason'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                color: kText,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action Buttons
                      if (leave['status'] == 'Pending') ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleRejectLeave(leave);
                                },
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kDanger,
                                  side: const BorderSide(color: kDanger),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleApproveLeave(leave);
                                },
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('Approve Leave'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kSuccess,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kText,
                              ),
                            ),
                          ),
                        ),
                      ],
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
  // APPLY LEAVE DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showApplyLeaveDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final fromDateController = TextEditingController();
    final toDateController = TextEditingController();
    final reasonController = TextEditingController();
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now().add(const Duration(days: 1));
    String selectedType = 'Casual Leave';

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
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: 400,
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
                            Icons.beach_access_rounded,
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
                                'Apply Leave',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Submit a leave request',
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
                            _buildDropdownField(
                              label: 'Leave Type *',
                              value: selectedType,
                              items: const [
                                'Casual Leave',
                                'Sick Leave',
                                'Annual Leave',
                                'Emergency Leave',
                                'Unpaid Leave',
                              ],
                              onChanged: (v) => setState(() => selectedType = v!),
                            ),
                            const SizedBox(height: 16),
                            _buildDatePickerField(
                              label: 'From Date *',
                              date: fromDate,
                              controller: fromDateController,
                              onChanged: (date) {
                                setState(() {
                                  fromDate = date;
                                  fromDateController.text =
                                      DateFormat('dd MMM yyyy').format(date);
                                });
                              },
                              context: context,
                            ),
                            const SizedBox(height: 16),
                            _buildDatePickerField(
                              label: 'To Date *',
                              date: toDate,
                              controller: toDateController,
                              onChanged: (date) {
                                setState(() {
                                  toDate = date;
                                  toDateController.text =
                                      DateFormat('dd MMM yyyy').format(date);
                                });
                              },
                              context: context,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: reasonController,
                              label: 'Reason *',
                              hint: 'Enter reason for leave',
                              icon: Icons.description_outlined,
                              maxLines: 3,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter reason' : null,
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
                                    content: Text('Leave request submitted!'),
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
                              'Submit Request',
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

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 18),
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
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Please select leave type' : null,
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime date,
    required TextEditingController controller,
    required void Function(DateTime) onChanged,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2027),
        );
        if (picked != null) onChanged(picked);
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
          prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
          suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
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
        validator: (value) => value?.isEmpty ?? true ? 'Please select date' : null,
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
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _getFilteredLeaves() {
    var filtered = _leaves;

    // Filter by tab
    if (_selectedTab == 'Pending') {
      filtered = filtered.where((l) => l['status'] == 'Pending').toList();
    } else if (_selectedTab == 'History') {
      filtered = filtered.where((l) => l['status'] != 'Pending').toList();
    }

    // Filter by type
    if (_selectedFilter != 'All') {
      filtered = filtered
          .where((l) => l['type'] == _selectedFilter)
          .toList();
    }

    // Sort by applied date (newest first)
    filtered.sort((a, b) => b['appliedOn'].compareTo(a['appliedOn']));

    return filtered;
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'Pending':
        return {
          'label': 'PENDING',
          'color': kWarning,
        };
      case 'Approved':
        return {
          'label': 'APPROVED',
          'color': kSuccess,
        };
      case 'Rejected':
        return {
          'label': 'REJECTED',
          'color': kDanger,
        };
      default:
        return {
          'label': 'UNKNOWN',
          'color': Colors.grey,
        };
    }
  }

  IconData _getLeaveIcon(String type) {
    switch (type) {
      case 'Casual Leave':
        return Icons.emoji_people_rounded;
      case 'Sick Leave':
        return Icons.health_and_safety_rounded;
      case 'Annual Leave':
        return Icons.beach_access_rounded;
      case 'Emergency Leave':
        return Icons.warning_rounded;
      case 'Unpaid Leave':
        return Icons.money_off_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  void _handleApproveLeave(Map<String, dynamic> leave) {
    setState(() {
      leave['status'] = 'Approved';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${leave['employeeName']}\'s leave approved!'),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleRejectLeave(Map<String, dynamic> leave) {
    setState(() {
      leave['status'] = 'Rejected';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ ${leave['employeeName']}\'s leave rejected'),
        backgroundColor: kDanger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}