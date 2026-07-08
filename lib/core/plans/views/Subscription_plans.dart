import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/responsive_utils.dart';
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

  // Currently selected plan id from backend (e.g. 'monthly' or 'yearly')
  String _selectedPlanId = 'monthly';
  bool _isProcessing = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Load plans from backend if not already loaded
    if (_subCtrl.plans.isEmpty) {
      _subCtrl.loadPlans().then((_) {
        // Auto-select first plan after load
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

  // ── Get selected plan map from backend data ──
  Map<String, dynamic> get _selectedPlan {
    return _subCtrl.plans.firstWhere(
      (p) => (p['id'] ?? '') == _selectedPlanId,
      orElse: () => _subCtrl.plans.isNotEmpty ? _subCtrl.plans[0] : {},
    );
  }

  // ── Subscribe handler ──
  Future<void> _handleSubscription() async {
    if (_selectedPlan.isEmpty) return;

    setState(() => _isProcessing = true);

    final planId = _selectedPlan['id'] as String;
    final amount = (_selectedPlan['price'] as num).toDouble();

    _showLoadingDialog();
    final success = await _subCtrl.subscribe(planId, amount);
    if (mounted) Navigator.pop(context);

    if (success) {
      Get.offAll(() => const DashboardScreen());
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  // ── Upgrade from trial handler ──
  Future<void> _handleUpgradeFromTrial() async {
    // Get first paid plan (monthly or yearly)
    if (_subCtrl.plans.isEmpty) {
      await _subCtrl.loadPlans();
    }
    
    final paidPlan = _subCtrl.plans.firstWhere(
      (p) => p['id'] != 'trial',
      orElse: () => {},
    );
    
    if (paidPlan.isEmpty) return;
    
    setState(() => _isProcessing = true);
    
    final planId = paidPlan['id'] as String;
    final amount = (paidPlan['price'] as num).toDouble();
    
    _showLoadingDialog();
    final success = await _subCtrl.subscribe(planId, amount);
    if (mounted) Navigator.pop(context);
    
    if (success) {
      Get.offAll(() => const DashboardScreen());
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  void _showLoadingDialog() {
    final isWeb = ResponsiveUtils.isWeb(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Center(
            child: LoadingAnimationWidget.discreteCircle(
              color: kPrimary,
              size: ResponsiveUtils.isWeb(context) ? 32 : 40,
            ),
          )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveUtils.isWeb(context);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
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
    );
  }

  Widget _buildTopBar() {
    final isWeb = ResponsiveUtils.isWeb(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16, vertical: isWeb ? 16 : 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(isWeb ? 12 : 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: isWeb ? 24 : 20),
            ),
          ),
          SizedBox(width: isWeb ? 16 : 12),
          Text(
            _subCtrl.hasAccess ? 'My Subscription' : 'Select a Plan',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 24 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscriptionView() {
    final isWeb = ResponsiveUtils.isWeb(context);
    final plan = _subCtrl.subscriptionPlan.value;
    final status = _subCtrl.subscriptionStatus.value;
    final isTrial = _subCtrl.isTrialActive.value;
    final daysLeft = _subCtrl.remainingDays;
    final totalDays = isTrial ? 30 : (plan == 'yearly' ? 365 : 30);
    final progress = daysLeft <= 0 ? 1.0 : (daysLeft / totalDays).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
      child: Column(
        children: [
          SizedBox(height: isWeb ? 16 : 12),

          // ── Hero card ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isWeb ? 32 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTrial
                    ? [const Color(0xFF1565C0), const Color(0xFF1E88E5)]
                    : [const Color(0xFF0D7C3D), const Color(0xFF1AB45A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
              boxShadow: [
                BoxShadow(
                  color: (isTrial
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF0D7C3D))
                      .withOpacity(0.35),
                  blurRadius: isWeb ? 24 : 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isWeb ? 16 : 12, vertical: isWeb ? 8 : 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isWeb ? 40 : 30),
                  ),
                  child: Text(
                    isTrial ? '🎯 Free Trial' : '⭐ Premium Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWeb ? 14 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: isWeb ? 20 : 16),

                // Plan name
                Text(
                  _getPlanDisplayName(plan, isTrial),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isWeb ? 26 : 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: isWeb ? 8 : 6),

                // Status dot
                Row(
                  children: [
                    Container(
                      width: isWeb ? 10 : 8,
                      height: isWeb ? 10 : 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF76FF9A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: isWeb ? 8 : 6),
                    Text(
                      _capitalize(status),
                      style: TextStyle(
                        color: const Color(0xFFB2FFD0),
                        fontSize: isWeb ? 14 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isWeb ? 24 : 20),

                // Days + progress bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$daysLeft days remaining',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWeb ? 15 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$totalDays day plan',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: isWeb ? 13 : 12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isWeb ? 8 : 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: isWeb ? 10 : 8,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF76FF9A)),
                  ),
                ),

                // End date
                SizedBox(height: isWeb ? 20 : 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: Colors.white.withOpacity(0.7), size: isWeb ? 18 : 14),
                    SizedBox(width: isWeb ? 8 : 6),
                    Text(
                      isTrial
                          ? 'Trial ends: ${_formatDate(_subCtrl.trialEndDate.value)}'
                          : 'Renews: ${_formatDate(_subCtrl.subscriptionEndDate.value)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: isWeb ? 13 : 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: isWeb ? 24 : 20),

          // ── Trial upgrade nudge ──
          if (isTrial) ...[
            _buildUpgradeNudge(),
            SizedBox(height: isWeb ? 20 : 16),
          ],
          _buildActivePlanFeaturesCard(plan),

          SizedBox(height: isWeb ? 24 : 20),
          if (!isTrial)
            GestureDetector(
              onTap: _showCancelDialog,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: isWeb ? 18 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Text(
                  'Cancel Subscription',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: isWeb ? 15 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          SizedBox(height: isWeb ? 32 : 24),
        ],
      ),
    );
  }

  String _getPlanDisplayName(String planId, bool isTrial) {
    if (isTrial) return 'LedgerPro Pro — Trial';
    final match = _subCtrl.plans.firstWhere(
      (p) => (p['id'] ?? '') == planId,
      orElse: () => {},
    );
    if (match.isNotEmpty) return match['name'] ?? 'LedgerPro Pro';
    return 'LedgerPro Pro — ${_capitalize(planId)}';
  }

  Widget _buildUpgradeNudge() {
    final isWeb = ResponsiveUtils.isWeb(context);
    final days = _subCtrl.trialDaysRemaining.value;
    final isUrgent = days <= 5;

    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        color: isUrgent ? const Color(0xFFFFF3E0) : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFFB74D) : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Text(isUrgent ? '⚠️' : '💡', style: TextStyle(fontSize: isWeb ? 26 : 22)),
          SizedBox(width: isWeb ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent ? 'Trial ends in $days days!' : 'Enjoying your trial?',
                  style: TextStyle(
                    fontSize: isWeb ? 15 : 13,
                    fontWeight: FontWeight.w700,
                    color: isUrgent ? const Color(0xFFE65100) : const Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: isWeb ? 4 : 2),
                Text(
                  'Subscribe now to keep all premium features.',
                  style: TextStyle(fontSize: isWeb ? 13 : 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(width: isWeb ? 12 : 8),
          InkWell(
            onTap: _handleUpgradeFromTrial,
            borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 16, vertical: isWeb ? 12 : 10),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
              ),
              child: Text(
                'Upgrade',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWeb ? 14 : 12,
                  fontWeight: FontWeight.w600,
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
            'Data backup',
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
            blurRadius: isWeb ? 24 : 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: kPrimary, size: isWeb ? 28 : 24),
              SizedBox(width: isWeb ? 12 : 8),
              Text(
                'Your Plan Includes',
                style: TextStyle(
                  fontSize: isWeb ? 18 : 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          SizedBox(height: isWeb ? 20 : 16),
          ...features.map((f) => _buildFeatureTile(f)),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    final isWeb = ResponsiveUtils.isWeb(context);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 16 : 12)),
        title: const Text('Cancel Subscription', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure? You will lose access at the end of your billing period.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Keep Plan')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Get.back();
              _subCtrl.cancelSubscription();
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // VIEW 2 — PLANS LIST (no active subscription)
  // ═══════════════════════════════════════════════════

  Widget _buildPlansView() {
    final isWeb = ResponsiveUtils.isWeb(context);
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
      child: Column(
        children: [
          SizedBox(height: isWeb ? 24 : 16),

          // Loading spinner
          if (_subCtrl.isLoading.value && _subCtrl.plans.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: isWeb ? 120 : 80),
              child: Center(
                child: LoadingAnimationWidget.waveDots(
                  color: Colors.white,
                  size: isWeb ? 60 : 40,
                ),
              ),
            )

          // Error / empty state with retry
          else if (_subCtrl.plans.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: isWeb ? 80 : 60),
              child: Column(
                children: [
                  Icon(Icons.subscriptions, color: Colors.white54, size: isWeb ? 80 : 64),
                  SizedBox(height: isWeb ? 20 : 16),
                  Text(
                    'No plans Available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: isWeb ? 15 : 13),
                  ),
                  SizedBox(height: isWeb ? 20 : 16),
                  ElevatedButton(
                    onPressed: () => _subCtrl.loadPlans(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    child: Text('Retry', style: TextStyle(color: kPrimary)),
                  ),
                ],
              ),
            )

          // Plans loaded
          else ...[
            // Trial banner
            if (_subCtrl.trialDaysRemaining.value > 0) ...[
              _buildTrialBanner(),
              SizedBox(height: isWeb ? 24 : 16),
            ],

            // Tab selector
            _buildPlanTabs(),
            SizedBox(height: isWeb ? 24 : 16),

            // Selected plan detail card
            _buildSelectedPlanCard(),
            SizedBox(height: isWeb ? 24 : 16),

            // Footer
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(isWeb ? 40 : 32),
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
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 16 : 12, vertical: isWeb ? 12 : 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(isWeb ? 32 : 24),
                ),
                child: Column(
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? kPrimary : Colors.white,
                        fontSize: isWeb ? 15 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isPopular) ...[
                      SizedBox(height: isWeb ? 4 : 2),
                      Text(
                        '⭐ Popular',
                        style: TextStyle(
                          fontSize: isWeb ? 10 : 8,
                          color: isSelected ? Colors.orange : Colors.white70,
                          fontWeight: FontWeight.w500,
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
    final currency = plan['currency'] as String? ?? '\$';
    final duration = plan['duration'] as String? ?? '';
    final features = List<String>.from(plan['features'] ?? []);
    final savings = plan['savings'] as String?;
    final isPopular = plan['isPopular'] == true;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: isWeb ? 28 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 28 : 24),
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
                      fontSize: isWeb ? 22 : 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isWeb ? 16 : 12, vertical: isWeb ? 6 : 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE5B4),
                      borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                    ),
                    child: Text(
                      '⭐ Most Popular',
                      style: TextStyle(
                        fontSize: isWeb ? 11 : 10,
                        color: const Color(0xFF8B6914),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(height: isWeb ? 20 : 16),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency ${_formatPrice(price)}',
                  style: TextStyle(
                    fontSize: isWeb ? 36 : 30,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                    height: 1,
                  ),
                ),
                SizedBox(width: isWeb ? 12 : 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '/ $duration',
                    style: TextStyle(fontSize: isWeb ? 13 : 11, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),

            // Savings badge
            if (savings != null) ...[
              SizedBox(height: isWeb ? 12 : 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 16, vertical: isWeb ? 8 : 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4F5E2),
                  borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                ),
                child: Text(
                  savings,
                  style: TextStyle(
                    fontSize: isWeb ? 12 : 11,
                    color: const Color(0xFF1A6B45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            SizedBox(height: isWeb ? 28 : 24),
            Divider(color: Colors.grey[100]),
            SizedBox(height: isWeb ? 20 : 16),

            // Features header
            Row(
              children: [
                Icon(Icons.check_circle, color: kPrimary, size: isWeb ? 24 : 20),
                SizedBox(width: isWeb ? 12 : 8),
                Text(
                  'Plan includes',
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            SizedBox(height: isWeb ? 16 : 12),

            // Features list
            ...features.map((f) => _buildFeatureTile(f)),

            SizedBox(height: isWeb ? 20 : 16),

            // Subscribe button
            SizedBox(
              width: double.infinity,
              height: isWeb ? 60 : 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                  ),
                ),
                child: _isProcessing
                    ? SizedBox(
                        height: isWeb ? 28 : 24,
                        width: isWeb ? 28 : 24,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Start $name — $currency ${_formatPrice(price)}',
                        style: TextStyle(fontSize: isWeb ? 15 : 13, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            SizedBox(height: isWeb ? 12 : 10),
            Text(
              'Cancel anytime. Add-ons available upon request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isWeb ? 11 : 10, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrialBanner() {
    final isWeb = ResponsiveUtils.isWeb(context);
    
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isWeb ? 12 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isWeb ? 12 : 10),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
            ),
            child: Icon(Icons.celebration, color: kPrimary, size: isWeb ? 28 : 24),
          ),
          SizedBox(width: isWeb ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎉 ${_subCtrl.trialDaysRemaining.value} Days Free Trial Active!',
                  style: TextStyle(
                    fontSize: isWeb ? 15 : 13,
                    fontWeight: FontWeight.bold,
                    color: kPrimary,
                  ),
                ),
                SizedBox(height: isWeb ? 4 : 2),
                Text(
                  'Subscribe now to continue after trial ends',
                  style: TextStyle(fontSize: isWeb ? 12 : 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String text) {
    final isWeb = ResponsiveUtils.isWeb(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: isWeb ? 14 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: isWeb ? 20 : 18,
            height: isWeb ? 20 : 18,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: kPrimary, size: isWeb ? 13 : 11),
          ),
          SizedBox(width: isWeb ? 14 : 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isWeb ? 14 : 12,
                color: const Color(0xFF3D3D5C),
                height: 1.5,
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
              'Pricing plan and offer terms',
              style: TextStyle(
                color: Colors.white,
                fontSize: isWeb ? 14 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: isWeb ? 8 : 6),
            Container(
              width: isWeb ? 20 : 16,
              height: isWeb ? 20 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(Icons.info_outline, size: isWeb ? 12 : 10, color: Colors.white),
            ),
          ],
        ),
        SizedBox(height: isWeb ? 16 : 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 20 : 16,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            children: [
              TextSpan(text: 'Join over 4.6 million\nsubscribers'),
              WidgetSpan(
                child: Padding(
                  padding: EdgeInsets.only(left: isWeb ? 6 : 4, bottom: 2),
                  child: Icon(Icons.auto_awesome, color: const Color(0xFF7DDFF5), size: isWeb ? 20 : 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
    return price
        .toInt()
        .toString()
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}