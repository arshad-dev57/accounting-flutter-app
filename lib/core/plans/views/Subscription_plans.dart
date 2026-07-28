import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:LedgerPro_app/core/dashboard/Screens/dashbaord_screen.dart';
import 'package:LedgerPro_app/core/plans/controllers/subscription_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SelectPlanScreen extends StatefulWidget {
  const SelectPlanScreen({super.key});

  @override
  State<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends State<SelectPlanScreen>
    with SingleTickerProviderStateMixin {
  final SubscriptionController _subCtrl = Get.put(SubscriptionController());

  String _selectedPlanId = 'monthly';
  bool _isProcessing = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
    );
    _fadeCtrl.forward();

    if (_subCtrl.plans.isEmpty) {
      _subCtrl.loadPlans().then((_) {
        if (_subCtrl.plans.isNotEmpty && mounted) {
          setState(() {
            _selectedPlanId = _subCtrl.plans[0]['id'] ?? 'monthly';
          });
        }
      });
    } else {
      _selectedPlanId = _subCtrl.plans[0]['id'] ?? 'monthly';
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _selectedPlan {
    return _subCtrl.plans.firstWhere(
      (p) => (p['id'] ?? '') == _selectedPlanId,
      orElse: () => _subCtrl.plans.isNotEmpty ? _subCtrl.plans[0] : {},
    );
  }

  // ─── Start 30-day free trial ─────────────────────────────────────
  Future<void> _handleStartTrial() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    _showLoadingDialog('Starting your 30-day free trial...');

    final success = await _subCtrl.startTrial();

    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      Get.offAll(() => const DashboardScreen());
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  // ─── Subscribe to selected paid plan ─────────────────────────────
  Future<void> _handleSubscription() async {
    if (_selectedPlan.isEmpty || _isProcessing) return;
    setState(() => _isProcessing = true);

    final planId = _selectedPlan['id'] as String;
    final amount = (_selectedPlan['price'] as num).toDouble();

    _showLoadingDialog('Activating your subscription...');

    final success = await _subCtrl.subscribe(planId, amount);

    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      Get.offAll(() => const DashboardScreen());
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  // ─── Upgrade from trial to selected paid plan ────────────────────
  Future<void> _handleUpgradeFromTrial() async {
    if (_isProcessing) return;

    // Ensure plans are loaded
    if (_subCtrl.plans.isEmpty) {
      await _subCtrl.loadPlans();
    }

    // Default to monthly when upgrading from trial
    final targetPlanId = _selectedPlanId.isNotEmpty ? _selectedPlanId : 'monthly';
    final paidPlan = _subCtrl.plans.firstWhere(
      (p) => p['id'] == targetPlanId,
      orElse: () => _subCtrl.plans.isNotEmpty ? _subCtrl.plans[0] : {},
    );

    if (paidPlan.isEmpty) return;

    setState(() => _isProcessing = true);

    final planId = paidPlan['id'] as String;
    final amount = (paidPlan['price'] as num).toDouble();

    _showLoadingDialog('Upgrading your plan...');

    final success = await _subCtrl.subscribe(planId, amount);

    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      Get.offAll(() => const DashboardScreen());
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingAnimationWidget.waveDots(
                color: kPrimary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Please wait a moment',
                style: TextStyle(fontSize: 12, color: kSubText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF1A1A3E),
              Color(0xFF2D1B4E),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim.drive(Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              )),
              child: Obx(() {
                return Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: _subCtrl.hasAccess
                          ? _buildActiveSubscriptionView()
                          : _buildPlansView(),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 32 : 20,
        vertical: isWeb ? 20 : 16,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(isWeb ? 12 : 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: isWeb ? 22 : 18,
              ),
            ),
          ),
          SizedBox(width: isWeb ? 16 : 12),
          Text(
            _subCtrl.hasAccess ? 'My Subscription' : 'Choose Your Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 26 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (_subCtrl.hasAccess)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 14 : 10,
                vertical: isWeb ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: kSuccess.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: kSuccess.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: kSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: isWeb ? 8 : 6),
                  Text(
                    'Active',
                    style: TextStyle(
                      color: kSuccess,
                      fontSize: isWeb ? 12 : 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIVE SUBSCRIPTION VIEW
  // Shown when user has trial OR paid subscription active
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActiveSubscriptionView() {
    final isWeb = ResponsiveUtils.isWeb(context);
    final plan = _subCtrl.subscriptionPlan.value;
    final status = _subCtrl.subscriptionStatus.value;
    final isTrial = _subCtrl.isTrialActive.value;
    final daysLeft = _subCtrl.remainingDays;
    final totalDays = isTrial ? 30 : (plan == 'yearly' ? 365 : 30);
    final progress =
        daysLeft <= 0 ? 1.0 : (daysLeft / totalDays).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 32 : 20,
        vertical: isWeb ? 8 : 4,
      ),
      child: Column(
        children: [
          // ── Hero Status Card ──
          _buildHeroCard(
              plan, status, isTrial, daysLeft, totalDays, progress, isWeb),

          SizedBox(height: isWeb ? 24 : 20),

          // ── Trial: Upgrade nudge with plan selection ──
          if (isTrial) ...[
            _buildUpgradeNudge(isWeb),
            SizedBox(height: isWeb ? 16 : 12),
            // Plan tabs so user can pick monthly or yearly before upgrading
            _buildPlanTabs(),
            SizedBox(height: isWeb ? 20 : 16),
          ],

          // ── What's Included ──
          _buildActivePlanFeaturesCard(plan),

          SizedBox(height: isWeb ? 24 : 20),

          // ── Cancel (only for paid subscriptions, not trial) ──
          if (!isTrial) ...[
            _buildCancelSubscriptionButton(),
            SizedBox(height: isWeb ? 16 : 12),
          ],

          // ── Footer ──
          _buildFooter(),

          SizedBox(height: isWeb ? 32 : 24),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String plan, String status, bool isTrial, int daysLeft,
      int totalDays, double progress, bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTrial
              ? [const Color(0xFF1A237E), const Color(0xFF283593)]
              : plan == 'yearly'
                  ? [const Color(0xFF4A148C), const Color(0xFF6A1B9A)]
                  : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: (isTrial
                    ? const Color(0xFF1A237E)
                    : plan == 'yearly'
                        ? const Color(0xFF4A148C)
                        : const Color(0xFF1B5E20))
                .withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isWeb ? 16 : 12,
              vertical: isWeb ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTrial ? Icons.celebration : Icons.star_rounded,
                  color: Colors.white,
                  size: isWeb ? 18 : 14,
                ),
                SizedBox(width: isWeb ? 8 : 6),
                Text(
                  isTrial ? 'Free Trial' : 'Premium Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWeb ? 13 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isWeb ? 20 : 16),

          // Plan name
          Text(
            _getPlanDisplayName(plan, isTrial),
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 28 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: isWeb ? 8 : 6),

          // Status dot
          Row(
            children: [
              Container(
                width: isWeb ? 10 : 8,
                height: isWeb ? 10 : 8,
                decoration: BoxDecoration(
                  color: isTrial ? Colors.amber : kSuccess,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: isWeb ? 8 : 6),
              Text(
                _capitalize(status),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isWeb ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: isWeb ? 24 : 20),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$daysLeft days remaining',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWeb ? 16 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$totalDays day plan',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: isWeb ? 13 : 11,
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 10 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: isWeb ? 8 : 6,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isTrial ? Colors.amber : kSuccess,
              ),
            ),
          ),

          // End / expiry date
          SizedBox(height: isWeb ? 20 : 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: Colors.white.withOpacity(0.6),
                size: isWeb ? 18 : 14,
              ),
              SizedBox(width: isWeb ? 8 : 6),
              Text(
                isTrial
                    ? 'Trial ends: ${_formatDate(_subCtrl.trialEndDate.value)}'
                    : 'Renews: ${_formatDate(_subCtrl.subscriptionEndDate.value)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: isWeb ? 13 : 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPlanDisplayName(String planId, bool isTrial) {
    if (isTrial) return '30-Day Free Trial';
    final match = _subCtrl.plans.firstWhere(
      (p) => (p['id'] ?? '') == planId,
      orElse: () => {},
    );
    if (match.isNotEmpty) return match['name'] ?? 'Pro Plan';
    return planId == 'yearly' ? 'Yearly Plan' : 'Monthly Plan';
  }

  // ─── Trial Upgrade Nudge ─────────────────────────────────────────

  Widget _buildUpgradeNudge(bool isWeb) {
    final days = _subCtrl.trialDaysRemaining.value;
    final isUrgent = days <= 5;

    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUrgent
              ? [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)]
              : [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.85)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFFFB74D)
              : Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isWeb ? 12 : 10),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? const Color(0xFFFFB74D).withOpacity(0.2)
                      : kPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  isUrgent ? '⏰' : '💡',
                  style: TextStyle(fontSize: isWeb ? 28 : 22),
                ),
              ),
              SizedBox(width: isWeb ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUrgent
                          ? 'Trial ends in $days day(s)!'
                          : 'Enjoying your free trial?',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        fontWeight: FontWeight.w700,
                        color: isUrgent
                            ? const Color(0xFFE65100)
                            : kText,
                      ),
                    ),
                    SizedBox(height: isWeb ? 4 : 2),
                    Text(
                      'Pick a plan below and upgrade to keep access',
                      style: TextStyle(
                        fontSize: isWeb ? 13 : 11,
                        color: isUrgent
                            ? const Color(0xFFBF360C)
                            : kSubText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 16 : 12),
          SizedBox(
            width: double.infinity,
            height: isWeb ? 48 : 44,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleUpgradeFromTrial,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.upgrade_rounded, size: 18),
              label: Text(
                _isProcessing ? 'Processing...' : 'Upgrade Now',
                style: TextStyle(
                  fontSize: isWeb ? 14 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePlanFeaturesCard(String planId) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final match = _subCtrl.plans.firstWhere(
      (p) => (p['id'] ?? '') == planId,
      orElse: () => {},
    );

    final List<String> features = match.isNotEmpty
        ? List<String>.from(match['features'] ?? [])
        : [
            'Full access to all features',
            'Unlimited transactions',
            'All financial reports',
            'Export to Excel/PDF',
            'Email support',
            'Data backup & security',
          ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 28 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isWeb ? 10 : 8),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: kPrimary,
                  size: isWeb ? 24 : 20,
                ),
              ),
              SizedBox(width: isWeb ? 14 : 10),
              Text(
                'What\'s Included',
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 20 : 16),
          ...features.map((f) => _buildFeatureTile(f, isWeb)),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String text, bool isWeb) {
    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 14 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: isWeb ? 22 : 18,
            height: isWeb ? 22 : 18,
            decoration: BoxDecoration(
              color: kSuccess.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: kSuccess,
              size: isWeb ? 14 : 12,
            ),
          ),
          SizedBox(width: isWeb ? 14 : 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                color: kText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Cancel Button ───────────────────────────────────────────────

  Widget _buildCancelSubscriptionButton() {
    final isWeb = ResponsiveUtils.isWeb(context);

    return GestureDetector(
      onTap: _showCancelDialog,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(isWeb ? 14 : 12),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cancel_outlined,
              color: Colors.red.withOpacity(0.7),
              size: isWeb ? 20 : 18,
            ),
            SizedBox(width: isWeb ? 10 : 8),
            Text(
              'Cancel Subscription',
              style: TextStyle(
                color: Colors.red.withOpacity(0.7),
                fontSize: isWeb ? 15 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    final isWeb = ResponsiveUtils.isWeb(context);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        ),
        child: Container(
          padding: EdgeInsets.all(isWeb ? 28 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isWeb ? 16 : 14),
                decoration: BoxDecoration(
                  color: kDanger.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: kDanger,
                  size: isWeb ? 32 : 28,
                ),
              ),
              SizedBox(height: isWeb ? 16 : 14),
              Text(
                'Cancel Subscription?',
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              SizedBox(height: isWeb ? 8 : 6),
              Text(
                'You will immediately lose access to all premium features. '
                'This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWeb ? 13 : 12,
                  color: kSubText,
                  height: 1.5,
                ),
              ),
              SizedBox(height: isWeb ? 24 : 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: kBorder),
                        padding: EdgeInsets.symmetric(
                          vertical: isWeb ? 14 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                        ),
                      ),
                      child: Text(
                        'Keep Plan',
                        style: TextStyle(
                          fontSize: isWeb ? 13 : 12,
                          color: kText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isWeb ? 12 : 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _subCtrl.cancelSubscription();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kDanger,
                        padding: EdgeInsets.symmetric(
                          vertical: isWeb ? 14 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Yes, Cancel',
                        style: TextStyle(
                          fontSize: isWeb ? 13 : 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PLANS LIST VIEW
  // Shown when user has NO active subscription (plan = none / expired)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPlansView() {
    final isWeb = ResponsiveUtils.isWeb(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 32 : 20),
      child: Column(
        children: [
          SizedBox(height: isWeb ? 12 : 8),

          // ── Subtitle ──
          Text(
            'Select the perfect plan for your business',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isWeb ? 16 : 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: isWeb ? 24 : 20),

          // ── 30-Day Free Trial Banner ──
          // Only shown when user never started a trial (plan = 'none')
          if (_subCtrl.subscriptionPlan.value == 'none' ||
              _subCtrl.subscriptionPlan.value.isEmpty) ...[
            _buildTrialBanner(),
            SizedBox(height: isWeb ? 24 : 20),
          ],

          // ── Loading ──
          if (_subCtrl.isLoading.value && _subCtrl.plans.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: isWeb ? 100 : 60),
              child: Column(
                children: [
                  LoadingAnimationWidget.waveDots(
                    color: Colors.white,
                    size: isWeb ? 60 : 40,
                  ),
                  SizedBox(height: isWeb ? 20 : 16),
                  Text(
                    'Loading plans...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: isWeb ? 15 : 13,
                    ),
                  ),
                ],
              ),
            )

          // ── Empty / Error ──
          else if (_subCtrl.plans.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: isWeb ? 80 : 50),
              child: Column(
                children: [
                  Icon(
                    Icons.subscriptions_outlined,
                    color: Colors.white.withOpacity(0.4),
                    size: isWeb ? 80 : 64,
                  ),
                  SizedBox(height: isWeb ? 20 : 16),
                  Text(
                    'No plans available',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: isWeb ? 15 : 13,
                    ),
                  ),
                  SizedBox(height: isWeb ? 20 : 16),
                  ElevatedButton(
                    onPressed: () => _subCtrl.loadPlans(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 32 : 24,
                        vertical: isWeb ? 14 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(isWeb ? 12 : 10),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: isWeb ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )

          // ── Plans ──
          else ...[
            _buildPlanTabs(),
            SizedBox(height: isWeb ? 24 : 20),
            _buildSelectedPlanCard(),
            SizedBox(height: isWeb ? 24 : 20),
            _buildFooter(),
          ],

          SizedBox(height: isWeb ? 32 : 24),
        ],
      ),
    );
  }

  Widget _buildPlanTabs() {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Container(
      padding: EdgeInsets.all(isWeb ? 6 : 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(isWeb ? 40 : 32),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: _subCtrl.plans.map((plan) {
          final id = plan['id'] as String? ?? '';
          final name = plan['name'] as String? ?? id;
          final isSelected = _selectedPlanId == id;
          final isPopular = plan['isPopular'] == true;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPlanId = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 20 : 14,
                  vertical: isWeb ? 14 : 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(isWeb ? 32 : 24),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? kText : Colors.white,
                        fontSize: isWeb ? 15 : 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (isPopular) ...[
                      SizedBox(height: isWeb ? 4 : 2),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWeb ? 10 : 8,
                          vertical: isWeb ? 2 : 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '⭐ Popular',
                          style: TextStyle(
                            fontSize: isWeb ? 10 : 8,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedPlanCard() {
    final isWeb = ResponsiveUtils.isWeb(context);
    final plan = _selectedPlan;
    if (plan.isEmpty) return const SizedBox.shrink();

    final name = plan['name'] as String? ?? 'Plan';
    final price = plan['price'] as num? ?? 0;
    final currency = plan['currency'] as String? ?? 'SAR';
    final duration = plan['duration'] as String? ?? 'month';
    final features = List<String>.from(plan['features'] ?? []);
    final savings = plan['savings'] as String?;
    final isPopular = plan['isPopular'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan name + popular badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: isWeb ? 24 : 20,
                      fontWeight: FontWeight.w800,
                      color: kText,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 16 : 12,
                      vertical: isWeb ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.shade400,
                          Colors.amber.shade600
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                    ),
                    child: Text(
                      '⭐ Best Value',
                      style: TextStyle(
                        fontSize: isWeb ? 11 : 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: isWeb ? 16 : 12),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency ${_formatPrice(price)}',
                  style: TextStyle(
                    fontSize: isWeb ? 40 : 32,
                    fontWeight: FontWeight.w800,
                    color: kText,
                    height: 1,
                  ),
                ),
                SizedBox(width: isWeb ? 12 : 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '/ $duration',
                    style: TextStyle(
                      fontSize: isWeb ? 14 : 12,
                      color: kSubText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            // Savings badge
            if (savings != null) ...[
              SizedBox(height: isWeb ? 12 : 10),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 16 : 14,
                  vertical: isWeb ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: kSuccess.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(isWeb ? 10 : 8),
                  border:
                      Border.all(color: kSuccess.withOpacity(0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.savings, color: kSuccess, size: isWeb ? 16 : 14),
                    SizedBox(width: isWeb ? 8 : 6),
                    Text(
                      savings,
                      style: TextStyle(
                        fontSize: isWeb ? 12 : 11,
                        color: kSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: isWeb ? 28 : 24),
            Divider(color: kBorder.withOpacity(0.5)),
            SizedBox(height: isWeb ? 20 : 16),

            // Features header
            Row(
              children: [
                Icon(Icons.check_circle, color: kPrimary, size: isWeb ? 22 : 18),
                SizedBox(width: isWeb ? 12 : 8),
                Text(
                  'Plan includes',
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
              ],
            ),
            SizedBox(height: isWeb ? 16 : 12),

            // Features list
            ...features.map((f) => _buildFeatureTile(f, isWeb)),

            SizedBox(height: isWeb ? 24 : 20),

            // ✅ Subscribe button — direct, no Stripe
            SizedBox(
              width: double.infinity,
              height: isWeb ? 56 : 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWeb ? 14 : 12),
                  ),
                ),
                child: _isProcessing
                    ? SizedBox(
                        height: isWeb ? 24 : 20,
                        width: isWeb ? 24 : 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Subscribe Now — $currency ${_formatPrice(price)}',
                        style: TextStyle(
                          fontSize: isWeb ? 15 : 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            SizedBox(height: isWeb ? 12 : 10),
            Center(
              child: Text(
                'Cancel anytime. No hidden charges.',
                style: TextStyle(
                  fontSize: isWeb ? 11 : 10,
                  color: kSubText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Trial Banner (shown to new users who haven't started trial) ─

  Widget _buildTrialBanner() {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade50, Colors.amber.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        border: Border.all(
          color: Colors.amber.shade300.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isWeb ? 12 : 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade200.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.celebration_rounded,
                  color: Colors.amber.shade800,
                  size: isWeb ? 28 : 22,
                ),
              ),
              SizedBox(width: isWeb ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 Try Free for 30 Days!',
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    SizedBox(height: isWeb ? 4 : 2),
                    Text(
                      'Full access to all premium features — no credit card needed',
                      style: TextStyle(
                        fontSize: isWeb ? 12 : 11,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 16 : 12),
          SizedBox(
            width: double.infinity,
            height: isWeb ? 48 : 44,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleStartTrial,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.rocket_launch_rounded, size: 18),
              label: Text(
                _isProcessing ? 'Starting...' : 'Start Free Trial',
                style: TextStyle(
                  fontSize: isWeb ? 14 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isWeb = ResponsiveUtils.isWeb(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Pricing plan and offer terms apply',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: isWeb ? 13 : 11,
              ),
            ),
            SizedBox(width: isWeb ? 8 : 6),
            Container(
              width: isWeb ? 20 : 16,
              height: isWeb ? 20 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.info_outline,
                size: isWeb ? 12 : 10,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
        SizedBox(height: isWeb ? 20 : 16),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 22 : 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
            children: [
              const TextSpan(text: 'Join over 4.6 million\n'),
              TextSpan(
                text: 'subscribers',
                style: const TextStyle(color: Color(0xFF7DDFF5)),
              ),
              WidgetSpan(
                child: Padding(
                  padding: EdgeInsets.only(left: isWeb ? 6 : 4),
                  child: Icon(
                    Icons.auto_awesome,
                    color: const Color(0xFF7DDFF5),
                    size: isWeb ? 20 : 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatPrice(num price) {
    return price.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}