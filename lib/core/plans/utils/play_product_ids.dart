import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';

/// Google Play subscription product IDs (must match Play Console exactly).
class PlayProductIds {
  static const posMonthly = 'pos_monthly';
  static const posYearly = 'pos_yearly';
  static const erpMonthly = 'erp_pos_monthly';
  static const erpYearly = 'erp_pos_yearly';

  static const all = <String>{
    posMonthly,
    posYearly,
    erpMonthly,
    erpYearly,
  };

  static String fromSelection(ProductTier tier, BillingCycle cycle) {
    final yearly = cycle == 'yearly';
    if (tier == tierPos) return yearly ? posYearly : posMonthly;
    return yearly ? erpYearly : erpMonthly;
  }

  static ({ProductTier tier, BillingCycle cycle, int users, int branches})
      parse(String productId) {
    switch (productId) {
      case posMonthly:
        return (tier: tierPos, cycle: 'monthly', users: 1, branches: 1);
      case posYearly:
        return (tier: tierPos, cycle: 'yearly', users: 1, branches: 1);
      case erpYearly:
        return (tier: tierErpPos, cycle: 'yearly', users: 1, branches: 1);
      case erpMonthly:
      default:
        return (tier: tierErpPos, cycle: 'monthly', users: 1, branches: 1);
    }
  }
}
