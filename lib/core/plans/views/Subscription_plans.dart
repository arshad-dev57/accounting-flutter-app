import 'package:BisonsTechs_app/Services/auth_logout_service.dart';
import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/views/pricing_section.dart';
import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';
import 'package:BisonsTechs_app/core/support/controllers/support_ticket_controller.dart';
import 'package:BisonsTechs_app/core/support/screens/support_tickets_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await _withLoading('Starting your $trialDays-day free trial...', () => _subCtrl.startTrial());
  }

  Future<void> _subscribePlan({
    required String billingCycle,
    required double amount,
    required String productTier,
    required int licensedUsers,
    required int licensedBranches,
    required bool isUpgrade,
  }) async {
    await _withLoading(
      isUpgrade ? 'Updating your subscription...' : 'Activating your subscription...',
      () => _subCtrl.subscribe(
        billingCycle,
        amount,
        productTier: productTier,
        licensedUsers: licensedUsers,
        licensedBranches: licensedBranches,
        isUpgrade: isUpgrade,
      ),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          if (!PermissionService.to.isAdmin) {
            if (_subCtrl.isLoading.value && _subCtrl.subscriptionPlan.value.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: kPrimary));
            }
            if (_subCtrl.hasAccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Get.currentRoute != '/dashboard') {
                  Get.offAllNamed('/dashboard');
                }
              });
              return const Center(child: CircularProgressIndicator(color: kPrimary));
            }
            return const _ContactAdminScreen();
          }

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
                            'PLANS & PRICING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                              color: Color(0xFFA3A3A3),
                            ),
                          ),
                          const SizedBox(height: 14),
                          PricingSection(
                            processing: _isProcessing,
                            isTrial: _subCtrl.onTrial,
                            isPaid: _subCtrl.hasAccess && !_subCtrl.onTrial,
                            onComplete: () => Get.offAllNamed('/dashboard'),
                            onStartTrial: _startTrial,
                            onSubscribe: _subscribePlan,
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
  ('trial', 'Trial', '\$0'),
  ('monthly', 'Monthly', 'From \$36 / mo'),
  ('yearly', 'Yearly', 'From \$257 / yr'),
  ('custom', 'Custom', 'Let’s talk'),
];

final _kCompareRows = <_CompareRow>[
  const _CompareRow.section('Access & users'),
  const _CompareRow.feature('Active subscription access', {
    'trial': '$trialDays days',
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
    'trial': 'Unlimited',
    'monthly': 'Scales with plan',
    'yearly': 'Scales with plan',
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

class _ContactAdminScreen extends StatelessWidget {
  const _ContactAdminScreen();

  Future<void> _logout() async {
    try {
      await AuthLogoutService.clearPushSession();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await PermissionService.to.clearUserData();
    } catch (_) {}
    Get.offAll(() => const LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SUBSCRIPTION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Contact your administrator',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your company\'s subscription has expired. Only an admin can view plans and renew access. Please ask your administrator to update the subscription.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF737373), height: 1.45),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary),
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
