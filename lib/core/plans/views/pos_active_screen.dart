import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/config/apiconfig.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/plans/views/billing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PosActiveScreen extends StatefulWidget {
  const PosActiveScreen({super.key});

  @override
  State<PosActiveScreen> createState() => _PosActiveScreenState();
}

class _PosActiveScreenState extends State<PosActiveScreen> {
  final _sub = Get.find<SubscriptionController>();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _sub.fetchCapacity();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openWebApp() async {
    final url = Uri.parse(Apiconfig().webAppUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cap = _sub.capacitySnapshot.value;
    final isActive = _sub.hasPosSubscription;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'POS Desktop',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _hero(isActive),
                const SizedBox(height: 16),
                if (isActive && cap != null) ...[
                  _statusCard(cap),
                  const SizedBox(height: 16),
                  _downloadSteps(),
                  const SizedBox(height: 16),
                  _featureList(),
                ] else
                  _inactiveCard(),
                const SizedBox(height: 16),
                _actions(isActive),
              ],
            ),
    );
  }

  Widget _hero(bool isActive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimary.withValues(alpha: 0.12),
            kPrimary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kPrimary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isActive ? Icons.check_circle_rounded : Icons.desktop_windows_rounded,
              color: isActive ? const Color(0xFF16A34A) : kPrimary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'POS subscription active' : 'POS not active',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Your desktop POS license is ready. Download the app from the web ERP using this account.'
                      : 'Subscribe to the POS plan to unlock the desktop Point of Sale application.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8A8FA8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(SubscriptionCapacity cap) {
    final end = _sub.subscriptionEndDate.value;
    final endLabel = end.isAfter(DateTime.now())
        ? DateFormat('d MMM yyyy').format(end)
        : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Column(
        children: [
          _row('Plan', cap.subscriptionPlan),
          _row('Billing cycle', cap.billingCycle),
          _row('Licensed POS users', '${cap.licensedUsers}'),
          _row('Users in use', '${cap.usedUsers}'),
          _row('Active until', endLabel),
          _row(
            'Monthly cost',
            cap.currentAmount == null ? '—' : formatUsd(cap.currentAmount!),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  Widget _downloadSteps() {
    final webUrl = Apiconfig().webAppUrl;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Download desktop POS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'The mobile app manages your subscription. The actual POS runs on Windows or Mac — install it from the web app:',
            style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA8), height: 1.45),
          ),
          const SizedBox(height: 14),
          _step('1', 'Open the BisonsTechs web app and sign in with this same account.'),
          _step('2', 'Go to POS → Management or Downloads in the web dashboard.'),
          _step('3', 'Download the desktop installer for Windows or Mac.'),
          _step('4', 'Install and sign in — your POS license will activate automatically.'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    webUrl,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: webUrl));
                    Get.snackbar('Copied', 'Web app URL copied');
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18, color: kPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: kPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF404040), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Included in POS',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D2E),
            ),
          ),
          const SizedBox(height: 10),
          ...posPricing.features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF404040)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inactiveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: const Text(
        'Subscribe to the POS (Desktop App) plan to activate offline sales, shifts, receipts and barcode scanning on Windows or Mac.',
        style: TextStyle(fontSize: 13, color: Color(0xFF8A8FA8), height: 1.45),
      ),
    );
  }

  Widget _actions(bool isActive) {
    return Column(
      children: [
        if (isActive)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openWebApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              label: const Text(
                'Open web app to download POS',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (!isActive)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const SelectPlanScreen()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View POS plans',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Get.to(() => const BillingScreen()),
            style: OutlinedButton.styleFrom(
              foregroundColor: kPrimary,
              side: const BorderSide(color: kPrimary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Billing & invoices',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
