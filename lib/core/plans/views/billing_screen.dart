import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/models/company_billing.dart';
import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _sub = Get.find<SubscriptionController>();
  CompanyBilling? _billing;
  String? _error;
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    if (!PermissionService.to.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = await _sub.fetchCompanyBilling();
    if (!mounted) return;
    setState(() {
      _billing = data;
      _loading = false;
      if (data == null) _error = 'Failed to load billing data';
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('d MMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.to.isAdmin) {
      return const SizedBox.shrink();
    }

    final billing = _billing;
    final cap = billing?.capacity;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Billing & Invoices',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kText,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => Get.to(() => const SelectPlanScreen()),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Manage plan'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                ],
              )
            : billing == null || cap == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Text(
                    billing.companyName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8A8FA8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _statsGrid(billing),
                  const SizedBox(height: 20),
                  _tabBar(),
                  const SizedBox(height: 16),
                  if (_tab == 0) _overview(billing, cap),
                  if (_tab == 1) _invoices(billing),
                ],
              ),
      ),
    );
  }

  Widget _statsGrid(CompanyBilling billing) {
    final stats = billing.stats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _statCard(
          'Current plan cost',
          billing.capacity.isPaid ? formatUsd(stats.currentAmount) : '—',
          billing.capacity.isTrial
              ? 'Free trial'
              : billing.capacity.isPaid
              ? 'Per ${billing.capacity.billingCycle == 'yearly' ? 'year' : 'month'}'
              : 'No paid plan',
          Icons.credit_card_rounded,
        ),
        _statCard(
          'Total paid',
          formatUsd(stats.totalPaid),
          'All time',
          Icons.trending_up_rounded,
        ),
        _statCard(
          'Paid this month',
          formatUsd(stats.paidThisMonth),
          DateFormat('MMMM yyyy').format(DateTime.now()),
          Icons.calendar_today_rounded,
        ),
        _statCard(
          'Invoices',
          '${stats.invoiceCount}',
          'Payment records',
          Icons.receipt_long_rounded,
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF8A8FA8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A8FA8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A8FA8)),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Row(
      children: [
        _tabChip('Overview', 0),
        const SizedBox(width: 8),
        _tabChip('Invoices', 1),
      ],
    );
  }

  Widget _tabChip(String label, int index) {
    final selected = _tab == index;
    return Material(
      color: selected ? kPrimary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? kPrimary : const Color(0xFFEEEFF4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF8A8FA8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _overview(CompanyBilling billing, SubscriptionCapacity cap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current subscription',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1D2E),
                ),
              ),
              const SizedBox(height: 12),
              _detailRow('Product', cap.productTier == tierPos ? 'POS Desktop' : 'ERP + POS'),
              _detailRow('Plan', cap.subscriptionPlan),
              _detailRow('Billing', cap.billingCycle),
              _detailRow('Status', cap.subscriptionStatus),
              if (cap.productTier == tierPos)
                _detailRow('Licensed users', '${cap.usedUsers} / ${cap.licensedUsers}')
              else ...[
                _detailRow('Users', '${cap.usedUsers} / ${cap.licensedUsers}'),
                _detailRow('Branches', '${cap.usedBranches} / ${cap.licensedBranches}'),
              ],
              if (cap.isPaid && billing.subscriptionDaysRemaining > 0)
                _detailRow(
                  'Renews in',
                  '${billing.subscriptionDaysRemaining} day(s)',
                ),
              if (cap.isTrial && billing.trialDaysRemaining > 0)
                _detailRow('Trial ends', _formatDate(billing.trialEndDate)),
            ],
          ),
        ),
        if (billing.monthlyStats.isNotEmpty) ...[
          const SizedBox(height: 16),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly payments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
                const SizedBox(height: 12),
                ...billing.monthlyStats.map(
                  (row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D2E),
                            ),
                          ),
                        ),
                        Text(
                          '${row.count} payment(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A8FA8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          formatUsd(row.total),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _invoices(CompanyBilling billing) {
    if (billing.invoices.isEmpty) {
      return _panel(
        child: const Text(
          'No invoices yet.',
          style: TextStyle(color: Color(0xFF8A8FA8)),
        ),
      );
    }

    return Column(
      children: billing.invoices.map((inv) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv.invoiceNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1D2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${inv.tierLabel} · ${inv.typeLabel}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8A8FA8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(inv.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB0B4C8),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatUsd(inv.amount, inv.currency),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: child,
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF8A8FA8)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D2E),
            ),
          ),
        ],
      ),
    );
  }
}
