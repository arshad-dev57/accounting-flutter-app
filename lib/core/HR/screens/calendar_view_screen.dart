// screens/calendar_view_screen.dart - CALENDAR VIEW

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  String _selectedView = 'Month'; // Month | Week | Day
  String _selectedFilter = 'All'; // All | Attendance | Leave | Holiday | Event
  late TabController _tabController;

  // Calendar Events
  final List<Map<String, dynamic>> _events = [
    {
      'id': 'E-001',
      'title': 'Attendance - Check In',
      'date': DateTime(2026, 9, 4),
      'time': '09:03 AM',
      'type': 'Attendance',
      'color': kSuccess,
      'icon': Icons.fingerprint_rounded,
      'description': 'Auto check-in at Head Office via geofence',
      'status': 'Completed',
    },
    {
      'id': 'E-002',
      'title': 'Leave - Casual Leave',
      'date': DateTime(2026, 9, 10),
      'time': '09:00 AM',
      'type': 'Leave',
      'color': Colors.blue,
      'icon': Icons.beach_access_rounded,
      'description': 'Casual leave approved',
      'status': 'Approved',
    },
    {
      'id': 'E-003',
      'title': 'Holiday - Independence Day',
      'date': DateTime(2026, 8, 14),
      'time': '12:00 AM',
      'type': 'Holiday',
      'color': Colors.green,
      'icon': Icons.celebration_rounded,
      'description': 'National holiday - Office closed',
      'status': 'Holiday',
    },
    {
      'id': 'E-004',
      'title': 'Meeting - Quarterly Review',
      'date': DateTime(2026, 9, 20),
      'time': '02:00 PM',
      'type': 'Event',
      'color': Colors.purple,
      'icon': Icons.meeting_room_rounded,
      'description': 'Quarterly performance review meeting',
      'status': 'Upcoming',
    },
    {
      'id': 'E-005',
      'title': 'Attendance - Late Check In',
      'date': DateTime(2026, 9, 2),
      'time': '09:25 AM',
      'type': 'Attendance',
      'color': kWarning,
      'icon': Icons.warning_rounded,
      'description': 'Late check-in by 25 minutes',
      'status': 'Late',
    },
    {
      'id': 'E-006',
      'title': 'Holiday - Eid-ul-Adha',
      'date': DateTime(2026, 8, 29),
      'time': '12:00 AM',
      'type': 'Holiday',
      'color': Colors.purple,
      'icon': Icons.celebration_rounded,
      'description': 'Religious holiday - Office closed',
      'status': 'Holiday',
    },
    {
      'id': 'E-007',
      'title': 'Overtime - Client Meeting',
      'date': DateTime(2026, 9, 15),
      'time': '06:00 PM',
      'type': 'Overtime',
      'color': Colors.orange,
      'icon': Icons.access_time_rounded,
      'description': 'Overtime approved for client meeting',
      'status': 'Approved',
    },
    {
      'id': 'E-008',
      'title': 'Payroll - Salary Disbursed',
      'date': DateTime(2026, 9, 1),
      'time': '09:00 AM',
      'type': 'Payroll',
      'color': kSuccess,
      'icon': Icons.attach_money_rounded,
      'description': 'Monthly salary disbursed',
      'status': 'Completed',
    },
  ];

  // Attendance Days for month view
  final Map<int, Map<String, dynamic>> _attendanceDays = {
    1: {'status': 'Present', 'color': kSuccess},
    2: {'status': 'Late', 'color': kWarning},
    3: {'status': 'Present', 'color': kSuccess},
    4: {'status': 'Present', 'color': kSuccess},
    5: {'status': 'Weekly Off', 'color': Colors.orange},
    6: {'status': 'Weekly Off', 'color': Colors.orange},
    7: {'status': 'Present', 'color': kSuccess},
    8: {'status': 'Leave', 'color': Colors.blue},
    9: {'status': 'Present', 'color': kSuccess},
    10: {'status': 'Present', 'color': kSuccess},
    11: {'status': 'Holiday', 'color': Colors.green},
    12: {'status': 'Present', 'color': kSuccess},
    13: {'status': 'Present', 'color': kSuccess},
    14: {'status': 'Present', 'color': kSuccess},
    15: {'status': 'Overtime', 'color': Colors.orange},
    16: {'status': 'Present', 'color': kSuccess},
    17: {'status': 'Late', 'color': kWarning},
    18: {'status': 'Present', 'color': kSuccess},
    19: {'status': 'Weekly Off', 'color': Colors.orange},
    20: {'status': 'Weekly Off', 'color': Colors.orange},
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
    final filteredEvents = _getFilteredEvents();

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          _buildViewSelector(),
          _buildMonthNavigator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  _buildMonthView(),
                  _buildWeekView(),
                  _buildDayView(),
                ],
              ),
            ),
          ),
          _buildBottomActionBar(),
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
          onPressed: () => _showAddEventDialog(context),
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
                      'Calendar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_events.length} events • ${DateFormat('MMMM yyyy').format(_currentMonth)}',
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
                  setState(() {
                    _currentMonth = DateTime.now();
                    _selectedDate = DateTime.now();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
  // VIEW SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildViewSelector() {
    final views = ['Month', 'Week', 'Day'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: views.map((view) {
          final isSelected = _selectedView == view;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedView = view;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary.withValues(alpha: 0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? kPrimary : Colors.grey.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  view,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? kPrimary : kSubText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTH NAVIGATOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMonthNavigator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                  1,
                );
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kBgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child:  Icon(Icons.chevron_left, size: 20, color: kSubText),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormat('MMMM yyyy').format(_currentMonth),
              style:  TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                  1,
                );
              });
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kBgLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child:  Icon(Icons.chevron_right, size: 20, color: kSubText),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // MONTH VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildMonthView() {
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Weekday Headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((day) => Expanded(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: kSubText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Calendar Grid
          Container(
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
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: firstDayOfMonth + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstDayOfMonth) {
                  return const SizedBox.shrink();
                }
                final day = index - firstDayOfMonth + 1;
                final date = DateTime(_currentMonth.year, _currentMonth.month, day);
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                final attendance = _attendanceDays[day];
                final dayEvents = _events.where((e) =>
                    e['date'].year == date.year &&
                    e['date'].month == date.month &&
                    e['date'].day == date.day);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                    _showDayEvents(date);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPrimary.withValues(alpha: 0.08)
                          : (isToday
                              ? kPrimary.withValues(alpha: 0.04)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: kPrimary.withValues(alpha: 0.3),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isToday ? kPrimary : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isToday
                                    ? Colors.white
                                    : (attendance != null &&
                                            attendance['color'] == kWarning
                                        ? kWarning
                                        : kText),
                              ),
                            ),
                          ),
                        ),
                        if (attendance != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: attendance['color'],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                        if (dayEvents.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 8,
                            height: 2,
                            decoration: BoxDecoration(
                              color: kPrimary,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _legendItem('Present', kSuccess),
                _legendItem('Late', kWarning),
                _legendItem('Absent', kDanger),
                _legendItem('Leave', Colors.blue),
                _legendItem('Holiday', Colors.green),
                _legendItem('Weekly Off', Colors.orange),
                _legendItem('Overtime', Colors.purple),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: kSubText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // WEEK VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildWeekView() {
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final dayEvents = _events.where((e) =>
              e['date'].year == date.year &&
              e['date'].month == date.month &&
              e['date'].day == date.day);
          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isToday
                  ? kPrimary.withValues(alpha: 0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday
                    ? kPrimary.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.05),
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isToday ? kPrimary : kSubText,
                        ),
                      ),
                      Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isToday ? kPrimary : kText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: dayEvents.isEmpty
                      ? Text(
                          'No events',
                          style: TextStyle(
                            fontSize: 11,
                            color: kSubText,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : Column(
                          children: dayEvents.map((event) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: event['color'].withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: event['color'].withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    event['icon'],
                                    size: 12,
                                    color: event['color'],
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      event['title'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: kText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    event['time'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: kSubText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DAY VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDayView() {
    final dayEvents = _events.where((e) =>
        e['date'].year == _selectedDate.year &&
        e['date'].month == _selectedDate.month &&
        e['date'].day == _selectedDate.day);

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
              children: [
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                  style:  TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dayEvents.isEmpty
                        ? 'No events today'
                        : '${dayEvents.length} events today',
                    style: TextStyle(
                      fontSize: 12,
                      color: kSubText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...dayEvents.map((event) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: event['color'].withValues(alpha: 0.15),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: event['color'].withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      event['icon'],
                      size: 20,
                      color: event['color'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${event['time']} • ${event['status']}',
                          style: TextStyle(
                            fontSize: 10,
                            color: kSubText,
                          ),
                        ),
                        if (event['description'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            event['description'],
                            style: TextStyle(
                              fontSize: 10,
                              color: kSubText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: event['color'].withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event['type'],
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: event['color'],
                      ),
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
  // BOTTOM ACTION BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBottomActionBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomActionItem(
                Icons.filter_list_rounded,
                'Filter',
                _selectedFilter,
                () => _showFilterMenu(),
              ),
              _bottomActionItem(
                Icons.calendar_today_rounded,
                'Today',
                '',
                () {
                  setState(() {
                    _selectedDate = DateTime.now();
                    _currentMonth = DateTime.now();
                  });
                },
              ),
              _bottomActionItem(
                Icons.search_rounded,
                'Search',
                '',
                () => _showSearchDialog(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomActionItem(IconData icon, String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: kPrimary),
              if (value.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                    ),
                  ),
                ),
              ],
            ],
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
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════

  void _showFilterMenu() {
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
              'Filter Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 16),
            ...['All', 'Attendance', 'Leave', 'Holiday', 'Event', 'Overtime', 'Payroll']
                .map((filter) {
              final isSelected = _selectedFilter == filter;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                    size: 18,
                    color: isSelected ? kPrimary : kSubText,
                  ),
                ),
                title: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? kPrimary : kText,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Search Events'),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Search by title or type...',
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onChanged: (value) {
            // Search logic
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kSubText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('dd MMM yyyy').format(_selectedDate),
    );
    final timeController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = _selectedDate;
    String selectedType = 'Event';

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
                            Icons.event_rounded,
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
                                'Add Event',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a new calendar event',
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
                              label: 'Event Title *',
                              hint: 'Enter event title',
                              icon: Icons.title_rounded,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter title' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildDatePickerField(
                              label: 'Date *',
                              date: selectedDate,
                              controller: dateController,
                              onChanged: (date) {
                                setState(() {
                                  selectedDate = date;
                                  dateController.text =
                                      DateFormat('dd MMM yyyy').format(date);
                                });
                              },
                              context: context,
                            ),
                            const SizedBox(height: 16),
                            _buildTimePickerField(
                              label: 'Time',
                              controller: timeController,
                              hint: 'Select time',
                            ),
                            const SizedBox(height: 16),
                            _buildDropdownField(
                              label: 'Event Type *',
                              value: selectedType,
                              items: const ['Event', 'Attendance', 'Leave', 'Holiday', 'Overtime'],
                              onChanged: (v) => setState(() => selectedType = v!),
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: descriptionController,
                              label: 'Description',
                              hint: 'Enter event description',
                              icon: Icons.description_outlined,
                              maxLines: 3,
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
                                    content: Text('✅ Event added successfully!'),
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
                              'Add Event',
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

  void _showDayEvents(DateTime date) {
    final dayEvents = _events.where((e) =>
        e['date'].year == date.year &&
        e['date'].month == date.month &&
        e['date'].day == date.day);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.6,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  DateFormat('EEEE, dd MMM yyyy').format(date),
                  style:  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ),
              Expanded(
                child: dayEvents.isEmpty
                    ? Center(
                        child: Text(
                          'No events on this day',
                          style: TextStyle(
                            fontSize: 13,
                            color: kSubText,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: dayEvents.length,
                        itemBuilder: (context, index) {
                          final event = dayEvents.toList()[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: event['color'].withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: event['color'].withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(event['icon'], size: 16, color: event['color']),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['title'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: kText,
                                        ),
                                      ),
                                      Text(
                                        '${event['time']} • ${event['type']}',
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
                                    color: event['color'].withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    event['status'],
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: event['color'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
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
      validator: (value) => value == null ? 'Please select type' : null,
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

  Widget _buildTimePickerField({
    required String label,
    required TextEditingController controller,
    required String hint,
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
          prefixIcon: const Icon(Icons.access_time, size: 18),
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
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Please select time' : null,
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    var filtered = List<Map<String, dynamic>>.from(_events);

    if (_selectedFilter != 'All') {
      filtered = filtered.where((e) => e['type'] == _selectedFilter).toList();
    }

    return filtered;
  }
}