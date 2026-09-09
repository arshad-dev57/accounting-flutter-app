// screens/performance_reviews_screen.dart - PERFORMANCE REVIEWS

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PerformanceReviewsScreen extends StatefulWidget {
  const PerformanceReviewsScreen({super.key});

  @override
  State<PerformanceReviewsScreen> createState() =>
      _PerformanceReviewsScreenState();
}

class _PerformanceReviewsScreenState extends State<PerformanceReviewsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'All';
  String _selectedPeriod = 'Q3 2026';
  late TabController _tabController;

  // Performance Review Data
  final List<Map<String, dynamic>> _reviews = [
    {
      'id': 'PR-001',
      'employeeId': 'EMP-001',
      'employeeName': 'Ahmed Khan',
      'designation': 'Senior Software Engineer',
      'department': 'IT',
      'reviewer': 'Fatima Noor',
      'reviewerId': 'EMP-004',
      'period': 'Q3 2026',
      'date': DateTime(2026, 9, 15),
      'status': 'Completed',
      'overallRating': 4.5,
      'ratings': {
        'technicalSkills': 4.5,
        'communication': 4.0,
        'teamwork': 5.0,
        'problemSolving': 4.5,
        'leadership': 4.0,
        'punctuality': 4.5,
      },
      'strengths': [
        'Excellent technical skills',
        'Great problem solver',
        'Strong team player',
      ],
      'areasForImprovement': [
        'Leadership skills',
        'Public speaking',
      ],
      'comments': 'Ahmed has shown exceptional performance this quarter.',
      'goals': [
        'Lead a major project',
        'Mentor junior developers',
        'Complete AWS certification',
      ],
      'nextReviewDate': DateTime(2026, 12, 15),
    },
    {
      'id': 'PR-002',
      'employeeId': 'EMP-002',
      'employeeName': 'Sara Ali',
      'designation': 'Software Engineer',
      'department': 'IT',
      'reviewer': 'Bilal Sheikh',
      'reviewerId': 'EMP-005',
      'period': 'Q3 2026',
      'date': DateTime(2026, 9, 10),
      'status': 'Pending',
      'overallRating': null,
      'ratings': {},
      'strengths': [],
      'areasForImprovement': [],
      'comments': '',
      'goals': [],
      'nextReviewDate': DateTime(2026, 12, 10),
    },
    {
      'id': 'PR-003',
      'employeeId': 'EMP-003',
      'employeeName': 'Usman Raza',
      'designation': 'Field Salesman',
      'department': 'Sales',
      'reviewer': 'Ali Raza',
      'reviewerId': 'EMP-009',
      'period': 'Q2 2026',
      'date': DateTime(2026, 6, 20),
      'status': 'Completed',
      'overallRating': 3.8,
      'ratings': {
        'salesPerformance': 4.0,
        'clientRelations': 4.5,
        'communication': 3.5,
        'teamwork': 3.0,
        'problemSolving': 4.0,
        'punctuality': 3.5,
      },
      'strengths': [
        'Excellent client relations',
        'Strong sales skills',
      ],
      'areasForImprovement': [
        'Team collaboration',
        'Communication skills',
      ],
      'comments': 'Usman needs to work on team collaboration.',
      'goals': [
        'Increase sales by 20%',
        'Attend communication workshop',
      ],
      'nextReviewDate': DateTime(2026, 9, 20),
    },
    {
      'id': 'PR-004',
      'employeeId': 'EMP-004',
      'employeeName': 'Fatima Noor',
      'designation': 'HR Executive',
      'department': 'HR',
      'reviewer': 'Fatima Khan',
      'reviewerId': 'EMP-008',
      'period': 'Q3 2026',
      'date': DateTime(2026, 9, 5),
      'status': 'Draft',
      'overallRating': null,
      'ratings': {},
      'strengths': [],
      'areasForImprovement': [],
      'comments': '',
      'goals': [],
      'nextReviewDate': DateTime(2026, 12, 5),
    },
    {
      'id': 'PR-005',
      'employeeId': 'EMP-005',
      'employeeName': 'Ali Raza',
      'designation': 'Accountant',
      'department': 'Finance',
      'reviewer': 'Sana Malik',
      'reviewerId': 'EMP-007',
      'period': 'Q2 2026',
      'date': DateTime(2026, 6, 25),
      'status': 'Completed',
      'overallRating': 4.2,
      'ratings': {
        'technicalSkills': 4.5,
        'accuracy': 5.0,
        'communication': 3.5,
        'teamwork': 4.0,
        'problemSolving': 4.0,
        'punctuality': 4.5,
      },
      'strengths': [
        'High accuracy',
        'Strong technical skills',
      ],
      'areasForImprovement': [
        'Communication',
      ],
      'comments': 'Ali is a valuable asset to the finance team.',
      'goals': [
        'Lead financial reporting',
        'Improve presentation skills',
      ],
      'nextReviewDate': DateTime(2026, 9, 25),
    },
  ];

  // Performance Metrics
  final Map<String, dynamic> _metrics = {
    'totalReviews': 12,
    'completed': 8,
    'pending': 3,
    'draft': 1,
    'averageRating': 4.1,
    'highPerformers': 5,
    'needsImprovement': 2,
    'onTrack': 5,
  };

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
    final filteredReviews = _getFilteredReviews();

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          _buildTabBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _buildReviewsView(filteredReviews),
                  _buildMetricsView(),
                  _buildGoalsView(),
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
                onPressed: () => _showCreateReviewDialog(context),
                backgroundColor: kPrimary,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            )
          : null,
    );
  }

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
                      'Performance Reviews',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_metrics['totalReviews']} reviews • ${_metrics['pending']} pending',
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showExportOptions,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.download_outlined,
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
                Icon(Icons.receipt_long_rounded, size: 16),
                SizedBox(width: 4),
                Text('Reviews'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics_rounded, size: 16),
                SizedBox(width: 4),
                Text('Metrics'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_rounded, size: 16),
                SizedBox(width: 4),
                Text('Goals'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REVIEWS VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildReviewsView(List<Map<String, dynamic>> reviews) {
    return Column(
      children: [
        _buildFilterAndPeriod(),
        const SizedBox(height: 8),
        Expanded(
          child: reviews.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildReviewCard(review, context),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterAndPeriod() {
    final filters = ['All', 'Completed', 'Pending', 'Draft', 'Scheduled'];
    final periods = ['Q1 2026', 'Q2 2026', 'Q3 2026', 'Q4 2026', 'All'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Period Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: periods.map((period) {
                final isSelected = _selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = period;
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
                        period,
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
          ),
          const SizedBox(height: 6),
          // Filter Chips
          SingleChildScrollView(
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
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? kPrimary
                              : Colors.grey.withValues(alpha: 0.3),
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
                              color: isSelected
                                  ? Colors.white
                                  : _getStatusColor(filter),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            filter,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : kSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // REVIEW CARD - Advanced
  // ═══════════════════════════════════════════════════════════════

  Widget _buildReviewCard(Map<String, dynamic> review, BuildContext context) {
    final status = review['status'] as String;
    final statusData = _getStatusData(status);
    final isCompleted = status == 'Completed';
    final overallRating = review['overallRating'] as double?;

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
          color: isCompleted
              ? kSuccess.withValues(alpha: 0.15)
              : statusData['color'].withValues(alpha: 0.2),
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showReviewDetail(review, context);
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
                        isCompleted
                            ? Icons.verified_rounded
                            : Icons.pending_actions_rounded,
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
                                  review['employeeName'] as String,
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
                            '${review['designation']} • ${review['department']}',
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
                      'Period: ${review['period']}',
                      kPrimary,
                    ),
                    const SizedBox(width: 6),
                    _detailChip(
                      Icons.person_outline_rounded,
                      'Reviewer: ${review['reviewer']}',
                      Colors.blue,
                    ),
                    const Spacer(),
                    if (isCompleted && overallRating != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getRatingColor(overallRating),
                              _getRatingColor(overallRating)
                                  .withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              overallRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Strengths/Goals Preview
                if (isCompleted) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: (review['strengths'] as List)
                        .take(2)
                        .map((strength) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kSuccess.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: kSuccess.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              '✓ $strength',
                              style: TextStyle(
                                fontSize: 8,
                                color: kSuccess,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                  if ((review['strengths'] as List).length > 2)
                    Text(
                      '+${(review['strengths'] as List).length - 2} more',
                      style: TextStyle(
                        fontSize: 8,
                        color: kSubText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
                // Action Buttons (for pending/draft)
                if (status == 'Pending' || status == 'Draft') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showReviewDetail(review, context);
                          },
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 14,
                            color: kSubText,
                          ),
                          label: Text(
                            status == 'Draft' ? 'Continue' : 'Review',
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
                      if (status == 'Pending') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _handleCompleteReview(review);
                            },
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Complete',
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
                      ],
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

  Widget _detailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // KPI Cards
          Container(
            padding: const EdgeInsets.all(8),
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
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              padding: EdgeInsets.zero,
              children: [
                _metricCard(
                  'Total Reviews',
                  '${_metrics['totalReviews']}',
                  Icons.receipt_long_rounded,
                  kPrimary,
                ),
                _metricCard(
                  'Completed',
                  '${_metrics['completed']}',
                  Icons.check_circle_rounded,
                  kSuccess,
                ),
                _metricCard(
                  'Pending',
                  '${_metrics['pending']}',
                  Icons.pending_actions_rounded,
                  kWarning,
                ),
                _metricCard(
                  'Draft',
                  '${_metrics['draft']}',
                  Icons.edit_rounded,
                  Colors.blue,
                ),
                _metricCard(
                  'Avg Rating',
                  '${_metrics['averageRating']}',
                  Icons.star_rounded,
                  Colors.amber,
                ),
                _metricCard(
                  'High Performers',
                  '${_metrics['highPerformers']}',
                  Icons.emoji_events_rounded,
                  Colors.purple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Performance Distribution
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
                  'Performance Distribution',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 12),
                _distributionBar('High Performers', _metrics['highPerformers'],
                    8, Colors.purple),
                _distributionBar('On Track', _metrics['onTrack'], 8,
                    Colors.green),
                _distributionBar('Needs Improvement',
                    _metrics['needsImprovement'], 8, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Rating Trends (Simplified)
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
                  'Rating Trends',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _trendItem('Q1 2026', 3.8),
                    _trendItem('Q2 2026', 4.1),
                    _trendItem('Q3 2026', 4.2),
                    _trendItem('Q4 2026', 4.0),
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

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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
    );
  }

  Widget _distributionBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? (value / total) : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: kText,
                ),
              ),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage as double?,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendItem(String label, double value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: kBgLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _getRatingColor(value),
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
  // GOALS VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildGoalsView() {
    // Extract all goals from reviews
    final allGoals = <Map<String, dynamic>>[];
    for (var review in _reviews) {
      if (review['goals'] != null) {
        for (var goal in review['goals'] as List) {
          allGoals.add({
            'goal': goal,
            'employee': review['employeeName'],
            'department': review['department'],
            'status': review['status'],
          });
        }
      }
    }

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
                 Text(
                  'Active Goals',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${allGoals.length} goals from ${_reviews.where((r) => r['goals'] != null && (r['goals'] as List).isNotEmpty).length} employees',
                  style: TextStyle(
                    fontSize: 11,
                    color: kSubText,
                  ),
                ),
                const SizedBox(height: 12),
                ...allGoals.map((goal) {
                  return Container(
                    padding: const EdgeInsets.all(10),
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
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            size: 16,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                goal['goal'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              Text(
                                '${goal['employee']} • ${goal['department']}',
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
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: goal['status'] == 'Completed'
                                ? kSuccess.withValues(alpha: 0.08)
                                : kWarning.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: goal['status'] == 'Completed'
                                  ? kSuccess.withValues(alpha: 0.1)
                                  : kWarning.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            goal['status'] == 'Completed'
                                ? '✓ Done'
                                : 'In Progress',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: goal['status'] == 'Completed'
                                  ? kSuccess
                                  : kWarning,
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE REVIEW DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showCreateReviewDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String selectedEmployee = '';
    String selectedPeriod = 'Q4 2026';
    String selectedReviewer = '';

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
                maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                            Icons.receipt_long_rounded,
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
                                'Create Review',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Start a new performance review',
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
                            _buildDropdownField(
                              label: 'Employee *',
                              value: selectedEmployee.isEmpty
                                  ? null
                                  : selectedEmployee,
                              hint: 'Select employee',
                              items: ['Ahmed Khan', 'Sara Ali', 'Usman Raza'],
                              onChanged: (v) =>
                                  setState(() => selectedEmployee = v!),
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Review Period *',
                              value: selectedPeriod,
                              hint: 'Select period',
                              items: ['Q1 2026', 'Q2 2026', 'Q3 2026', 'Q4 2026'],
                              onChanged: (v) =>
                                  setState(() => selectedPeriod = v!),
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Reviewer *',
                              value: selectedReviewer.isEmpty
                                  ? null
                                  : selectedReviewer,
                              hint: 'Select reviewer',
                              items: ['Fatima Noor', 'Bilal Sheikh', 'Ali Raza'],
                              onChanged: (v) =>
                                  setState(() => selectedReviewer = v!),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
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
                                      'The review will be created as a draft. You can complete it later.',
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
                                    content: Text('✅ Review created as draft!'),
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
                              'Create Review',
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
  // REVIEW DETAIL DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showReviewDetail(Map<String, dynamic> review, BuildContext context) {
    final status = review['status'] as String;
    final statusData = _getStatusData(status);
    final isCompleted = status == 'Completed';
    final overallRating = review['overallRating'] as double?;

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
                              color: statusData['color'].withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isCompleted
                                  ? Icons.verified_rounded
                                  : Icons.pending_actions_rounded,
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
                                  review['employeeName'] as String,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${review['designation']} • ${review['department']}',
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
                            child: Text(
                              statusData['label'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusData['color'],
                              ),
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
                      _detailRow('Review ID', review['id']),
                      _detailRow('Period', review['period']),
                      _detailRow('Reviewer', review['reviewer']),
                      _detailRow('Date', DateFormat('dd MMM yyyy').format(review['date'])),
                      _detailRow('Next Review',
                          DateFormat('dd MMM yyyy').format(review['nextReviewDate'])),
                      if (isCompleted && overallRating != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getRatingColor(overallRating).withValues(alpha: 0.08),
                                _getRatingColor(overallRating).withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getRatingColor(overallRating).withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Overall Rating: ${overallRating.toStringAsFixed(1)} / 5.0',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _getRatingColor(overallRating),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isCompleted) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Ratings',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
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
                            children: (review['ratings'] as Map<String, dynamic>)
                                .entries
                                .map((entry) {
                              final label = _getRatingLabel(entry.key);
                              final value = entry.value as double;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: kText,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          value.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _getRatingColor(value),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: LinearProgressIndicator(
                                        value: value / 5,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getRatingColor(value),
                                        ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Strengths
                        Text(
                          'Strengths',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(review['strengths'] as List).map((strength) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: kSuccess.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: kSuccess.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 12,
                                  color: kSuccess,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  strength,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        // Areas for Improvement
                        Text(
                          'Areas for Improvement',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(review['areasForImprovement'] as List).map((area) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: kWarning.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: kWarning.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  size: 12,
                                  color: kWarning,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  area,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        // Comments
                        if (review['comments'] != null &&
                            review['comments'].toString().isNotEmpty) ...[
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
                                  'Comments',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: kSubText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  review['comments'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kText,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Goals
                        Text(
                          'Goals',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(review['goals'] as List).map((goal) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: kPrimary.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: kPrimary.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  size: 12,
                                  color: kPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  goal,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      // Action Buttons
                      if (status == 'Draft') ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✏️ Review sent for completion!'),
                                      backgroundColor: kSuccess,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text('Continue Review'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (status == 'Pending') ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Cancel'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleCompleteReview(review);
                                },
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('Complete Review'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kSuccess,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: kSubText.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No reviews found',
            style: TextStyle(
              fontSize: 14,
              color: kSubText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new review to get started',
            style: TextStyle(
              fontSize: 12,
              color: kSubText,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _getFilteredReviews() {
    var filtered = List<Map<String, dynamic>>.from(_reviews);

    if (_selectedFilter != 'All') {
      filtered = filtered.where((r) => r['status'] == _selectedFilter).toList();
    }

    if (_selectedPeriod != 'All') {
      filtered = filtered.where((r) => r['period'] == _selectedPeriod).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b['date'].compareTo(a['date']));

    return filtered;
  }

  Map<String, dynamic> _getStatusData(String status) {
    switch (status) {
      case 'Completed':
        return {
          'label': 'COMPLETED',
          'color': kSuccess,
        };
      case 'Pending':
        return {
          'label': 'PENDING',
          'color': kWarning,
        };
      case 'Draft':
        return {
          'label': 'DRAFT',
          'color': Colors.blue,
        };
      case 'Scheduled':
        return {
          'label': 'SCHEDULED',
          'color': Colors.purple,
        };
      default:
        return {
          'label': 'UNKNOWN',
          'color': Colors.grey,
        };
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return kSuccess;
      case 'Pending':
        return kWarning;
      case 'Draft':
        return Colors.blue;
      case 'Scheduled':
        return Colors.purple;
      default:
        return kSubText;
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.amber;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  String _getRatingLabel(String key) {
    switch (key) {
      case 'technicalSkills':
        return 'Technical Skills';
      case 'communication':
        return 'Communication';
      case 'teamwork':
        return 'Teamwork';
      case 'problemSolving':
        return 'Problem Solving';
      case 'leadership':
        return 'Leadership';
      case 'punctuality':
        return 'Punctuality';
      case 'salesPerformance':
        return 'Sales Performance';
      case 'clientRelations':
        return 'Client Relations';
      case 'accuracy':
        return 'Accuracy';
      default:
        return key;
    }
  }

  void _handleCompleteReview(Map<String, dynamic> review) {
    setState(() {
      review['status'] = 'Completed';
      review['overallRating'] = 4.2;
      review['ratings'] = {
        'technicalSkills': 4.0,
        'communication': 4.0,
        'teamwork': 4.5,
        'problemSolving': 4.0,
        'leadership': 4.0,
        'punctuality': 4.5,
      };
      review['strengths'] = ['Good performance', 'Team player'];
      review['areasForImprovement'] = ['Communication'];
      review['comments'] = 'Good performance this quarter. Keep it up!';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Review completed successfully!'),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExportOptions() {
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
              'Export Performance Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 16),
            _exportOption(
              Icons.picture_as_pdf_rounded,
              'Export as PDF',
              'Download performance report as PDF',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📄 Performance report exported as PDF!'),
                    backgroundColor: kSuccess,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _exportOption(
              Icons.table_chart_rounded,
              'Export as Excel',
              'Download performance data as Excel',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📊 Performance data exported as Excel!'),
                    backgroundColor: kSuccess,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(IconData icon, String title, String subtitle,
      VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kPrimary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: kText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          color: kSubText,
        ),
      ),
      onTap: onTap,
    );
  }
}