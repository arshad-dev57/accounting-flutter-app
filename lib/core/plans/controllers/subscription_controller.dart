import 'package:LedgerPro_app/Services/subscription_service.dart';
import 'package:LedgerPro_app/core/plans/views/Subscription_plans.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionController extends GetxController {
  final SubscriptionService _subscriptionService = SubscriptionService();

  var isLoading = false.obs;
  var hasActiveSubscription = false.obs;
  var subscriptionPlan = ''.obs;
  var subscriptionStatus = ''.obs;
  var trialDaysRemaining = 0.obs;
  var subscriptionDaysRemaining = 0.obs;
  var isTrialActive = false.obs;
  var trialEndDate = DateTime.now().obs;
  var subscriptionEndDate = DateTime.now().obs;
  var plans = <Map<String, dynamic>>[].obs;

  /// Flag to prevent re-check right after a successful subscription action
  var justSubscribed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromPrefs().then((_) => checkSubscriptionStatus());
    loadPlans();
  }

  // ─── Load cached values from SharedPreferences ─────────────────
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    hasActiveSubscription.value =
        prefs.getBool('has_active_subscription') ?? false;
    subscriptionPlan.value = prefs.getString('subscription_plan') ?? 'none';
    trialDaysRemaining.value = prefs.getInt('trial_days_remaining') ?? 0;
    subscriptionDaysRemaining.value =
        prefs.getInt('subscription_days_remaining') ?? 0;
    isTrialActive.value = prefs.getBool('is_trial_active') ?? false;
  }

  // ─── Check subscription status from backend ─────────────────────
  Future<void> checkSubscriptionStatus() async {
    if (justSubscribed.value) {
      print('[SubscriptionController] Just subscribed — skipping status check');
      return;
    }

    try {
      isLoading.value = true;

      final response = await _subscriptionService.checkSubscription();

      if (response['success'] == true) {
        final data = response['data'];
        _applySubscriptionData(data);
        await _saveSubscriptionStatus();
        _showTrialExpiryWarning();
      }
    } catch (e) {
      print('[SubscriptionController] Error checking subscription: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Apply subscription data map to observables ─────────────────
  void _applySubscriptionData(Map<String, dynamic> data) {
    final sub = data['subscription'] as Map<String, dynamic>? ?? {};

    hasActiveSubscription.value = data['hasAccess'] ?? false;
    subscriptionPlan.value = sub['plan'] ?? 'none';
    subscriptionStatus.value = sub['status'] ?? 'none';
    trialDaysRemaining.value = sub['trialDaysRemaining'] ?? 0;
    subscriptionDaysRemaining.value = sub['subscriptionDaysRemaining'] ?? 0;

    isTrialActive.value = (subscriptionPlan.value == 'trial' &&
        trialDaysRemaining.value > 0 &&
        hasActiveSubscription.value);

    if (sub['trialEndDate'] != null) {
      trialEndDate.value = DateTime.parse(sub['trialEndDate']);
    }
    if (sub['endDate'] != null) {
      subscriptionEndDate.value = DateTime.parse(sub['endDate']);
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
      isLoading.value = true;
      final response = await _subscriptionService.getPlans();
      if (response['success'] == true) {
        plans.value =
            List<Map<String, dynamic>>.from(response['data'] as List);
      }
    } catch (e) {
      print('[SubscriptionController] Error loading plans: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Start 30-day free trial ─────────────────────────────────────
  Future<bool> startTrial() async {
    try {
      isLoading.value = true;

      final response = await _subscriptionService.startTrial();

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>? ?? {};

        hasActiveSubscription.value = true;
        subscriptionPlan.value = 'trial';
        subscriptionStatus.value = 'active';
        trialDaysRemaining.value = data['trialDaysRemaining'] ?? 30;
        subscriptionDaysRemaining.value = 0;
        isTrialActive.value = true;

        if (data['trialEndDate'] != null) {
          trialEndDate.value = DateTime.parse(data['trialEndDate']);
        }

        await _saveSubscriptionStatus();

        AppSnackbar.success(
          kSuccess,
          '🎉 Trial Started!',
          '30-day free trial activated. Enjoy all premium features!',
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
      AppSnackbar.error(kDanger, 'Error', 'Something went wrong. Please try again.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Subscribe to monthly or yearly plan (direct, no Stripe) ────
  Future<bool> subscribe(String plan, double amount) async {
    try {
      isLoading.value = true;
      justSubscribed.value = true;

      final response = await _subscriptionService.subscribeDirect(
        plan: plan,
        amount: amount,
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

        if (data['endDate'] != null) {
          subscriptionEndDate.value = DateTime.parse(data['endDate']);
        }

        await _saveSubscriptionStatus();

        AppSnackbar.success(
          kSuccess,
          '✅ Subscribed!',
          'Your ${plan == 'monthly' ? 'Monthly' : 'Yearly'} plan is now active!',
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
          kDanger, 'Error', 'Something went wrong. Please try again.');
      return false;
    }
  }

  // ─── Cancel active subscription ──────────────────────────────────
  Future<void> cancelSubscription() async {
    try {
      isLoading.value = true;
      final response = await _subscriptionService.cancelSubscription();

      if (response['success'] == true) {
        // ✅ Reset ALL subscription state
        hasActiveSubscription.value = false;
        subscriptionPlan.value = 'none';
        subscriptionStatus.value = 'expired';
        isTrialActive.value = false;
        trialDaysRemaining.value = 0;
        subscriptionDaysRemaining.value = 0;
        justSubscribed.value = false;

        await _saveSubscriptionStatus();

        AppSnackbar.success(
            kSuccess, 'Cancelled', 'Subscription cancelled successfully');

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
          kDanger, 'Error', 'Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Computed helpers ────────────────────────────────────────────

  String getTrialStatusText() {
    if (isTrialActive.value) {
      if (trialDaysRemaining.value == 30) return '🎉 30-Day Free Trial Started!';
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
    return ((30 - trialDaysRemaining.value) / 30).clamp(0.0, 1.0);
  }

  bool get hasAccess => hasActiveSubscription.value;
  bool get onTrial => isTrialActive.value;

  int get remainingDays {
    if (isTrialActive.value && trialDaysRemaining.value > 0) {
      return trialDaysRemaining.value;
    }
    if (subscriptionDaysRemaining.value > 0) return subscriptionDaysRemaining.value;
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
        'subscription_days_remaining', subscriptionDaysRemaining.value);
    await prefs.setBool('is_trial_active', isTrialActive.value);
  }
}