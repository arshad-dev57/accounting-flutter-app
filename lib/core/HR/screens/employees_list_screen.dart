import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/screens/add_employee_screen.dart';
import 'package:BisonsTechs_app/core/HR/screens/employee_profile_screen.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
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
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await HrApiService.instance.employees();
      if (!mounted) return;
      setState(() { _employees = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _employees.where((emp) {
      final matchesFilter = _filter == 'All' || emp['status'] == _filter;
      final q = _query.toLowerCase();
      final matchesQuery = q.isEmpty ||
          emp['name'].toString().toLowerCase().contains(q) ||
          emp['id'].toString().toLowerCase().contains(q) ||
          (emp['employeeCode'] ?? '').toString().toLowerCase().contains(q) ||
          emp['department'].toString().toLowerCase().contains(q);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  Future<void> _deactivate(Map<String, dynamic> emp) async {
    final name = emp['name'] ?? 'Employee';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Deactivate Employee'),
        content: Text('Set $name as Inactive? They will lose app access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await HrApiService.instance.deactivateEmployee('${emp['id']}');
      await _loadEmployees();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name deactivated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: kDanger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _employees.length;
    final active = _employees.where((e) => e['status'] == 'Active').length;
    final onLeave = _employees.where((e) => e['status'] == 'On Leave').length;
    final inactive = _employees.where((e) => e['status'] == 'Inactive').length;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: kBgLight,
      drawer: const HRDrawer(currentItem: 'employees'),
      body: Column(
        children: [
          _buildHeader(),
          // Stat cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              _statCard('Total', '$total', kPrimary),
              const SizedBox(width: 8),
              _statCard('Active', '$active', kSuccess),
              const SizedBox(width: 8),
              _statCard('On Leave', '$onLeave', Colors.purple),
              const SizedBox(width: 8),
              _statCard('Inactive', '$inactive', kSubText),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search name, code, department…',
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
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _chip('All'), const SizedBox(width: 8),
                    _chip('Active'), const SizedBox(width: 8),
                    _chip('On Leave'), const SizedBox(width: 8),
                    _chip('Inactive'),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              TextButton(onPressed: _loadEmployees, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(child: Text('No employees. Tap + to add.', style: TextStyle(color: kSubText)))
                        : RefreshIndicator(
                            onRefresh: _loadEmployees,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) => _employeeCard(filtered[index]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
          );
          if (created == true) _loadEmployees();
        },
        backgroundColor: kPrimary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    ),
  );

  Widget _buildHeader() {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Employees',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('${_employees.length} staff',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
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
        child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : kSubText)),
      ),
    );
  }

  Widget _employeeCard(Map<String, dynamic> emp) {
    final status = emp['status']?.toString() ?? 'Active';
    final name = emp['name']?.toString() ?? 'Employee';
    final code = emp['employeeCode']?.toString() ?? '';
    final isActive = status == 'Active';
    final statusColor = status == 'Active' ? kSuccess : status == 'On Leave' ? Colors.purple : kSubText;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => HRNav.go(context, EmployeeProfileScreen(employeeId: emp['id']?.toString())),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: kPrimary.withValues(alpha: 0.12),
                    child: Text(name.isNotEmpty ? name[0] : 'E',
                      style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText))),
                          if (code.isNotEmpty)
                            Text(code, style: TextStyle(fontSize: 10, color: kSubText, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 2),
                        Text('${emp['designation']} · ${emp['department']}',
                          style: TextStyle(fontSize: 11, color: kSubText)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(status,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                  ),
                ],
              ),
            ),
          ),
          // Action row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                _actionBtn('View', Icons.visibility_outlined, kPrimary, () =>
                  HRNav.go(context, EmployeeProfileScreen(employeeId: emp['id']?.toString()))),
                const SizedBox(width: 8),
                _actionBtn('Edit', Icons.edit_outlined, kPrimary, () async {
                  final updated = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => AddEmployeeScreen(employee: emp)),
                  );
                  if (updated == true) _loadEmployees();
                }),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  _actionBtn('Deactivate', Icons.block_outlined, kDanger, () => _deactivate(emp)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
}
