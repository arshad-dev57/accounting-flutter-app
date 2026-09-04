import 'package:BisonsTechs_app/Services/play_billing_service.dart';
import 'package:BisonsTechs_app/Services/subscription_service.dart';
import 'package:BisonsTechs_app/config/store_compliance.dart';
import 'package:BisonsTechs_app/core/plans/models/company_billing.dart';
import 'package:BisonsTechs_app/core/plans/utils/play_product_ids.dart';
import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';
import 'package:BisonsTechs_app/core/plans/views/Subscription_plans.dart';
import 'package:BisonsTechs_app/core/plans/views/pos_active_screen.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SubscriptionController extends GetxController {
  final SubscriptionService _subscriptionService = SubscriptionService();

  var isLoading = false.obs;
  var isCheckingStatus = false.obs;
  var hasActiveSubscription = false.obs;
  var subscriptionPlan = ''.obs;
  var subscriptionStatus = ''.obs;
  var trialDaysRemaining = 0.obs;
  var subscriptionDaysRemaining = 0.obs;
  var isTrialActive = false.obs;
  var trialEndDate = DateTime.now().obs;
  var subscriptionEndDate = DateTime.now().obs;
  var productTier = tierErpPos.obs;
  var capacitySnapshot = Rxn<SubscriptionCapacity>();
  var trialEligible = false.obs;
  var plans = <Map<String, dynamic>>[].obs;

  /// Flag to prevent re-check right after a successful subscription action
  var justSubscribed = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Prefs are for UI labels only. Access is always re-checked via API on splash/login.
    _loadFromPrefs();
    loadPlans();
  }

  // ─── Load cached values from SharedPreferences ─────────────────
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    hasActiveSubscription.value =
        prefs.getBool('has_active_subscription') ?? false;
    subscriptionPlan.value = prefs.getString('subscription_plan') ?? 'none';
    productTier.value = prefs.getString('product_tier') ?? tierErpPos;
    trialDaysRemaining.value = prefs.getInt('trial_days_remaining') ?? 0;
    subscriptionDaysRemaining.value =
        prefs.getInt('subscription_days_remaining') ?? 0;
    isTrialActive.value = prefs.getBool('is_trial_active') ?? false;
  }

  // ─── Check subscription status from backend ─────────────────────
  /// Live API check. Returns true when the server responded successfully.
  Future<bool> checkSubscriptionStatus() async {
    if (justSubscribed.value) {
      return hasAccess;
    }

    try {
      isCheckingStatus.value = true;

      final response = await _subscriptionService.checkSubscription();

      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          _applySubscriptionData(data);
        }
        await _saveSubscriptionStatus();
        _showTrialExpiryWarning();
        // Refresh capacity in background — don't block splash / plans UI.
        unawaited(_refreshCapacityQuietly());
        return true;
      }

      hasActiveSubscription.value = false;
      await _saveSubscriptionStatus();
      return false;
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      hasActiveSubscription.value = false;
      return false;
    } finally {
      isCheckingStatus.value = false;
    }
  }

  // ─── Apply subscription data map to observables ─────────────────
  void _applySubscriptionData(Map<String, dynamic> data) {
    final sub = data['subscription'] as Map<String, dynamic>? ?? {};

    hasActiveSubscription.value = data['hasAccess'] ?? false;
    trialEligible.value = data['trialEligible'] == true;
    subscriptionPlan.value = sub['plan'] ?? 'none';
    subscriptionStatus.value = sub['status'] ?? 'none';
    trialDaysRemaining.value = sub['trialDaysRemaining'] ?? 0;
    subscriptionDaysRemaining.value = sub['subscriptionDaysRemaining'] ?? 0;

    isTrialActive.value =
        (subscriptionPlan.value == 'trial' &&
        trialDaysRemaining.value > 0 &&
        hasActiveSubscription.value);

    if (sub['trialEndDate'] != null) {
      trialEndDate.value = DateTime.parse(sub['trialEndDate']);
    }
    if (sub['endDate'] != null) {
      subscriptionEndDate.value = DateTime.parse(sub['endDate']);
    }
    if (data['productTier'] != null) {
      productTier.value = data['productTier'].toString();
    } else if (sub['productTier'] != null) {
      productTier.value = sub['productTier'].toString();
    }
  }

  Future<void> _refreshCapacityQuietly() async {
    final cap = await fetchCapacity();
    if (cap != null) {
      capacitySnapshot.value = cap;
      productTier.value = cap.productTier;
    }
  }

  // ─── Update from user data (called after login) ─────────────────
  void updateFromUserData(Map<String, dynamic> userData) {
    final subscription = userData['subscription'];
    if (subscription == null) return;

    final plan = subscription['plan'] ?? 'none';
    final status = subscription['status'] ?? 'none';
    final trialDays = subscription['trialDaysRemaining'] ?? 0;
    final subDays = subscription['subscriptionDaysRemaining'] ?? 0;

    subscriptionPlan.value = plan;
    subscriptionStatus.value = status;
    trialDaysRemaining.value = trialDays;
    subscriptionDaysRemaining.value = subDays;
    hasActiveSubscription.value = (status == 'active');
    isTrialActive.value =
        (plan == 'trial' && trialDays > 0 && status == 'active');

    if (subscription['trialEndDate'] != null) {
      trialEndDate.value = DateTime.parse(subscription['trialEndDate']);
    }
    if (subscription['endDate'] != null) {
      subscriptionEndDate.value = DateTime.parse(subscription['endDate']);
    }

    _saveSubscriptionStatus();
  }

  // ─── Show warning snackbar when trial is expiring soon ──────────
  void _showTrialExpiryWarning() {
    if (isTrialActive.value &&
        trialDaysRemaining.value <= 3 &&
        trialDaysRemaining.value > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        AppSnackbar.error(
          kWarning,
          '⚠️ Trial Expiring Soon',
          'Your ${trialDaysRemaining.value}-day trial ends soon. Subscribe now!',
        );
      });
    }
  }

  // ─── Load available plans from backend ──────────────────────────
  Future<void> loadPlans() async {
    try {
      // Do not touch [isLoading] — splash / plan screen use that for status checks.
      final response = await _subscriptionService.getPlans();
      if (response['success'] != true) return;

      final data = response['data'];
      final raw = data is List
          ? data
          : (data is Map && data['plans'] is List)
              ? data['plans'] as List
              : const <dynamic>[];

      plans.value = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint('Error loading plans: $e');
    }
  }

  // ─── Start 14-day free trial ─────────────────────────────────────
  Future<bool> startTrial() async {
    try {
      isLoading.value = true;

      final response = await _subscriptionService.startTrial();

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};

        hasActiveSubscription.value = true;
        subscriptionPlan.value = 'trial';
        subscriptionStatus.value = 'active';
        trialDaysRemaining.value = data['trialDaysRemaining'] ?? trialDays;
        subscriptionDaysRemaining.value = 0;
        isTrialActive.value = true;
        trialEligible.value = false;

        if (data['trialEndDate'] != null) {
          trialEndDate.value = DateTime.parse(data['trialEndDate']);
        }

        await _saveSubscriptionStatus();

        AppSnackbar.success(
          kSuccess,
          '🎉 Trial Started!',
          '$trialDays-day free trial activated. Enjoy all premium features!',
        );

        return true;
      } else {
        AppSnackbar.error(
          kDanger,
          'Trial Error',
          response['message'] ?? 'Failed to start trial',
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.error(
        kDanger,
        'Error',
        'Something went wrong. Please try again.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Subscribe or upgrade (direct, no Stripe) ───────────────────
  Future<bool> subscribe(
    String plan,
    double amount, {
    String productTier = tierErpPos,
    int licensedUsers = 1,
    int licensedBranches = 1,
    bool isUpgrade = false,
  }) async {
    if (StoreCompliance.mustChargeViaPlay) {
      return _subscribeWithPlay(
        plan: plan,
        productTier: productTier,
      );
    }
    if (await StoreCompliance.redirectPaidCheckoutIfRequired()) {
      return false;
    }
    try {
      isLoading.value = true;
      justSubscribed.value = true;

      final response = isUpgrade
          ? await _subscriptionService.upgradeSubscription(
              licensedUsers: licensedUsers,
              licensedBranches: licensedBranches,
              productTier: productTier,
              billingCycle: plan,
            )
          : await _subscriptionService.subscribeDirect(
              plan: plan,
              amount: amount,
              productTier: productTier,
              licensedUsers: licensedUsers,
              licensedBranches: licensedBranches,
            );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};

        // ✅ Update paid subscription state
        hasActiveSubscription.value = true;
        subscriptionPlan.value = plan;
        subscriptionStatus.value = 'active';
        subscriptionDaysRemaining.value =
            data['subscriptionDaysRemaining'] ?? 0;

        // ✅ Reset trial state (user upgraded from trial to paid)
        isTrialActive.value = false;
        trialDaysRemaining.value = 0;

        final cap = data['capacity'];
        final capMap = cap is Map ? Map<String, dynamic>.from(cap) : null;
        final endRaw = data['endDate'] ?? capMap?['subscriptionEndDate'];
        if (endRaw != null) {
          final parsed = DateTime.tryParse(endRaw.toString());
          if (parsed != null) subscriptionEndDate.value = parsed;
        }
        final nextTier = data['productTier'] ?? capMap?['productTier'];
        if (nextTier != null) {
          this.productTier.value = nextTier.toString();
        } else {
          this.productTier.value = productTier;
        }
        unawaited(_refreshCapacityQuietly());

        await _saveSubscriptionStatus();
        justSubscribed.value = false;

        AppSnackbar.success(
          kSuccess,
          isUpgrade ? '✅ Updated!' : '✅ Subscribed!',
          isUpgrade
              ? 'Your subscription was updated successfully.'
              : 'Your ${plan == 'monthly' ? 'Monthly' : 'Yearly'} plan is now active!',
        );

        isLoading.value = false;
        return true;
      } else {
        justSubscribed.value = false;
        AppSnackbar.error(
          kDanger,
          'Subscription Failed',
          response['message'] ?? 'Failed to activate subscription',
        );
        isLoading.value = false;
        return false;
      }
    } catch (e) {
      justSubscribed.value = false;
      isLoading.value = false;
      AppSnackbar.error(
        kDanger,
        'Error',
        'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> _subscribeWithPlay({
    required String plan,
    required String productTier,
  }) async {
    try {
      isLoading.value = true;
      justSubscribed.value = true;
      final productId = PlayProductIds.fromSelection(productTier, plan);
      final play = await PlayBillingService.instance.buy(productId);
      if (play.canceled) {
        justSubscribed.value = false;
        isLoading.value = false;
        return false;
      }
      if (!play.success ||
          play.purchaseToken == null ||
          play.productId == null) {
        justSubscribed.value = false;
        isLoading.value = false;
        AppSnackbar.error(
          kDanger,
          'Purchase failed',
          play.message ?? 'Google Play purchase did not complete.',
        );
        return false;
      }

      final response = await _subscriptionService.verifyGooglePlayPurchase(
        purchaseToken: play.purchaseToken!,
        productId: play.productId!,
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};
        hasActiveSubscription.value = true;
        subscriptionPlan.value = plan;
        subscriptionStatus.value = 'active';
        subscriptionDaysRemaining.value =
            data['subscriptionDaysRemaining'] ?? 0;
        isTrialActive.value = false;
        trialDaysRemaining.value = 0;
        final parsed = PlayProductIds.parse(play.productId!);
        this.productTier.value = parsed.tier;
        unawaited(_refreshCapacityQuietly());
        await _saveSubscriptionStatus();
        justSubscribed.value = false;
        AppSnackbar.success(
          kSuccess,
          'Subscribed',
          'Your Google Play subscription is now active.',
        );
        isLoading.value = false;
        return true;
      }

      justSubscribed.value = false;
      isLoading.value = false;
      AppSnackbar.error(
        kDanger,
        'Verification failed',
        response['message'] ??
            'Payment succeeded but we could not activate the plan. Contact support.',
      );
      return false;
    } catch (e) {
      justSubscribed.value = false;
      isLoading.value = false;
      AppSnackbar.error(kDanger, 'Error', 'Google Play purchase failed.');
      return false;
    }
  }

  // ─── Cancel active subscription ──────────────────────────────────
  Future<void> cancelSubscription() async {
    if (StoreCompliance.usesPlayBilling) {
      await StoreCompliance.openPlaySubscriptionManagement();
      AppSnackbar.info(
        'Manage in Google Play',
        'Cancel or change auto-renew from Google Play. Access continues until the current period ends.',
      );
      return;
    }
    try {
      isLoading.value = true;
      final response = await _subscriptionService.cancelSubscription();

      if (response['success'] == true) {
        justSubscribed.value = false;
        hasActiveSubscription.value = false;
        subscriptionPlan.value = 'none';
        subscriptionStatus.value = 'expired';
        isTrialActive.value = false;
        trialDaysRemaining.value = 0;
        subscriptionDaysRemaining.value = 0;
        productTier.value = tierErpPos;
        capacitySnapshot.value = null;
        await _saveSubscriptionStatus();

        AppSnackbar.success(
          kSuccess,
          'Cancelled',
          'Subscription cancelled successfully',
        );

        Get.offAll(() => const SelectPlanScreen());
      } else {
        AppSnackbar.error(
          kDanger,
          'Error',
          response['message'] ?? 'Failed to cancel subscription',
        );
      }
    } catch (e) {
      AppSnackbar.error(
        kDanger,
        'Error',
        'Something went wrong. Please try again.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> upgradeSubscription({
    required int licensedUsers,
    required int licensedBranches,
  }) async {
    if (StoreCompliance.mustChargeViaPlay) {
      AppSnackbar.info(
        'Google Play',
        'Extra users and branches are not separate Play products yet. Change POS / ERP plan from the subscription screen.',
      );
      return false;
    }
    if (await StoreCompliance.redirectPaidCheckoutIfRequired()) {
      return false;
    }
    try {
      isLoading.value = true;
      final response = await _subscriptionService.upgradeSubscription(
        licensedUsers: licensedUsers,
        licensedBranches: licensedBranches,
      );
      if (response['success'] == true) return true;
      AppSnackbar.error(
        kDanger,
        'Upgrade Failed',
        response['message'] ?? 'Failed to upgrade subscription',
      );
      return false;
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'Something went wrong.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<SubscriptionCapacity?> fetchCapacity() async {
    try {
      final response = await _subscriptionService.fetchCapacity();
      if (response['success'] != true || response['data'] == null) return null;
      final data = response['data'];
      if (data is! Map<String, dynamic>) return null;
      final cap = SubscriptionCapacity.fromJson(data);
      capacitySnapshot.value = cap;
      productTier.value = cap.productTier;
      return cap;
    } catch (_) {
      return null;
    }
  }

  Future<CompanyBilling?> fetchCompanyBilling() async {
    try {
      isLoading.value = true;
      final response = await _subscriptionService.fetchCompanyBilling();
      if (response['success'] != true || response['data'] == null) return null;
      final data = response['data'];
      if (data is! Map<String, dynamic>) return null;
      final billing = CompanyBilling.fromJson(data);
      capacitySnapshot.value = billing.capacity;
      productTier.value = billing.capacity.productTier;
      return billing;
    } catch (_) {
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Computed helpers ────────────────────────────────────────────

  String getTrialStatusText() {
    if (isTrialActive.value) {
      if (trialDaysRemaining.value == trialDays) {
        return '🎉 $trialDays-Day Free Trial Started!';
      }
      if (trialDaysRemaining.value <= 3) {
        return '⚠️ Trial ends in ${trialDaysRemaining.value} day(s)!';
      }
      return '✨ ${trialDaysRemaining.value} days left in free trial';
    } else if (subscriptionPlan.value != 'none' &&
        subscriptionPlan.value != 'trial' &&
        hasActiveSubscription.value) {
      if (subscriptionDaysRemaining.value > 0) {
        return '📅 ${subscriptionDaysRemaining.value} days remaining';
      }
    }
    return 'Subscription expired';
  }

  double getTrialProgress() {
    if (!isTrialActive.value) return 1.0;
    if (trialDaysRemaining.value <= 0) return 1.0;
    return ((trialDays - trialDaysRemaining.value) / trialDays)
        .clamp(0.0, 1.0);
  }

  bool get hasAccess => hasActiveSubscription.value;

  bool get hasPosSubscription =>
      hasActiveSubscription.value &&
      !isTrialActive.value &&
      productTier.value == tierPos;

  bool get hasErpSubscription =>
      hasActiveSubscription.value &&
      (isTrialActive.value || productTier.value == tierErpPos);

  /// POS-only paid plan — no ERP module access.
  bool get isPosOnly => hasPosSubscription;

  bool get onTrial => isTrialActive.value;

  /// Route after login / splash when subscription is active.
  void goToAppHome({bool offAll = true}) {
    if (!hasAccess) {
      if (offAll) {
        Get.offAll(() => const SelectPlanScreen());
      } else {
        Get.to(() => const SelectPlanScreen());
      }
      return;
    }
    if (isPosOnly) {
      if (offAll) {
        Get.offAll(() => const PosActiveScreen());
      } else {
        Get.to(() => const PosActiveScreen());
      }
      return;
    }
    if (offAll) {
      Get.offAllNamed('/dashboard');
    } else {
      Get.toNamed('/dashboard');
    }
  }

  int get remainingDays {
    if (isTrialActive.value && trialDaysRemaining.value > 0) {
      return trialDaysRemaining.value;
    }
    if (subscriptionDaysRemaining.value > 0) {
      return subscriptionDaysRemaining.value;
    }
    return 0;
  }

  String get trialDaysText {
    if (trialDaysRemaining.value > 0) {
      return '${trialDaysRemaining.value} days remaining in trial';
    }
    return 'Trial expired';
  }

  String get subscriptionDaysText {
    if (subscriptionDaysRemaining.value > 0) {
      return '${subscriptionDaysRemaining.value} days remaining';
    }
    return 'Subscription expired';
  }

  // ─── Persist key values to SharedPreferences ────────────────────
  Future<void> _saveSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_active_subscription', hasActiveSubscription.value);
    await prefs.setString('subscription_plan', subscriptionPlan.value);
    await prefs.setInt('trial_days_remaining', trialDaysRemaining.value);
    await prefs.setInt(
      'subscription_days_remaining',
      subscriptionDaysRemaining.value,
    );
    await prefs.setBool('is_trial_active', isTrialActive.value);
    await prefs.setString('product_tier', productTier.value);
  }
}
