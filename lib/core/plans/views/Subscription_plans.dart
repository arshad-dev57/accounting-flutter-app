import 'package:BisonsTechs_app/Services/auth_logout_service.dart';
import 'package:BisonsTechs_app/Services/permission_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/responsive_utils.dart';
import 'package:BisonsTechs_app/core/login/screen/login_screen.dart';
import 'package:BisonsTechs_app/core/plans/controllers/subscription_controller.dart';
import 'package:BisonsTechs_app/core/plans/views/pricing_section.dart';
import 'package:BisonsTechs_app/core/plans/views/pos_active_screen.dart';
import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String _plansContactEmail = 'support@bisonstechs.com';
const String _plansContactPhone = '+92 325 3411482';
const String _plansContactPhoneTel = '+923253411482';

class SelectPlanScreen extends StatefulWidget {
  const SelectPlanScreen({super.key});

  @override
  State<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends State<SelectPlanScreen> {
  late final SubscriptionController _subCtrl;
  bool _isProcessing = false;
  String? _pendingProductTier;

  @override
  void initState() {
    super.initState();
    _subCtrl = Get.isRegistered<SubscriptionController>()
        ? Get.find<SubscriptionController>()
        : Get.put(SubscriptionController(), permanent: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subCtrl.checkSubscriptionStatus();
    });
  }

  Future<void> _withLoading(
    String message,
    Future<bool> Function() action, {
    String? productTier,
  }) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    OverlayEntry? entry;
    var ok = false;
    try {
      final overlay = Overlay.of(context, rootOverlay: true);
      entry = OverlayEntry(
        builder: (_) => Stack(
          children: [
            const ModalBarrier(dismissible: false, color: Color(0x66000000)),
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
          ],
        ),
      );
      overlay.insert(entry);
      ok = await action();
    } finally {
      entry?.remove();
    }

    if (ok && mounted) {
      final tier = productTier ?? _pendingProductTier ?? _subCtrl.productTier.value;
      if (tier == tierPos) {
        Get.off(() => const PosActiveScreen());
      } else {
        Get.offAllNamed('/dashboard');
      }
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
    _pendingProductTier = productTier;
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
      productTier: productTier,
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
    if (_subCtrl.isCheckingStatus.value &&
        !_subCtrl.hasAccess &&
        _subCtrl.subscriptionPlan.isEmpty) {
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
            if (_subCtrl.isCheckingStatus.value &&
                _subCtrl.subscriptionPlan.value.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: kPrimary));
            }
            if (_subCtrl.hasAccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _subCtrl.goToAppHome();
              });
              return const Center(child: CircularProgressIndicator(color: kPrimary));
            }
            return const _ContactAdminScreen();
          }

          return Column(
            children: [
              _TopBar(
                showHome: _subCtrl.hasAccess,
                isPosOnly: _subCtrl.isPosOnly,
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
                              isPos: _subCtrl.hasPosSubscription,
                              onContinue: () {
                                if (_subCtrl.hasPosSubscription) {
                                  Get.to(() => const PosActiveScreen());
                                } else {
                                  Get.offAllNamed('/dashboard');
                                }
                              },
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
                            trialEligible: _subCtrl.trialEligible.value,
                            onComplete: () {
                              if (_subCtrl.isPosOnly) {
                                Get.offAll(() => const PosActiveScreen());
                              } else {
                                Get.offAllNamed('/dashboard');
                              }
                            },
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
                          const _CustomPlanContactFooter(),
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
  final bool showHome;
  final bool isPosOnly;
  const _TopBar({
    this.onCancel,
    this.showHome = false,
    this.isPosOnly = false,
  });

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
          if (showHome)
            TextButton(
              onPressed: () {
                if (isPosOnly) {
                  Get.offAll(() => const PosActiveScreen());
                } else if (Navigator.canPop(context)) {
                  Get.back();
                } else {
                  Get.offAllNamed('/dashboard');
                }
              },
              child: Text(
                isPosOnly ? 'POS' : 'Dashboard',
                style: const TextStyle(color: kPrimary),
              ),
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
  final bool isPos;
  final VoidCallback onContinue;
  final VoidCallback? onCancel;

  const _ActiveBanner({
    required this.isTrial,
    required this.plan,
    this.isPos = false,
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
              isTrial
                  ? 'You are on a Free Trial'
                  : isPos
                  ? 'POS subscription active'
                  : 'Current plan: $plan',
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
            child: Text(
              isPos ? 'POS details' : 'Continue to ERP',
              style: const TextStyle(fontSize: 12),
            ),
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
// CUSTOM PLAN CONTACT FOOTER
// ═══════════════════════════════════════════════════════════════════

class _CustomPlanContactFooter extends StatelessWidget {
  const _CustomPlanContactFooter();

  Future<void> _launch(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Need a custom plan?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF525252),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Contact BisonsTechs directly — we\'ll discuss features and pricing.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFFA3A3A3), height: 1.4),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () => _launch(Uri.parse('mailto:$_plansContactEmail')),
              onLongPress: () {
                Clipboard.setData(const ClipboardData(text: _plansContactEmail));
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.email_outlined, size: 16, color: kPrimary),
                  SizedBox(width: 6),
                  Text(
                    _plansContactEmail,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _launch(Uri.parse('tel:$_plansContactPhoneTel')),
              onLongPress: () {
                Clipboard.setData(const ClipboardData(text: _plansContactPhone));
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: kPrimary),
                  SizedBox(width: 6),
                  Text(
                    _plansContactPhone,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
