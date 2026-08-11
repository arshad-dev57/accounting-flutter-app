import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/support/controllers/support_ticket_controller.dart';
import 'package:BisonsTechs_app/core/support/screens/support_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SelectPlanScreen extends StatefulWidget {
  const SelectPlanScreen({super.key});

  @override
  State<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends State<SelectPlanScreen> {
  late final SubscriptionController _subCtrl;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _subCtrl = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController(), permanent: true);
    _subCtrl.checkSubscriptionStatus();
  }

  Future<void> _withLoading(String message, Future<bool> Function() action) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    Get.dialog(
      Center(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.waveDots(color: kPrimary, size: 42),
                const SizedBox(height: 14),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final ok = await action();
    if (Get.isDialogOpen ?? false) Get.back();

    if (ok && mounted) {
      Get.offAllNamed('/dashboard');
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _startTrial() async {
    await _withLoading('Starting your 30-day free trial...', () => _subCtrl.startTrial());
  }

  Future<void> _subscribe(String planId, double amount) async {
    await _withLoading(
      'Activating your subscription...',
      () => _subCtrl.subscribe(planId, amount),
    );
  }

  Future<void> _cancel() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Cancel subscription?'),
        content: const Text('Access will end immediately.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Keep plan')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Cancel plan', style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    Get.dialog(
      Center(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.waveDots(color: kPrimary, size: 42),
                const SizedBox(height: 14),
                const Text(
                  'Cancelling subscription...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    await _subCtrl.cancelSubscription();
    if (Get.isDialogOpen ?? false) Get.back();
    if (mounted) setState(() => _isProcessing = false);
  }

  void _openCustomRequest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CustomPlanSheet(),
    );
  }

  String get _statusLine {
    if (_subCtrl.isLoading.value && !_subCtrl.hasAccess && _subCtrl.subscriptionPlan.isEmpty) {
      return 'Loading your subscription…';
    }
    if (_subCtrl.onTrial) {
      return 'You are on a free trial · ${_subCtrl.trialDaysRemaining.value} day(s) left';
    }
    if (_subCtrl.hasAccess &&
        (_subCtrl.subscriptionPlan.value == 'monthly' ||
            _subCtrl.subscriptionPlan.value == 'yearly')) {
      return 'Active ${_subCtrl.subscriptionPlan.value} plan · ${_subCtrl.subscriptionDaysRemaining.value} day(s) remaining';
    }
    return 'No active plan — choose a plan below to unlock the ERP';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isWide = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          return Column(
            children: [
              _TopBar(
                onCancel: (_subCtrl.hasAccess && !_subCtrl.onTrial) ? _cancel : null,
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 20 : 40,
                        28,
                        isMobile ? 20 : 40,
                        40,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _HeroHeader(statusLine: _statusLine),
                          const SizedBox(height: 16),
                          if (_subCtrl.hasAccess) ...[
                            _ActiveBanner(
                              isTrial: _subCtrl.onTrial,
                              plan: _subCtrl.subscriptionPlan.value,
                              onContinue: () => Get.offAllNamed('/dashboard'),
                              onCancel: _subCtrl.onTrial ? null : _cancel,
                            ),
                            const SizedBox(height: 20),
                          ],
                          const Text(
                            'INDIVIDUAL PLANS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                              color: Color(0xFFA3A3A3),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PlanCardsGrid(
                            isWide: isWide,
                            isMobile: isMobile,
                            processing: _isProcessing,
                            currentPlan: _subCtrl.subscriptionPlan.value,
                            hasAccess: _subCtrl.hasAccess,
                            onTrial: _startTrial,
                            onSubscribe: _subscribe,
                            onCustom: _openCustomRequest,
                          ),
                          const SizedBox(height: 48),
                          const Text(
                            'Compare Plans',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0A0A0A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Everything you can run in the Bisonstechs ERP — accounting, sales, purchases, warehouse, POS, reports and support — by plan.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF737373), height: 1.45),
                          ),
                          const SizedBox(height: 20),
                          const _CompareTable(),
                          const SizedBox(height: 28),
                          Center(
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(fontSize: 12, color: Color(0xFFA3A3A3)),
                                children: [
                                  const TextSpan(text: 'Need help choosing? '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: GestureDetector(
                                      onTap: () => Get.to(
                                        () => const SupportTicketsScreen(),
                                      ),
                                      child: const Text(
                                        'Open a support ticket',
                                        style: TextStyle(
                                          color: kPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' or request a Custom plan above.'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final VoidCallback? onCancel;
  const _TopBar({this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: kPrimary.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.business, size: 18, color: kPrimary),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bisonstechs',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: kPrimary,
                ),
              ),
              Text(
                'ERP Suite',
                style: TextStyle(fontSize: 11, color: Color(0xFF737373)),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Get.back();
              } else {
                Get.offAllNamed('/dashboard');
              }
            },
            child: const Text('Dashboard', style: TextStyle(color: kPrimary)),
          ),
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel plan', style: TextStyle(color: kDanger)),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HERO
// ═══════════════════════════════════════════════════════════════════

class _HeroHeader extends StatelessWidget {
  final String statusLine;
  const _HeroHeader({required this.statusLine});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Bisonstechs\n',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              TextSpan(
                text: 'Plans and Pricing',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFA3A3A3),
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          statusLine,
          style: const TextStyle(fontSize: 13, color: Color(0xFF737373)),
        ),
        if (!isMobile) ...[
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Choose the perfect plan for your business journey.',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, color: Color(0xFF737373)),
                ),
                SizedBox(height: 6),
                Text(
                  'COMPARE EVERY ERP FEATURE →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  final bool isTrial;
  final String plan;
  final VoidCallback onContinue;
  final VoidCallback? onCancel;

  const _ActiveBanner({
    required this.isTrial,
    required this.plan,
    required this.onContinue,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isTrial ? 'You are on a Free Trial' : 'Current plan: $plan',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextLight,
              ),
            ),
          ),
          TextButton(
            onPressed: onContinue,
            style: TextButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Continue to ERP', style: TextStyle(fontSize: 12)),
          ),
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 12, color: Color(0xFF525252)),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PLAN CARDS
// ═══════════════════════════════════════════════════════════════════

class _PlanDef {
  final String id;
  final String name;
  final String priceLabel;
  final String? priceSub;
  final String? badge;
  final bool popular;
  final String cta;
  final bool outlineCta;
  final String includesLabel;
  final List<String> highlights;
  final double? amount;

  const _PlanDef({
    required this.id,
    required this.name,
    required this.priceLabel,
    this.priceSub,
    this.badge,
    this.popular = false,
    required this.cta,
    this.outlineCta = false,
    required this.includesLabel,
    required this.highlights,
    this.amount,
  });
}

const _kPlans = <_PlanDef>[
  _PlanDef(
    id: 'trial',
    name: 'Trial',
    priceLabel: '\$0',
    cta: 'Start free trial',
    outlineCta: true,
    includesLabel: '30-DAY FULL ACCESS',
    highlights: [
      'Full ERP access for 30 days',
      'Accounting, sales, purchases & warehouse',
      'POS terminal & receipts',
      'Reports export to PDF / Excel',
      'Email support during trial',
    ],
  ),
  _PlanDef(
    id: 'monthly',
    name: 'Monthly',
    priceLabel: '\$15',
    priceSub: 'PER MONTH',
    badge: 'FLEXIBLE',
    cta: 'Select plan',
    includesLabel: 'EVERYTHING IN TRIAL, PLUS:',
    highlights: [
      'Unlimited transactions & journals',
      'Invoices, bills, payments & AR/AP',
      'Inventory, stock & goods receiving',
      'Sales orders, POS & purchase flow',
      'Financial statements & aged reports',
      'Email support',
    ],
    amount: 15,
  ),
  _PlanDef(
    id: 'yearly',
    name: 'Yearly',
    priceLabel: '\$150',
    priceSub: 'PER YEAR',
    badge: 'POPULAR',
    popular: true,
    cta: 'Select plan',
    includesLabel: 'EVERYTHING IN MONTHLY, PLUS:',
    highlights: [
      '2 months free (save ~16%)',
      'Priority support',
      'Advanced analytics & PDF branding',
      'Best value for growing businesses',
      'Continuous updates & data security',
    ],
    amount: 150,
  ),
  _PlanDef(
    id: 'custom',
    name: 'Custom',
    priceLabel: 'Let’s talk',
    badge: 'NEW',
    cta: 'Request features',
    includesLabel: 'TAILORED FOR YOUR BUSINESS:',
    highlights: [
      'Tell us the features you need',
      'Discuss scope with our product team',
      'Custom modules, reports or workflows',
      'Dedicated onboarding & training',
      'Flexible pricing for your company',
    ],
  ),
];

class _PlanCardsGrid extends StatelessWidget {
  final bool isWide;
  final bool isMobile;
  final bool processing;
  final String currentPlan;
  final bool hasAccess;
  final Future<void> Function() onTrial;
  final Future<void> Function(String, double) onSubscribe;
  final VoidCallback onCustom;

  const _PlanCardsGrid({
    required this.isWide,
    required this.isMobile,
    required this.processing,
    required this.currentPlan,
    required this.hasAccess,
    required this.onTrial,
    required this.onSubscribe,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isWide ? 4 : (isMobile ? 1 : 2);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _kPlans.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? 0.78 : (isWide ? 0.62 : 0.72),
      ),
      itemBuilder: (context, i) {
        final p = _kPlans[i];
        final isCurrent =
            hasAccess && p.id != 'custom' && currentPlan == p.id;
        return _PlanCard(
          plan: p,
          isCurrent: isCurrent,
          processing: processing,
          onTap: () {
            if (processing) return;
            if (p.id == 'custom') {
              onCustom();
            } else if (p.id == 'trial') {
              onTrial();
            } else {
              onSubscribe(p.id, p.amount ?? 0);
            }
          },
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _PlanDef plan;
  final bool isCurrent;
  final bool processing;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.processing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: plan.popular ? kPrimary : const Color(0xFFE5E5E5),
          width: plan.popular ? 1.5 : 1,
        ),
        boxShadow: plan.popular
            ? [
                BoxShadow(
                  color: kPrimary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF737373),
                  ),
                ),
              ),
              if (plan.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: plan.popular
                        ? kPrimary.withValues(alpha: 0.1)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    plan.badge!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: plan.popular ? kPrimary : const Color(0xFF525252),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  plan.priceLabel,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A0A0A),
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
              ),
              if (plan.priceSub != null) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    plan.priceSub!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Color(0xFFA3A3A3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (processing || (isCurrent && plan.id != 'custom'))
                  ? null
                  : onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    plan.outlineCta ? Colors.white : kPrimary,
                foregroundColor:
                    plan.outlineCta ? kPrimary : Colors.white,
                disabledBackgroundColor: kPrimary.withValues(alpha: 0.35),
                disabledForegroundColor: Colors.white,
                side: plan.outlineCta
                    ? const BorderSide(color: kPrimary, width: 1.5)
                    : BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isCurrent && plan.id != 'custom' ? 'Current plan' : plan.cta,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 14),
          Text(
            plan.includesLabel,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFFA3A3A3),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plan.highlights.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check, size: 16, color: kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plan.highlights[i],
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF404040),
                        height: 1.3,
                      ),
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
}

// ═══════════════════════════════════════════════════════════════════
// COMPARE TABLE
// ═══════════════════════════════════════════════════════════════════

class _CompareRow {
  final bool section;
  final String label;
  final Map<String, dynamic>? values;
  const _CompareRow.section(this.label)
      : section = true,
        values = null;
  const _CompareRow.feature(this.label, this.values) : section = false;
}

const _kCompareCols = [
  ('trial', 'Trial', '\$0 / month'),
  ('monthly', 'Monthly', '\$15 / month'),
  ('yearly', 'Yearly', '\$150 / year'),
  ('custom', 'Custom', 'Let’s talk'),
];

final _kCompareRows = <_CompareRow>[
  const _CompareRow.section('Access & users'),
  const _CompareRow.feature('Active subscription access', {
    'trial': '30 days',
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Company workspace', {
    'trial': '1',
    'monthly': '1',
    'yearly': '1',
    'custom': 'Unlimited',
  }),
  const _CompareRow.feature('User seats', {
    'trial': 'Limited',
    'monthly': 'Standard',
    'yearly': 'Standard',
    'custom': 'Unlimited / negotiated',
  }),
  const _CompareRow.section('Accounting'),
  const _CompareRow.feature('Chart of accounts & journals', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Invoices, bills & payments', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('P&L, balance sheet, cash flow', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Trial balance, GL & aged AR', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Fixed assets, loans & equity', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.section('Sales & POS'),
  const _CompareRow.feature('Orders, quotations & invoices', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Customers, deliveries & returns', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Point of Sale & shifts', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Sales reports (PDF / Excel)', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.section('Purchases & warehouse'),
  const _CompareRow.feature('Purchase orders & invoices', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Goods receiving & payments', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Products, stock & categories', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Purchase reports (PDF / Excel)', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.section('Support & extras'),
  const _CompareRow.feature('Support tickets', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Priority support', {
    'trial': false,
    'monthly': false,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('PDF branding & signature', {
    'trial': true,
    'monthly': true,
    'yearly': true,
    'custom': true,
  }),
  const _CompareRow.feature('Custom feature development', {
    'trial': false,
    'monthly': false,
    'yearly': false,
    'custom': true,
  }),
  const _CompareRow.feature('Dedicated onboarding', {
    'trial': false,
    'monthly': false,
    'yearly': false,
    'custom': true,
  }),
];

class _CompareTable extends StatelessWidget {
  const _CompareTable();

  Widget _cell(dynamic value) {
    if (value is bool) {
      return value
          ? Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            )
          : Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kDanger),
              ),
              child: const Icon(Icons.close, size: 12, color: kDanger),
            );
    }
    return Text(
      '$value',
      style: const TextStyle(fontSize: 12.5, color: Color(0xFF404040)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 860,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(bottom: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 220),
                  ..._kCompareCols.map(
                    (c) => Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.$2,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A0A0A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.$3,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFA3A3A3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._kCompareRows.map((row) {
              if (row.section) {
                return Padding(
                  padding: const EdgeInsets.only(top: 22, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      row.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF262626),
                        ),
                      ),
                    ),
                    ..._kCompareCols.map(
                      (c) => Expanded(child: _cell(row.values![c.$1])),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CUSTOM PLAN SHEET
// ═══════════════════════════════════════════════════════════════════

class _CustomPlanSheet extends StatefulWidget {
  const _CustomPlanSheet();

  @override
  State<_CustomPlanSheet> createState() => _CustomPlanSheetState();
}

class _CustomPlanSheetState extends State<_CustomPlanSheet> {
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _featuresCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _featuresCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _featuresCtrl.text.trim().isEmpty) {
      AppSnackbar.error(kDanger, 'Required', 'Please describe the features you want');
      return;
    }
    setState(() => _submitting = true);

    final support = Get.isRegistered<SupportTicketController>()
        ? Get.find<SupportTicketController>()
        : Get.put(SupportTicketController());

    final description = [
      'Custom plan / feature request from Subscription page.',
      if (_companyCtrl.text.trim().isNotEmpty)
        'Company / context: ${_companyCtrl.text.trim()}',
      '',
      'Requested features / requirements:',
      _featuresCtrl.text.trim(),
    ].join('\n');

    final ok = await support.createTicket(
      title: _titleCtrl.text.trim(),
      description: description,
      category: 'Feature Request',
      priority: 'Medium',
    );

    if (mounted) setState(() => _submitting = false);
    if (ok && mounted) {
      Get.back();
      AppSnackbar.success(
        kSuccess,
        'Request sent',
        'Our team will contact you to discuss features and pricing.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Custom plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tell us what new features or workflows you need. Our team will discuss scope and pricing with you.',
              style: TextStyle(fontSize: 13, color: Color(0xFF737373), height: 1.4),
            ),
            const SizedBox(height: 18),
            _field('Request title', _titleCtrl,
                hint: 'e.g. Multi-branch inventory + custom payroll reports'),
            const SizedBox(height: 12),
            _field('Company / context (optional)', _companyCtrl,
                hint: 'Business name, industry, team size'),
            const SizedBox(height: 12),
            _field(
              'Features you want',
              _featuresCtrl,
              hint: 'List the modules, reports, integrations or workflows you need…',
              maxLines: 5,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFD4D4D4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Send to team',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Color(0xFF737373),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFA3A3A3)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
