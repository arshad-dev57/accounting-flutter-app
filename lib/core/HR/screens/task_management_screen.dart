// screens/task_management_screen.dart - TASK MANAGEMENT

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  String _selectedPriority = 'All';
  late TabController _tabController;

  // Task Data
  final List<Map<String, dynamic>> _tasks = [
    {
      'id': 'T-001',
      'title': 'Complete Q3 Performance Review',
      'description': 'Review and submit performance evaluations for all team members',
      'assignedTo': 'Ahmed Khan',
      'assignedBy': 'Fatima Noor',
      'dueDate': DateTime(2026, 9, 30),
      'priority': 'High',
      'status': 'In Progress',
      'category': 'HR',
      'createdAt': DateTime(2026, 9, 1),
      'subtasks': [
        {'title': 'Review team performance', 'completed': true},
        {'title': 'Submit evaluations', 'completed': false},
        {'title': 'Schedule feedback meetings', 'completed': false},
      ],
      'attachments': 3,
      'comments': 5,
    },
    {
      'id': 'T-002',
      'title': 'Update Employee Handbook',
      'description': 'Review and update company policies and procedures',
      'assignedTo': 'Sara Ali',
      'assignedBy': 'Fatima Khan',
      'dueDate': DateTime(2026, 9, 25),
      'priority': 'Medium',
      'status': 'Pending',
      'category': 'HR',
      'createdAt': DateTime(2026, 9, 5),
      'subtasks': [
        {'title': 'Review current policies', 'completed': false},
        {'title': 'Draft updates', 'completed': false},
      ],
      'attachments': 1,
      'comments': 2,
    },
    {
      'id': 'T-003',
      'title': 'Prepare Monthly Sales Report',
      'description': 'Compile and analyze sales data for September',
      'assignedTo': 'Usman Raza',
      'assignedBy': 'Ali Raza',
      'dueDate': DateTime(2026, 9, 20),
      'priority': 'High',
      'status': 'Completed',
      'category': 'Sales',
      'createdAt': DateTime(2026, 9, 2),
      'subtasks': [
        {'title': 'Collect sales data', 'completed': true},
        {'title': 'Analyze trends', 'completed': true},
        {'title': 'Create presentation', 'completed': true},
      ],
      'attachments': 2,
      'comments': 1,
    },
    {
      'id': 'T-004',
      'title': 'Organize Team Building Event',
      'description': 'Plan and execute quarterly team building activity',
      'assignedTo': 'Fatima Noor',
      'assignedBy': 'Usman Raza',
      'dueDate': DateTime(2026, 10, 15),
      'priority': 'Low',
      'status': 'Pending',
      'category': 'Events',
      'createdAt': DateTime(2026, 9, 8),
      'subtasks': [
        {'title': 'Choose venue', 'completed': false},
        {'title': 'Plan activities', 'completed': false},
        {'title': 'Send invitations', 'completed': false},
      ],
      'attachments': 0,
      'comments': 3,
    },
    {
      'id': 'T-005',
      'title': 'Review Q3 Budget',
      'description': 'Analyze and approve Q3 budget allocations',
      'assignedTo': 'Ali Raza',
      'assignedBy': 'Sana Malik',
      'dueDate': DateTime(2026, 9, 18),
      'priority': 'High',
      'status': 'In Progress',
      'category': 'Finance',
      'createdAt': DateTime(2026, 9, 10),
      'subtasks': [
        {'title': 'Review expenses', 'completed': true},
        {'title': 'Approve budget', 'completed': false},
      ],
      'attachments': 4,
      'comments': 2,
    },
    {
      'id': 'T-006',
      'title': 'Design Marketing Campaign',
      'description': 'Create marketing materials for new product launch',
      'assignedTo': 'Ayesha Noor',
      'assignedBy': 'Danish Khan',
      'dueDate': DateTime(2026, 10, 5),
      'priority': 'Medium',
      'status': 'Pending',
      'category': 'Marketing',
      'createdAt': DateTime(2026, 9, 12),
      'subtasks': [
        {'title': 'Design concepts', 'completed': false},
        {'title': 'Create content', 'completed': false},
        {'title': 'Review with team', 'completed': false},
      ],
      'attachments': 2,
      'comments': 4,
    },
  ];

  // Task Statistics
  final Map<String, dynamic> _taskStats = {
    'total': 6,
    'completed': 1,
    'inProgress': 2,
    'pending': 3,
    'highPriority': 3,
    'mediumPriority': 2,
    'lowPriority': 1,
    'overdue': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          _buildTaskStats(),
          _buildTabBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: IndexedStack(
                      index: _tabController.index,
                      children: [
                        _buildTaskList(filteredTasks),
                        _buildTaskList(
                          filteredTasks.where((t) => t['status'] == 'Pending').toList(),
                        ),
                        _buildTaskList(
                          filteredTasks.where((t) => t['status'] == 'In Progress').toList(),
                        ),
                        _buildTaskList(
                          filteredTasks.where((t) => t['status'] == 'Completed').toList(),
                        ),
                      ],
                    ),
                  ),
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
          onPressed: () => _showCreateTaskDialog(context),
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
                      'Task Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_taskStats['total']} tasks • ${_taskStats['pending']} pending',
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
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TASK STATS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTaskStats() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statCard('Total', '${_taskStats['total']}', kPrimary),
          _statCard('Pending', '${_taskStats['pending']}', kWarning),
          _statCard('In Progress', '${_taskStats['inProgress']}', Colors.blue),
          _statCard('Completed', '${_taskStats['completed']}', kSuccess),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
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
                fontSize: 8,
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'In Progress'),
          Tab(text: 'Done'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilterChips() {
    final priorities = ['All', 'High', 'Medium', 'Low'];
    final categories = ['All', 'HR', 'Sales', 'Finance', 'Marketing', 'Events'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...priorities.map((priority) {
            final isSelected = _selectedPriority == priority;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getPriorityColor(priority)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _getPriorityColor(priority)
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : kSubText,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          ...categories.map((category) {
            final isSelected = _selectedFilter == category;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = category;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? kPrimary
                          : Colors.grey.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : kSubText,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TASK LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_rounded,
              size: 64,
              color: kSubText.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No tasks found',
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
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildTaskCard(task, context),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TASK CARD - Advanced
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTaskCard(Map<String, dynamic> task, BuildContext context) {
    final priority = task['priority'] as String;
    final priorityColor = _getPriorityColor(priority);
    final status = task['status'] as String;
    final statusColor = _getStatusColor(status);
    final isOverdue = task['dueDate'].isBefore(DateTime.now()) &&
        status != 'Completed';
    final subtaskProgress = _calculateSubtaskProgress(task['subtasks']);

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
          color: isOverdue
              ? kDanger.withValues(alpha: 0.15)
              : priorityColor.withValues(alpha: 0.15),
          width: isOverdue ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showTaskDetail(task, context);
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
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isOverdue ? kDanger : priorityColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isOverdue ? kDanger : kText,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: priorityColor.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  priority,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimary.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  task['category'],
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: kSubText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: kDanger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: kDanger.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: kDanger,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  task['description'],
                  style: TextStyle(
                    fontSize: 11,
                    color: kSubText,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Progress Bar (if subtasks exist)
                if (task['subtasks'].isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: subtaskProgress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              subtaskProgress >= 0.8
                                  ? kSuccess
                                  : subtaskProgress >= 0.5
                                      ? kWarning
                                      : kPrimary,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(subtaskProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kSubText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 12,
                      color: kSubText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task['assignedTo'],
                      style: TextStyle(
                        fontSize: 10,
                        color: kSubText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: isOverdue ? kDanger : kSubText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM').format(task['dueDate']),
                      style: TextStyle(
                        fontSize: 10,
                        color: isOverdue ? kDanger : kSubText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (task['attachments'] > 0) ...[
                      Icon(
                        Icons.attachment_rounded,
                        size: 12,
                        color: kSubText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task['attachments']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: kSubText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (task['comments'] > 0) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.comment_rounded,
                        size: 12,
                        color: kSubText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task['comments']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: kSubText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TASK DETAIL DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showTaskDetail(Map<String, dynamic> task, BuildContext context) {
    final priority = task['priority'] as String;
    final priorityColor = _getPriorityColor(priority);
    final status = task['status'] as String;
    final statusColor = _getStatusColor(status);
    final subtaskProgress = _calculateSubtaskProgress(task['subtasks']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.task_rounded,
                              size: 26,
                              color: priorityColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['title'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: priorityColor
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: priorityColor
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Text(
                                        priority,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: priorityColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: statusColor
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
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
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 16),
                      // Details
                      _detailRow('Task ID', task['id']),
                      _detailRow('Category', task['category']),
                      _detailRow('Assigned To', task['assignedTo']),
                      _detailRow('Assigned By', task['assignedBy']),
                      _detailRow('Due Date',
                          DateFormat('dd MMM yyyy').format(task['dueDate'])),
                      _detailRow('Created',
                          DateFormat('dd MMM yyyy').format(task['createdAt'])),
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
                              'Description',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kSubText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task['description'],
                              style: TextStyle(
                                fontSize: 13,
                                color: kText,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Subtasks
                      if (task['subtasks'].isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtasks',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: kText,
                              ),
                            ),
                            Text(
                              '${(subtaskProgress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kSubText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...task['subtasks'].map((subtask) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: subtask['completed'],
                                  onChanged: (value) {
                                    // Toggle subtask
                                  },
                                  activeColor: kPrimary,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                Expanded(
                                  child: Text(
                                    subtask['title'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      decoration: subtask['completed']
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: subtask['completed']
                                          ? kSubText
                                          : kText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      // Action Buttons
                      Row(
                        children: [
                          if (status != 'Completed') ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Mark as completed
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('Complete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kSuccess,
                                  side: const BorderSide(color: kSuccess),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Close'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
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
  // CREATE TASK DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showCreateTaskDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(
        DateTime.now().add(const Duration(days: 7)),
      ),
    );
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    String assignedTo = 'Ahmed Khan';
    String priority = 'Medium';
    String category = 'General';

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
                            Icons.task_rounded,
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
                                'Create Task',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a new task assignment',
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
                              controller: titleController,
                              label: 'Task Title *',
                              hint: 'Enter task title',
                              icon: Icons.title_rounded,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter title' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: descriptionController,
                              label: 'Description',
                              hint: 'Enter task description',
                              icon: Icons.description_outlined,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            _buildDatePickerField(
                              label: 'Due Date *',
                              date: dueDate,
                              controller: dueDateController,
                              onChanged: (date) {
                                setState(() {
                                  dueDate = date;
                                  dueDateController.text =
                                      DateFormat('dd MMM yyyy').format(date);
                                });
                              },
                              context: context,
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Assign To *',
                              value: assignedTo,
                              items: const [
                                'Ahmed Khan',
                                'Sara Ali',
                                'Usman Raza',
                                'Fatima Noor',
                                'Ali Raza',
                              ],
                              onChanged: (v) => setState(() => assignedTo = v!),
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Priority *',
                              value: priority,
                              items: const ['Low', 'Medium', 'High'],
                              onChanged: (v) => setState(() => priority = v!),
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Category *',
                              value: category,
                              items: const [
                                'General',
                                'HR',
                                'Sales',
                                'Finance',
                                'Marketing',
                                'Events',
                              ],
                              onChanged: (v) => setState(() => category = v!),
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
                                    content: Text('✅ Task created successfully!'),
                                    backgroundColor: kSuccess,
                                    behavior: SnackBarBehavior.floating,
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
                              'Create Task',
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
        labelStyle:  TextStyle(fontSize: 12, color: kSubText),
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
      value: value,
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
      validator: (value) => value == null ? 'Please select $label' : null,
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
          lastDate: DateTime(2030),
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

  List<Map<String, dynamic>> _getFilteredTasks() {
    var filtered = List<Map<String, dynamic>>.from(_tasks);

    if (_selectedPriority != 'All') {
      filtered = filtered
          .where((t) => t['priority'] == _selectedPriority)
          .toList();
    }

    if (_selectedFilter != 'All') {
      filtered = filtered
          .where((t) => t['category'] == _selectedFilter)
          .toList();
    }

    return filtered;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return kDanger;
      case 'Medium':
        return kWarning;
      case 'Low':
        return Colors.blue;
      default:
        return kSubText;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return kWarning;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return kSuccess;
      default:
        return kSubText;
    }
  }

  double _calculateSubtaskProgress(List<dynamic> subtasks) {
    if (subtasks.isEmpty) return 0.0;
    final completed = subtasks.where((s) => s['completed'] == true).length;
    return completed / subtasks.length;
  }
}