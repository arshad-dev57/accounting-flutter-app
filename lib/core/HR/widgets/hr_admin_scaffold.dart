import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/widgets/hr_drawer.dart';
import 'package:flutter/material.dart';

/// Shared admin page chrome matching web HR (#014582 / #F0F4F8).
class HrAdminScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final String drawerId;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showDrawer;

  const HrAdminScaffold({
    super.key,
    required this.title,
    required this.drawerId,
    required this.body,
    this.subtitle = '',
    this.actions,
    this.floatingActionButton,
    this.showDrawer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      drawer: showDrawer ? HRDrawer(currentItem: drawerId) : null,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          _Header(
            title: title,
            subtitle: subtitle,
            actions: actions,
            showMenu: showDrawer,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool showMenu;

  const _Header({
    required this.title,
    required this.subtitle,
    this.actions,
    this.showMenu = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kPrimary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (showMenu)
                GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}

class HrStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const HrStatChip({
    super.key,
    required this.label,
    required this.value,
    this.color = kPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kSubTextLight)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

class HrCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HrCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

Color hrStatusColor(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'approved':
    case 'paid':
    case 'present':
    case 'active':
    case 'completed':
      return kSuccess;
    case 'pending':
    case 'review':
    case 'late':
    case 'draft':
      return kWarning;
    case 'rejected':
    case 'absent':
    case 'held':
    case 'terminated':
      return kDanger;
    default:
      return kPrimary;
  }
}

class HrStatusPill extends StatelessWidget {
  final String status;
  const HrStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = hrStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c),
      ),
    );
  }
}

/// Generic admin list with optional approve/reject — used for many HCM screens.
class HrResourceListScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String drawerId;
  final Future<List<Map<String, dynamic>>> Function() loader;
  final String Function(Map<String, dynamic> row) titleOf;
  final String Function(Map<String, dynamic> row) subtitleOf;
  final String Function(Map<String, dynamic> row)? statusOf;
  final Future<void> Function(Map<String, dynamic> row, String status)? onStatus;
  final Future<void> Function()? onCreate;
  final IconData emptyIcon;
  final String? notice;

  const HrResourceListScreen({
    super.key,
    required this.title,
    required this.drawerId,
    required this.loader,
    required this.titleOf,
    required this.subtitleOf,
    this.subtitle = '',
    this.statusOf,
    this.onStatus,
    this.onCreate,
    this.emptyIcon = Icons.inbox_rounded,
    this.notice,
  });

  @override
  State<HrResourceListScreen> createState() => _HrResourceListScreenState();
}

class _HrResourceListScreenState extends State<HrResourceListScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  String _query = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await widget.loader();
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Set<String> get _statusOptions {
    if (widget.statusOf == null) return {};
    final statuses = _rows.map((r) => widget.statusOf!(r)).toSet();
    if (statuses.length <= 1) return {};
    return statuses;
  }

  @override
  Widget build(BuildContext context) {
    final statuses = _statusOptions;
    final filtered = _rows.where((r) {
      final q = _query.toLowerCase();
      final matchesQ = q.isEmpty || '${widget.titleOf(r)} ${widget.subtitleOf(r)}'.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == 'All' || (widget.statusOf?.call(r) == _statusFilter);
      return matchesQ && matchesStatus;
    }).toList();

    return HrAdminScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      drawerId: widget.drawerId,
      floatingActionButton: widget.onCreate == null
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await widget.onCreate!();
                _load();
              },
              backgroundColor: kPrimary,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            if (widget.notice != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kPrimary.withValues(alpha: 0.15)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.notice!, style: const TextStyle(fontSize: 11, color: kPrimary, height: 1.4))),
                ]),
              ),
            ],
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search…',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: kSubTextLight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kBorderLight),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (statuses.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _chip('All'),
                  ...statuses.map((s) => Padding(padding: const EdgeInsets.only(left: 6), child: _chip(s))),
                ]),
              ),
            ],
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: kPrimary)),
              )
            else if (_error != null)
              HrCard(
                child: Column(
                  children: [
                    Text(_error!, style: const TextStyle(color: kDanger, fontWeight: FontWeight.w600)),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if (filtered.isEmpty)
              HrCard(
                child: Column(
                  children: [
                    Icon(widget.emptyIcon, size: 40, color: kSubTextLight),
                    const SizedBox(height: 8),
                    const Text('No records yet', style: TextStyle(color: kSubTextLight, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text('Pull down to refresh', style: TextStyle(fontSize: 11, color: kSubTextLight)),
                  ],
                ),
              )
            else
              ...filtered.map((row) {
                final status = widget.statusOf?.call(row);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HrCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.titleOf(row),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: kTextLight),
                              ),
                            ),
                            if (status != null && status.isNotEmpty) HrStatusPill(status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitleOf(row),
                          style: const TextStyle(fontSize: 12, color: kSubTextLight, fontWeight: FontWeight.w500),
                        ),
                        if (widget.onStatus != null &&
                            (status == null ||
                                status.toLowerCase() == 'pending' ||
                                status.toLowerCase() == 'draft')) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _setStatus(row, 'Rejected'),
                                  style: OutlinedButton.styleFrom(foregroundColor: kDanger),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _setStatus(row, 'Approved'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    final sel = _statusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? kPrimary : kBorderLight),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? Colors.white : kSubText)),
      ),
    );
  }

  Future<void> _setStatus(Map<String, dynamic> row, String status) async {
    try {
      await widget.onStatus!(row, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked $status')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}
