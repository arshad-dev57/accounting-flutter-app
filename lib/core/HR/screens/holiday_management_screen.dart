// screens/holiday_management_screen.dart - HOLIDAY MANAGEMENT

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HolidayManagementScreen extends StatefulWidget {
  const HolidayManagementScreen({super.key});

  @override
  State<HolidayManagementScreen> createState() =>
      _HolidayManagementScreenState();
}

class _HolidayManagementScreenState extends State<HolidayManagementScreen> {
  String _selectedFilter = 'All';
  String _selectedYear = DateFormat('yyyy').format(DateTime.now());

  // Sample holiday data
  final List<Map<String, dynamic>> _holidays = [
    {
      'id': 'HOL-001',
      'name': 'Pakistan Day',
      'date': DateTime(2026, 3, 23),
      'type': 'National',
      'description': 'Pakistan Day - 23rd March',
      'recurring': true,
      'status': 'Upcoming',
    },
    {
      'id': 'HOL-002',
      'name': 'Eid-ul-Fitr',
      'date': DateTime(2026, 4, 10),
      'type': 'Religious',
      'description': 'Eid-ul-Fitr holidays',
      'recurring': false,
      'status': 'Upcoming',
    },
    {
      'id': 'HOL-003',
      'name': 'Labour Day',
      'date': DateTime(2026, 5, 1),
      'type': 'National',
      'description': 'International Labour Day',
      'recurring': true,
      'status': 'Upcoming',
    },
    {
      'id': 'HOL-004',
      'name': 'Eid-ul-Adha',
      'date': DateTime(2026, 6, 17),
      'type': 'Religious',
      'description': 'Eid-ul-Adha holidays',
      'recurring': false,
      'status': 'Upcoming',
    },
    {
      'id': 'HOL-005',
      'name': 'Independence Day',
      'date': DateTime(2026, 8, 14),
      'type': 'National',
      'description': '14th August - Independence Day',
      'recurring': true,
      'status': 'Upcoming',
    },
    {
      'id': 'HOL-006',
      'name': 'Ashura',
      'date': DateTime(2026, 8, 29),
      'type': 'Religious',
      'description': 'Ashura holidays',
      'recurring': false,
      'status': 'Upcoming',
    },
    {
      'id': 'HOL-007',
      'name': 'Iqbal Day',
      'date': DateTime(2026, 11, 9),
      'type': 'National',
      'description': 'Allama Iqbal Day',
      'recurring': true,
      'status': 'Upcoming',
    },
    {
      'id': 'HOL-008',
      'name': 'Quaid-e-Azam Day',
      'date': DateTime(2026, 12, 25),
      'type': 'National',
      'description': 'Quaid-e-Azam Day - 25th December',
      'recurring': true,
      'status': 'Upcoming',
    },
    {
      'id': 'HOL-009',
      'name': 'Christmas Day',
      'date': DateTime(2026, 12, 25),
      'type': 'Religious',
      'description': 'Christmas Day',
      'recurring': true,
      'status': 'Upcoming',
    },
    {
      'id': 'HOL-010',
      'name': 'New Year Day',
      'date': DateTime(2027, 1, 1),
      'type': 'National',
      'description': 'New Year Day',
      'recurring': true,
      'status': 'Upcoming',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredHolidays = _getFilteredHolidays();

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
                  _buildYearSelector(),
                  const SizedBox(height: 8),
                  _buildFilterChips(),
                  const SizedBox(height: 8),
                  Expanded(child: _buildHolidayList(filteredHolidays)),
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
          onPressed: () => _showAddHolidayDialog(context),
          backgroundColor: kPrimary,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final totalHolidays = _holidays.length;

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
                      'Holidays',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '$totalHolidays holidays • $_selectedYear',
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
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // YEAR SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildYearSelector() {
    final currentYear = int.parse(DateFormat('yyyy').format(DateTime.now()));
    final years = List.generate(3, (index) => (currentYear + index - 1).toString());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final currentIdx = years.indexOf(_selectedYear);
              if (currentIdx > 0) {
                setState(() {
                  _selectedYear = years[currentIdx - 1];
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:  Icon(Icons.chevron_left, size: 18, color: kSubText),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _selectedYear,
                  style:  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              final currentIdx = years.indexOf(_selectedYear);
              if (currentIdx < years.length - 1) {
                setState(() {
                  _selectedYear = years[currentIdx + 1];
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:  Icon(Icons.chevron_right, size: 18, color: kSubText),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildFilterChips() {
    final filters = ['All', 'National', 'Religious', 'Company'];

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
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kPrimary.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
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
  // HOLIDAY LIST
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHolidayList(List<Map<String, dynamic>> holidays) {
    if (holidays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 64,
              color: kSubText.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No holidays found',
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

    // Sort by date
    final sortedHolidays = List<Map<String, dynamic>>.from(holidays)
      ..sort((a, b) => a['date'].compareTo(b['date']));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: sortedHolidays.length,
      itemBuilder: (context, index) {
        final holiday = sortedHolidays[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildHolidayCard(holiday, context),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HOLIDAY CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHolidayCard(Map<String, dynamic> holiday, BuildContext context) {
    final type = holiday['type'] as String;
    final typeColor = _getTypeColor(type);
    final date = holiday['date'] as DateTime;
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final daysUntil = date.difference(DateTime.now()).inDays;

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
          color: isPast
              ? Colors.grey.withValues(alpha: 0.1)
              : typeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showHolidayDetails(holiday, context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Date Badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isPast
                            ? Colors.grey.withValues(alpha: 0.1)
                            : typeColor.withValues(alpha: 0.15),
                        isPast
                            ? Colors.grey.withValues(alpha: 0.05)
                            : typeColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPast
                          ? Colors.grey.withValues(alpha: 0.15)
                          : typeColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isPast ? kSubText : typeColor,
                          height: 1,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(date),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isPast ? kSubText : typeColor,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Holiday Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              holiday['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isPast ? kSubText : kText,
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
                              color: typeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: typeColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: typeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isPast ? kSubText : kSubText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (holiday['recurring'] == true) ...[
                            Icon(
                              Icons.repeat_rounded,
                              size: 12,
                              color: kPrimary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Yearly',
                              style: TextStyle(
                                fontSize: 9,
                                color: kPrimary.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (!isPast) ...[
                            Icon(
                              Icons.timer_rounded,
                              size: 12,
                              color: daysUntil <= 7 ? kDanger : kSubText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              daysUntil == 0
                                  ? 'Today! 🎉'
                                  : daysUntil <= 7
                                      ? '$daysUntil days left'
                                      : '$daysUntil days',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: daysUntil <= 7 ? kDanger : kSubText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Day of week
                Column(
                  children: [
                    Text(
                      DateFormat('E').format(date),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isPast ? kSubText : kPrimary,
                      ),
                    ),
                    if (isPast) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Past',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: kSubText,
                          ),
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
  // ADD HOLIDAY DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showAddHolidayDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dateController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'National';
    bool isRecurring = false;

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
                            Icons.calendar_month_rounded,
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
                                'Add Holiday',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: kText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create a new company holiday',
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
                              label: 'Holiday Name *',
                              hint: 'e.g., Independence Day',
                              icon: Icons.event_rounded,
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Please enter holiday name' : null,
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
                            _buildDropdownField(
                              label: 'Holiday Type *',
                              value: selectedType,
                              items: const [
                                'National',
                                'Religious',
                                'Company',
                              ],
                              onChanged: (v) => setState(() => selectedType = v!),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: isRecurring,
                                  onChanged: (v) => setState(() {
                                    isRecurring = v ?? false;
                                  }),
                                  activeColor: kPrimary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Recurring yearly',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: kText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              controller: descriptionController,
                              label: 'Description',
                              hint: 'Enter holiday description (optional)',
                              icon: Icons.description_outlined,
                              maxLines: 2,
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
                                    content: Text('Holiday added successfully!'),
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
                              'Add Holiday',
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
  // HOLIDAY DETAIL DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showHolidayDetails(Map<String, dynamic> holiday, BuildContext context) {
    final type = holiday['type'] as String;
    final typeColor = _getTypeColor(type);
    final date = holiday['date'] as DateTime;
    final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.75,
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
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.calendar_month_rounded,
                              size: 26,
                              color: typeColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  holiday['name'] as String,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE, dd MMM yyyy').format(date),
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
                              color: typeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: typeColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: typeColor,
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
                      _detailRow('Holiday ID', holiday['id']),
                      _detailRow('Date', DateFormat('dd MMM yyyy').format(date)),
                      _detailRow('Day', DateFormat('EEEE').format(date)),
                      _detailRow('Type', type),
                      _detailRow(
                        'Recurring',
                        holiday['recurring'] == true ? 'Yes (Yearly)' : 'No',
                        valueColor: holiday['recurring'] == true
                            ? kPrimary
                            : kSubText,
                      ),
                      if (holiday['description'] != null &&
                          holiday['description'].toString().isNotEmpty) ...[
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
                                'Description',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: kSubText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                holiday['description'] as String,
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
                      ],
                      const SizedBox(height: 16),
                      if (!isPast) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kSuccess.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: kSuccess.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.celebration_rounded,
                                size: 16,
                                color: kSuccess,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This holiday is upcoming. Employees will be marked as HOLIDAY in attendance.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: kSubText,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
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

  List<Map<String, dynamic>> _getFilteredHolidays() {
    var filtered = _holidays;

    // Filter by year
    filtered = filtered
        .where((h) => DateFormat('yyyy').format(h['date']) == _selectedYear)
        .toList();

    // Filter by type
    if (_selectedFilter != 'All') {
      filtered = filtered
          .where((h) => h['type'] == _selectedFilter)
          .toList();
    }

    return filtered;
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'National':
        return Colors.green;
      case 'Religious':
        return Colors.purple;
      case 'Company':
        return Colors.blue;
      default:
        return kPrimary;
    }
  }
}