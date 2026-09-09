// screens/organization_chart_screen.dart - ORGANIZATION CHART

import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:flutter/material.dart';

class OrganizationChartScreen extends StatefulWidget {
  const OrganizationChartScreen({super.key});

  @override
  State<OrganizationChartScreen> createState() =>
      _OrganizationChartScreenState();
}

class _OrganizationChartScreenState extends State<OrganizationChartScreen>
    with SingleTickerProviderStateMixin {
  String _selectedDepartment = 'All';
  String _selectedView = 'Hierarchy';
  String _selectedEmployee = '';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Organization Data
  final Map<String, dynamic> _orgData = {
    'company': 'BisonsTechs Pvt Ltd',
    'totalEmployees': 125,
    'departments': 8,
    'levels': 5,
    'ceo': {
      'id': 'EMP-000',
      'name': 'Muhammad Ali',
      'designation': 'CEO',
      'department': 'Executive',
      'email': 'ceo@bisonstechs.com',
      'phone': '+92 300 0000000',
      'avatar': null,
      'reportsTo': null,
      'directReports': ['EMP-001', 'EMP-002', 'EMP-003'],
    },
    'executives': [
      {
        'id': 'EMP-001',
        'name': 'Ahmed Khan',
        'designation': 'CTO',
        'department': 'Executive',
        'email': 'ahmed.khan@bisonstechs.com',
        'phone': '+92 300 1111111',
        'avatar': null,
        'reportsTo': 'EMP-000',
        'directReports': ['EMP-004', 'EMP-005', 'EMP-006'],
      },
      {
        'id': 'EMP-002',
        'name': 'Sara Ali',
        'designation': 'CFO',
        'department': 'Executive',
        'email': 'sara.ali@bisonstechs.com',
        'phone': '+92 300 2222222',
        'avatar': null,
        'reportsTo': 'EMP-000',
        'directReports': ['EMP-007', 'EMP-008'],
      },
      {
        'id': 'EMP-003',
        'name': 'Usman Raza',
        'designation': 'COO',
        'department': 'Executive',
        'email': 'usman.raza@bisonstechs.com',
        'phone': '+92 300 3333333',
        'avatar': null,
        'reportsTo': 'EMP-000',
        'directReports': ['EMP-009', 'EMP-010'],
      },
    ],
    'departments': [
      {
        'id': 'DEPT-001',
        'name': 'Engineering',
        'head': 'EMP-004',
        'headName': 'Fatima Noor',
        'headDesignation': 'VP Engineering',
        'employeeCount': 32,
        'employees': [
          {
            'id': 'EMP-004',
            'name': 'Fatima Noor',
            'designation': 'VP Engineering',
            'avatar': null,
            'reportsTo': 'EMP-001',
          },
          {
            'id': 'EMP-005',
            'name': 'Bilal Sheikh',
            'designation': 'Lead Software Engineer',
            'avatar': null,
            'reportsTo': 'EMP-004',
          },
          {
            'id': 'EMP-006',
            'name': 'Nadia Khan',
            'designation': 'Senior Software Engineer',
            'avatar': null,
            'reportsTo': 'EMP-005',
          },
          {
            'id': 'EMP-011',
            'name': 'Hamza Ali',
            'designation': 'Software Engineer',
            'avatar': null,
            'reportsTo': 'EMP-006',
          },
          {
            'id': 'EMP-012',
            'name': 'Ayesha Malik',
            'designation': 'Software Engineer',
            'avatar': null,
            'reportsTo': 'EMP-006',
          },
          {
            'id': 'EMP-013',
            'name': 'Zain Ahmed',
            'designation': 'Junior Developer',
            'avatar': null,
            'reportsTo': 'EMP-011',
          },
        ],
      },
      {
        'id': 'DEPT-002',
        'name': 'Sales',
        'head': 'EMP-009',
        'headName': 'Ali Raza',
        'headDesignation': 'VP Sales',
        'employeeCount': 45,
        'employees': [
          {
            'id': 'EMP-009',
            'name': 'Ali Raza',
            'designation': 'VP Sales',
            'avatar': null,
            'reportsTo': 'EMP-003',
          },
          {
            'id': 'EMP-014',
            'name': 'Usman Sheikh',
            'designation': 'Sales Manager',
            'avatar': null,
            'reportsTo': 'EMP-009',
          },
          {
            'id': 'EMP-015',
            'name': 'Rabia Khan',
            'designation': 'Senior Sales Executive',
            'avatar': null,
            'reportsTo': 'EMP-014',
          },
          {
            'id': 'EMP-016',
            'name': 'Omar Farooq',
            'designation': 'Sales Executive',
            'avatar': null,
            'reportsTo': 'EMP-015',
          },
        ],
      },
      {
        'id': 'DEPT-003',
        'name': 'Finance',
        'head': 'EMP-007',
        'headName': 'Sana Malik',
        'headDesignation': 'VP Finance',
        'employeeCount': 15,
        'employees': [
          {
            'id': 'EMP-007',
            'name': 'Sana Malik',
            'designation': 'VP Finance',
            'avatar': null,
            'reportsTo': 'EMP-002',
          },
          {
            'id': 'EMP-017',
            'name': 'Kamran Ali',
            'designation': 'Finance Manager',
            'avatar': null,
            'reportsTo': 'EMP-007',
          },
          {
            'id': 'EMP-018',
            'name': 'Hira Noor',
            'designation': 'Accountant',
            'avatar': null,
            'reportsTo': 'EMP-017',
          },
        ],
      },
      {
        'id': 'DEPT-004',
        'name': 'Human Resources',
        'head': 'EMP-008',
        'headName': 'Fatima Khan',
        'headDesignation': 'VP HR',
        'employeeCount': 18,
        'employees': [
          {
            'id': 'EMP-008',
            'name': 'Fatima Khan',
            'designation': 'VP HR',
            'avatar': null,
            'reportsTo': 'EMP-002',
          },
          {
            'id': 'EMP-019',
            'name': 'Nida Ali',
            'designation': 'HR Manager',
            'avatar': null,
            'reportsTo': 'EMP-008',
          },
          {
            'id': 'EMP-020',
            'name': 'Sohail Ahmed',
            'designation': 'HR Executive',
            'avatar': null,
            'reportsTo': 'EMP-019',
          },
        ],
      },
      {
        'id': 'DEPT-005',
        'name': 'Marketing',
        'head': 'EMP-010',
        'headName': 'Ayesha Noor',
        'headDesignation': 'VP Marketing',
        'employeeCount': 10,
        'employees': [
          {
            'id': 'EMP-010',
            'name': 'Ayesha Noor',
            'designation': 'VP Marketing',
            'avatar': null,
            'reportsTo': 'EMP-003',
          },
          {
            'id': 'EMP-021',
            'name': 'Danish Khan',
            'designation': 'Marketing Manager',
            'avatar': null,
            'reportsTo': 'EMP-010',
          },
          {
            'id': 'EMP-022',
            'name': 'Sana Sheikh',
            'designation': 'Marketing Executive',
            'avatar': null,
            'reportsTo': 'EMP-021',
          },
        ],
      },
      {
        'id': 'DEPT-006',
        'name': 'Operations',
        'head': 'EMP-009',
        'headName': 'Ali Raza',
        'headDesignation': 'VP Operations',
        'employeeCount': 5,
        'employees': [
          {
            'id': 'EMP-009',
            'name': 'Ali Raza',
            'designation': 'VP Operations',
            'avatar': null,
            'reportsTo': 'EMP-003',
          },
          {
            'id': 'EMP-023',
            'name': 'Imran Ali',
            'designation': 'Operations Manager',
            'avatar': null,
            'reportsTo': 'EMP-009',
          },
        ],
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();

    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildTopHeader(context),
          _buildViewSelector(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                children: [
                  _buildDepartmentFilter(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _selectedView == 'Hierarchy'
                        ? _buildHierarchyView(filteredData)
                        : _buildDepartmentView(filteredData),
                  ),
                ],
              ),
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
                      'Organization Chart',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${_orgData['totalEmployees']} employees • ${_orgData['departments']} departments',
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
                    _animationController.reset();
                    _animationController.forward();
                  });
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
  // VIEW SELECTOR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildViewSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _viewOption('Hierarchy', Icons.account_tree_rounded),
          const SizedBox(width: 8),
          _viewOption('Department', Icons.business_center_rounded),
        ],
      ),
    );
  }

  Widget _viewOption(String label, IconData icon) {
    final isSelected = _selectedView == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = label;
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? kPrimary : kSubText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? kPrimary : kSubText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DEPARTMENT FILTER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDepartmentFilter() {
    final departments = ['All', ..._orgData['departments'].map((d) => d['name'] as String)];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: departments.map((dept) {
          final isSelected = _selectedDepartment == dept;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDepartment = dept;
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
                child: Text(
                  dept,
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
  // HIERARCHY VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHierarchyView(Map<String, dynamic> data) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            // CEO
            _buildOrgNode(
              _orgData['ceo'],
              isRoot: true,
            ),
            const SizedBox(height: 16),
            // Level Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kPrimary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward_rounded, size: 14, color: kPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'Level 1 • Executive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Executives
            ..._buildExecutiveNodes(),
            const SizedBox(height: 12),
            // Department Heads
            ..._buildDepartmentHeadNodes(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ORG NODE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOrgNode(Map<String, dynamic> node, {bool isRoot = false}) {
    final isSelected = _selectedEmployee == node['id'];
    final name = node['name'] as String;
    final designation = node['designation'] as String;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedEmployee = isSelected ? '' : node['id'];
        });
        if (!isSelected) {
          _showEmployeeDetail(node);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isRoot
              ? LinearGradient(
                  colors: [
                    kPrimary.withValues(alpha: 0.12),
                    kPrimary.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? kPrimary.withValues(alpha: 0.08)
              : (isRoot ? Colors.transparent : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? kPrimary
                : (isRoot
                    ? kPrimary.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1)),
            width: isSelected ? 2 : (isRoot ? 1.5 : 1),
          ),
          boxShadow: isRoot
              ? [
                  BoxShadow(
                    color: kPrimary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isRoot ? kPrimary : kPrimary.withValues(alpha: 0.8),
                    isRoot ? kPrimary.withValues(alpha: 0.6) : kPrimary.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _getInitials(name),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isRoot ? kPrimary : kText,
                    ),
                  ),
                  Text(
                    designation,
                    style: TextStyle(
                      fontSize: 11,
                      color: isRoot ? kPrimary.withValues(alpha: 0.7) : kSubText,
                    ),
                  ),
                  if (node['directReports'] != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.people_rounded,
                          size: 12,
                          color: kSubText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(node['directReports'] as List).length} direct reports',
                          style: TextStyle(
                            fontSize: 9,
                            color: kSubText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isRoot)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: kWarning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: kWarning.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  'CEO',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: kWarning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EXECUTIVE NODES
  // ═══════════════════════════════════════════════════════════════

  List<Widget> _buildExecutiveNodes() {
    return _orgData['executives'].map((exec) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // Connecting Line
            Container(
              width: 24,
              height: 1,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _buildOrgNode(exec),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // DEPARTMENT HEAD NODES
  // ═══════════════════════════════════════════════════════════════

  List<Widget> _buildDepartmentHeadNodes() {
    final filteredDepts = _getFilteredDepartments();

    if (filteredDepts.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.1),
            ),
          ),
          child:  Center(
            child: Text(
              'No departments found',
              style: TextStyle(
                fontSize: 13,
                color: kSubText,
              ),
            ),
          ),
        ),
      ];
    }

    return filteredDepts.map((dept) {
      final head = dept['employees'].firstWhere(
        (e) => e['id'] == dept['head'],
        orElse: () => null,
      );

      if (head == null) return const SizedBox.shrink();

      final node = {
        'id': head['id'],
        'name': head['name'],
        'designation': head['designation'],
        'directReports': dept['employees']
            .where((e) => e['id'] != head['id'])
            .map((e) => e['id'])
            .toList(),
      };

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            // Department Label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getDepartmentColor(dept['name']).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getDepartmentColor(dept['name']).withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getDepartmentColor(dept['name']),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dept['name'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _getDepartmentColor(dept['name']),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _getDepartmentColor(dept['name']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${dept['employeeCount']} emp',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: _getDepartmentColor(dept['name']),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 24,
                  height: 1,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildOrgNode(node),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // DEPARTMENT VIEW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDepartmentView(Map<String, dynamic> data) {
    final filteredDepts = _getFilteredDepartments();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: filteredDepts.map((dept) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                  color: _getDepartmentColor(dept['name']).withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Department Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getDepartmentColor(dept['name']).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getDepartmentColor(dept['name']).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Icon(
                          _getDepartmentIcon(dept['name']),
                          size: 20,
                          color: _getDepartmentColor(dept['name']),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dept['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: kText,
                              ),
                            ),
                            Text(
                              '${dept['employeeCount']} employees • Head: ${dept['headName']}',
                              style: TextStyle(
                                fontSize: 11,
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
                          color: _getDepartmentColor(dept['name']).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _getDepartmentColor(dept['name']).withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          dept['headDesignation'] ?? 'Head',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: _getDepartmentColor(dept['name']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: Colors.grey.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 12),
                  // Employees List
                  ...dept['employees'].map((emp) {
                    final isHead = emp['id'] == dept['head'];
                    final isSelected = _selectedEmployee == emp['id'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEmployee = isSelected ? '' : emp['id'];
                        });
                        if (!isSelected) {
                          _showEmployeeDetail(emp);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kPrimary.withValues(alpha: 0.04)
                              : (isHead
                                  ? _getDepartmentColor(dept['name']).withValues(alpha: 0.02)
                                  : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: kPrimary.withValues(alpha: 0.2),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isHead
                                    ? _getDepartmentColor(dept['name']).withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                                border: isHead
                                    ? Border.all(
                                        color: _getDepartmentColor(dept['name']).withValues(alpha: 0.2),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(emp['name']),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isHead
                                        ? _getDepartmentColor(dept['name'])
                                        : kSubText,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        emp['name'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isHead
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isHead ? kPrimary : kText,
                                        ),
                                      ),
                                      if (isHead) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getDepartmentColor(dept['name']).withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Head',
                                            style: TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.w700,
                                              color: _getDepartmentColor(dept['name']),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    emp['designation'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: kSubText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (emp['reportsTo'] != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Reports to ${_getEmployeeName(emp['reportsTo'])}',
                                  style: TextStyle(
                                    fontSize: 7,
                                    color: kSubText,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPLOYEE DETAIL DIALOG
  // ═══════════════════════════════════════════════════════════════

  void _showEmployeeDetail(Map<String, dynamic> employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
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
                            width: 60,
                            height: 60,
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
                                color: kPrimary.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(employee['name']),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee['name'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  employee['designation'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: kSubText,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimary.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'ID: ${employee['id']}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                      if (employee['email'] != null)
                        _detailRow('Email', employee['email']),
                      if (employee['phone'] != null)
                        _detailRow('Phone', employee['phone']),
                      if (employee['department'] != null)
                        _detailRow('Department', employee['department']),
                      if (employee['reportsTo'] != null)
                        _detailRow(
                          'Reports To',
                          _getEmployeeName(employee['reportsTo']),
                        ),
                      if (employee['directReports'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Direct Reports',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kSubText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...(employee['directReports'] as List).map((id) {
                          final name = _getEmployeeName(id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 12,
                                  color: kSubText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kText,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      // Quick Actions
                      Row(
                        children: [
                          _quickActionButton(
                            Icons.email_rounded,
                            'Email',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📧 Email sent!'),
                                  backgroundColor: kSuccess,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _quickActionButton(
                            Icons.phone_rounded,
                            'Call',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📞 Calling...'),
                                  backgroundColor: kSuccess,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _quickActionButton(
                            Icons.message_rounded,
                            'Message',
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('💬 Message sent!'),
                                  backgroundColor: kSuccess,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _quickActionButton(
                            Icons.person_rounded,
                            'Profile',
                            () {
                              Navigator.pop(context);
                              // Navigate to profile
                            },
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

  Widget _quickActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: kPrimary.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: kPrimary),
              const SizedBox(height: 2),
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> _getFilteredData() {
    // Return filtered data based on selected department
    return _orgData;
  }

  List<Map<String, dynamic>> _getFilteredDepartments() {
    var depts = List<Map<String, dynamic>>.from(_orgData['departments']);

    if (_selectedDepartment != 'All') {
      depts = depts.where((d) => d['name'] == _selectedDepartment).toList();
    }

    return depts;
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  String _getEmployeeName(String? id) {
    if (id == null) return 'N/A';

    // Search in all employees
    for (var dept in _orgData['departments']) {
      for (var emp in dept['employees']) {
        if (emp['id'] == id) return emp['name'];
      }
    }

    // Search in executives
    for (var exec in _orgData['executives']) {
      if (exec['id'] == id) return exec['name'];
    }

    // Search in CEO
    if (_orgData['ceo']['id'] == id) return _orgData['ceo']['name'];

    return id;
  }

  Color _getDepartmentColor(String name) {
    switch (name) {
      case 'Engineering':
        return Colors.blue;
      case 'Sales':
        return Colors.green;
      case 'Finance':
        return Colors.orange;
      case 'Human Resources':
        return Colors.purple;
      case 'Marketing':
        return Colors.pink;
      case 'Operations':
        return Colors.teal;
      default:
        return kPrimary;
    }
  }

  IconData _getDepartmentIcon(String name) {
    switch (name) {
      case 'Engineering':
        return Icons.code_rounded;
      case 'Sales':
        return Icons.trending_up_rounded;
      case 'Finance':
        return Icons.attach_money_rounded;
      case 'Human Resources':
        return Icons.people_rounded;
      case 'Marketing':
        return Icons.campaign_rounded;
      case 'Operations':
        return Icons.settings_rounded;
      default:
        return Icons.business_center_rounded;
    }
  }

  Widget _detailRow(String label, String value) {
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
                color: kText,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
              'Export Organization Chart',
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
              'Download org chart as PDF',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📄 Org chart exported as PDF!'),
                    backgroundColor: kSuccess,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _exportOption(
              Icons.image_rounded,
              'Export as Image',
              'Download org chart as PNG',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🖼️ Org chart exported as image!'),
                    backgroundColor: kSuccess,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _exportOption(
              Icons.print_rounded,
              'Print',
              'Print organization chart',
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🖨️ Printing org chart...'),
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