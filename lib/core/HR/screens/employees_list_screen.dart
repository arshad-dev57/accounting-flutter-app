import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/screens/add_employee_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_profile_screen.dart';
import 'package:BisonsTechs_app/widgets/hr_drawer.dart';
import 'package:flutter/material.dart';


class EmployeesListScreen extends StatefulWidget {
  const EmployeesListScreen({super.key});

  @override
  State<EmployeesListScreen> createState() => _EmployeesListScreenState();
}

class _EmployeesListScreenState extends State<EmployeesListScreen> {
  String _query = '';
  String _filter = 'All';

  final List<Map<String, dynamic>> _employees = [
    {
      'id': 'EMP-001',
      'name': 'Ahmed Khan',
      'designation': 'CTO',
      'department': 'IT',
      'status': 'Active',
      'office': 'Head Office',
    },
    {
      'id': 'EMP-002',
      'name': 'Sara Ali',
      'designation': 'Software Engineer',
      'department': 'IT',
      'status': 'Active',
      'office': 'Head Office',
    },
    {
      'id': 'EMP-003',
      'name': 'Ali Raza',
      'designation': 'VP Sales',
      'department': 'Sales',
      'status': 'Active',
      'office': 'North Branch',
    },
    {
      'id': 'EMP-004',
      'name': 'Fatima Noor',
      'designation': 'HR Manager',
      'department': 'HR',
      'status': 'Active',
      'office': 'Head Office',
    },
    {
      'id': 'EMP-005',
      'name': 'Usman Sheikh',
      'designation': 'Sales Manager',
      'department': 'Sales',
      'status': 'On Leave',
      'office': 'South Branch',
    },
    {
      'id': 'EMP-006',
      'name': 'Nadia Khan',
      'designation': 'Senior Software Engineer',
      'department': 'IT',
      'status': 'Inactive',
      'office': 'Head Office',
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    return _employees.where((emp) {
      final matchesFilter = _filter == 'All' || emp['status'] == _filter;
      final q = _query.toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          emp['name'].toString().toLowerCase().contains(q) ||
          emp['id'].toString().toLowerCase().contains(q) ||
          emp['department'].toString().toLowerCase().contains(q);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search employees...',
                    hintStyle: TextStyle(color: kSubText, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: kSubText),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _chip('All'),
                    const SizedBox(width: 8),
                    _chip('Active'),
                    const SizedBox(width: 8),
                    _chip('On Leave'),
                    const SizedBox(width: 8),
                    _chip('Inactive'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: _filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final emp = _filtered[index];
                return _employeeCard(emp);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => HRNav.go(context, const AddEmployeeScreen()),
        backgroundColor: kPrimary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
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
                      'Employees List',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_filtered.length} employees',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.7),
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

  Widget _chip(String label) {
    final selected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : kSubText,
          ),
        ),
      ),
    );
  }

  Widget _employeeCard(Map<String, dynamic> emp) {
    final status = emp['status'] as String;
    final statusColor = status == 'Active'
        ? kSuccess
        : status == 'On Leave'
        ? Colors.purple
        : kSubText;

    return GestureDetector(
      onTap: () => HRNav.go(
        context,
        EmployeeProfileScreen(employeeId: emp['id'] as String),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: kPrimary.withValues(alpha: 0.12),
              child: Text(
                emp['name'].toString().substring(0, 1),
                style: const TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp['name'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${emp['designation']} • ${emp['department']}',
                    style: TextStyle(fontSize: 11, color: kSubText),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
