/// Mirrors accounting-web-app/lib/subscription-pricing.ts

const int trialDays = 14;

typedef ProductTier = String; // 'pos' | 'erp_pos'
typedef BillingCycle = String; // 'monthly' | 'yearly'

const ProductTier tierPos = 'pos';
const ProductTier tierErpPos = 'erp_pos';

class PricingTierInfo {
  final String label;
  final double monthlyPerUser;
  final double yearlyPerUser;
  final double monthlyBase;
  final double yearlyBase;
  final List<String> features;

  const PricingTierInfo({
    required this.label,
    this.monthlyPerUser = 0,
    this.yearlyPerUser = 0,
    this.monthlyBase = 0,
    this.yearlyBase = 0,
    this.features = const [],
  });
}

const posPricing = PricingTierInfo(
  label: 'POS (Desktop App)',
  monthlyPerUser: 14,
  yearlyPerUser: 86,
  features: [
    'Desktop POS for Windows & Mac',
    'Offline sales — sync when back online',
    'Shifts, terminals & thermal receipts',
    'Barcode / QR product scanning',
    'Cash drawer & card terminal ready',
    'Held sales, returns & shift reports',
  ],
);

const erpPosPricing = PricingTierInfo(
  label: 'ERP + POS',
  monthlyBase: 36,
  yearlyBase: 257,
  features: [
    'Full web ERP — accounting, sales, purchases, warehouse',
    'Desktop POS with offline mode included',
    'Base price: 1 user + 1 branch',
    'Each extra user doubles total price',
    'Each extra branch doubles total price',
    'Tax compliance, reports & permissions',
  ],
);

class PriceQuote {
  final ProductTier productTier;
  final BillingCycle billingCycle;
  final int licensedUsers;
  final int licensedBranches;
  final double amount;
  final String currency;
  final String breakdown;

  const PriceQuote({
    required this.productTier,
    required this.billingCycle,
    required this.licensedUsers,
    required this.licensedBranches,
    required this.amount,
    this.currency = 'USD',
    required this.breakdown,
  });
}

class UpgradeQuote {
  final PriceQuote current;
  final PriceQuote next;
  final double delta;
  final int licensedUsers;
  final int licensedBranches;

  const UpgradeQuote({
    required this.current,
    required this.next,
    required this.delta,
    required this.licensedUsers,
    required this.licensedBranches,
  });
}

class SubscriptionCapacity {
  final ProductTier productTier;
  final BillingCycle billingCycle;
  final String subscriptionPlan;
  final String subscriptionStatus;
  final bool isTrial;
  final bool isPaid;
  final bool hasAccess;
  final int licensedUsers;
  final int licensedBranches;
  final int usedUsers;
  final int usedBranches;
  final bool canAddUser;
  final bool canAddBranch;
  final double? currentAmount;

  const SubscriptionCapacity({
    this.productTier = tierErpPos,
    this.billingCycle = 'monthly',
    this.subscriptionPlan = 'none',
    this.subscriptionStatus = 'none',
    this.isTrial = false,
    this.isPaid = false,
    this.hasAccess = false,
    this.licensedUsers = 1,
    this.licensedBranches = 1,
    this.usedUsers = 0,
    this.usedBranches = 0,
    this.canAddUser = true,
    this.canAddBranch = true,
    this.currentAmount,
  });

  factory SubscriptionCapacity.fromJson(Map<String, dynamic> json) {
    return SubscriptionCapacity(
      productTier: (json['productTier'] ?? tierErpPos).toString(),
      billingCycle: (json['billingCycle'] ?? 'monthly').toString(),
      subscriptionPlan: (json['subscriptionPlan'] ?? 'none').toString(),
      subscriptionStatus: (json['subscriptionStatus'] ?? 'none').toString(),
      isTrial: json['isTrial'] == true,
      isPaid: json['isPaid'] == true,
      hasAccess: json['hasAccess'] == true,
      licensedUsers: _int(json['licensedUsers'], 1),
      licensedBranches: _int(json['licensedBranches'], 1),
      usedUsers: _int(json['usedUsers'], 0),
      usedBranches: _int(json['usedBranches'], 0),
      canAddUser: json['canAddUser'] != false,
      canAddBranch: json['canAddBranch'] != false,
      currentAmount: json['currentAmount'] == null
          ? null
          : (json['currentAmount'] as num).toDouble(),
    );
  }

  static int _int(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }
}

String formatUsd(double amount, [String? sourceCurrency]) {
  final c = (sourceCurrency ?? 'USD').toUpperCase();
  final usd = c == 'PKR' ? amount / (4000 / 14) : amount;
  return '\$${usd.round()}';
}

PriceQuote calculatePrice(
  ProductTier productTier,
  BillingCycle billingCycle,
  int users,
  int branches,
) {
  final u = users < 1 ? 1 : users;
  final b = branches < 1 ? 1 : branches;

  if (productTier == tierPos) {
    final rate = billingCycle == 'yearly'
        ? posPricing.yearlyPerUser
        : posPricing.monthlyPerUser;
    return PriceQuote(
      productTier: productTier,
      billingCycle: billingCycle,
      licensedUsers: u,
      licensedBranches: b,
      amount: rate * u,
      breakdown: '${formatUsd(rate)} × $u user(s)',
    );
  }

  final rate = billingCycle == 'yearly'
      ? erpPosPricing.yearlyBase
      : erpPosPricing.monthlyBase;
  return PriceQuote(
    productTier: productTier,
    billingCycle: billingCycle,
    licensedUsers: u,
    licensedBranches: b,
    amount: rate * u * b,
    breakdown: '${formatUsd(rate)} × $u user(s) × $b branch(es)',
  );
}

UpgradeQuote buildUserSeatUpgrade(SubscriptionCapacity capacity) {
  final current = calculatePrice(
    capacity.productTier,
    capacity.billingCycle,
    capacity.licensedUsers,
    capacity.licensedBranches,
  );
  final next = calculatePrice(
    capacity.productTier,
    capacity.billingCycle,
    capacity.licensedUsers + 1,
    capacity.licensedBranches,
  );
  return UpgradeQuote(
    current: current,
    next: next,
    delta: next.amount - current.amount,
    licensedUsers: capacity.licensedUsers + 1,
    licensedBranches: capacity.licensedBranches,
  );
}

UpgradeQuote buildBranchUpgrade(SubscriptionCapacity capacity) {
  final current = calculatePrice(
    capacity.productTier,
    capacity.billingCycle,
    capacity.licensedUsers,
    capacity.licensedBranches,
  );
  final next = calculatePrice(
    capacity.productTier,
    capacity.billingCycle,
    capacity.licensedUsers,
    capacity.licensedBranches + 1,
  );
  return UpgradeQuote(
    current: current,
    next: next,
    delta: next.amount - current.amount,
    licensedUsers: capacity.licensedUsers,
    licensedBranches: capacity.licensedBranches + 1,
  );
}
