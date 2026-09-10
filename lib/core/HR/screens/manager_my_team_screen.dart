import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/HR/services/hr_api_service.dart';
import 'package:flutter/material.dart';

class ManagerMyTeamScreen extends StatefulWidget {
  const ManagerMyTeamScreen({super.key});

  @override
  State<ManagerMyTeamScreen> createState() => _ManagerMyTeamScreenState();
}

class _ManagerMyTeamScreenState extends State<ManagerMyTeamScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _data = await HrApiService.instance.myTeam();
      _error = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final members = (_data['members'] as List?)?.whereType<Map>().toList() ?? [];
    final approvals = _data['approvals'] as Map<String, dynamic>? ?? {};
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: kPrimary,
        title: const Text('My Team', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('${members.length} team members', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...members.map((m) {
                      final att = m['attendance'] as Map?;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFDDE4EE)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${m['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text('${m['designation'] ?? ''} · ${m['department'] ?? ''}', style: TextStyle(color: kSubText, fontSize: 11)),
                                ],
                              ),
                            ),
                            Text(att == null ? 'Absent' : '${att['status'] ?? 'Present'}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text('Pending leaves ${(approvals['leaves'] as List?)?.length ?? 0}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('Pending overtime ${(approvals['overtime'] as List?)?.length ?? 0}', style: TextStyle(color: kSubText)),
                    Text('Attendance corrections ${(approvals['attendance'] as List?)?.length ?? 0}', style: TextStyle(color: kSubText)),
                  ],
                ),
    );
  }
}
