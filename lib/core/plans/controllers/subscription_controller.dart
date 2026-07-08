import 'package:LedgerPro_app/Services/subscription_service.dart';
import 'package:LedgerPro_app/core/plans/views/Subscription_plans.dart';
import 'package:LedgerPro_app/Utils/colors.dart';
import 'package:LedgerPro_app/Utils/toast_utils.dart';
import 'package:flutter/foundation.dart';
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

  var justSubscribed = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromPrefs().then((_) => checkSubscriptionStatus());
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    hasActiveSubscription.value = prefs.getBool('has_active_subscription') ?? false;
    subscriptionPlan.value = prefs.getString('subscription_plan') ?? 'none';
    trialDaysRemaining.value = prefs.getInt('trial_days_remaining') ?? 0;
    isTrialActive.value = prefs.getBool('is_trial_active') ?? false;
  }

  Future<void> checkSubscriptionStatus() async {
    if (justSubscribed.value) {
      print('Just subscribed, skipping check...');
      return;
    }

    try {
      isLoading.value = true;

      final response = await _subscriptionService.checkSubscription();

      if (response['success'] == true) {
        final data = response['data'];
        hasActiveSubscription.value = data['hasAccess'] ?? false;
        subscriptionPlan.value = data['subscription']['plan'] ?? 'none';
        subscriptionStatus.value = data['subscription']['status'] ?? 'none';
        trialDaysRemaining.value = data['subscription']['trialDaysRemaining'] ?? 0;
        subscriptionDaysRemaining.value = data['subscription']['subscriptionDaysRemaining'] ?? 0;

        isTrialActive.value = (subscriptionPlan.value == 'trial' &&
            trialDaysRemaining.value > 0 &&
            hasActiveSubscription.value);

        if (data['subscription']['trialEndDate'] != null) {
          trialEndDate.value = DateTime.parse(data['subscription']['trialEndDate']);
        }
        if (data['subscription']['endDate'] != null) {
          subscriptionEndDate.value = DateTime.parse(data['subscription']['endDate']);
        }

        await _saveSubscriptionStatus();
        _showTrialExpiryWarning();
      }
    } catch (e) {
      print('Error checking subscription: $e');
    } finally {
      isLoading.value = false;
    }
    
  }

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

  isTrialActive.value = (plan == 'trial' && trialDays > 0 && status == 'active');

  if (subscription['trialEndDate'] != null) {
    trialEndDate.value = DateTime.parse(subscription['trialEndDate']);
  }
  if (subscription['endDate'] != null) {
    subscriptionEndDate.value = DateTime.parse(subscription['endDate']);
  }

  _saveSubscriptionStatus();
}
  void _showTrialExpiryWarning() {
    if (isTrialActive.value && trialDaysRemaining.value <= 3 && trialDaysRemaining.value > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        AppSnackbar.error(kWarning, '⚠️ Trial Expiring Soon', 'Your ${trialDaysRemaining.value} day trial will end soon. Subscribe now!');
      });
    }
  }

  Future<void> loadPlans() async {
    try {
      isLoading.value = true;
      final response = await _subscriptionService.getPlans();
      if (response['success'] == true) {
        plans.value = List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      print('Error loading plans: $e');
    } finally {
      isLoading.value = false;
    }
  }
Future<bool> subscribe(String plan, double amount) async {
  try {
    isLoading.value = true;
    justSubscribed.value = true;
    if (kIsWeb) {
      final response = await _subscriptionService.createStripeCheckout(
        plan: plan,
      );

      if (response['success'] == true) {
        isLoading.value = false;
        return true;
      } else {
        justSubscribed.value = false;
        AppSnackbar.error(kDanger, 'Error', response['message'] ?? 'Failed to start payment');
        isLoading.value = false;
        return false;
      }
    }

    AppSnackbar.error(kWarning, 'Web Only', 'Stripe payment is only available on web version');
    justSubscribed.value = false;
    isLoading.value = false;
    return false;

  } catch (e) {
    justSubscribed.value = false;
    isLoading.value = false;
    AppSnackbar.error(kDanger, 'Error', 'error. Please try again.');
    return false;
  }
}  Future<void> cancelSubscription() async {
    try {
      isLoading.value = true;
      final response = await _subscriptionService.cancelSubscription();

      if (response['success'] == true) {
        hasActiveSubscription.value = false;
        subscriptionStatus.value = 'expired';

        AppSnackbar.success(kSuccess, 'Success', 'Subscription cancelled successfully');

        Get.offAll(() => const SelectPlanScreen());
      } else {
        AppSnackbar.error(kDanger, 'Error', response['message'] ?? 'Failed to cancel subscription');
      }
    } catch (e) {
      AppSnackbar.error(kDanger, 'Error', 'error. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  String getTrialStatusText() {
    if (isTrialActive.value) {
      if (trialDaysRemaining.value == 30) return '🎉 30-Day Free Trial Started!';
      if (trialDaysRemaining.value <= 3) return '⚠️ Trial ends in ${trialDaysRemaining.value} days!';
      return '✨ ${trialDaysRemaining.value} days left in free trial';
    } else if (subscriptionPlan.value != 'none' && hasActiveSubscription.value) {
      if (subscriptionDaysRemaining.value > 0) return '📅 ${subscriptionDaysRemaining.value} days remaining';
    }
    return 'Subscription expired';
  }

  double getTrialProgress() {
    if (!isTrialActive.value) return 1.0;
    if (trialDaysRemaining.value <= 0) return 1.0;
    return ((30 - trialDaysRemaining.value) / 30).clamp(0.0, 1.0);
  }

  Future<void> _saveSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_active_subscription', hasActiveSubscription.value);
    await prefs.setString('subscription_plan', subscriptionPlan.value);
    await prefs.setInt('trial_days_remaining', trialDaysRemaining.value);
    await prefs.setBool('is_trial_active', isTrialActive.value);
  }

  bool get hasAccess => hasActiveSubscription.value;
  bool get onTrial => isTrialActive.value;

  String get trialDaysText {
    if (trialDaysRemaining.value > 0) return '${trialDaysRemaining.value} days remaining in trial';
    return 'Trial expired';
  }

  String get subscriptionDaysText {
    if (subscriptionDaysRemaining.value > 0) return '${subscriptionDaysRemaining.value} days remaining';
    return 'Subscription expired';
  }

  int get remainingDays {
    if (isTrialActive.value && trialDaysRemaining.value > 0) return trialDaysRemaining.value;
    if (subscriptionDaysRemaining.value > 0) return subscriptionDaysRemaining.value;
    return 0;
  }
}

