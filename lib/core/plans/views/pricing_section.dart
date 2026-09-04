import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/config/store_compliance.dart';
import 'package:BisonsTechs_app/core/plans/services/subscription_limit_helper.dart';
import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';

const String _customPlanEmail = 'support@bisonstechs.com';
const String _customPlanPhone = '+92 325 3411482';
const String _customPlanPhoneTel = '+923253411482';

/// Web-like pricing UI: POS vs ERP+POS, user/branch counters, live quote.
class PricingSection extends StatefulWidget {
  final bool processing;
  final bool isTrial;
  final bool isPaid;
  final bool trialEligible;
  final VoidCallback onComplete;
  final Future<void> Function() onStartTrial;
  final Future<void> Function({
    required String billingCycle,
    required double amount,
    required String productTier,
    required int licensedUsers,
    required int licensedBranches,
    required bool isUpgrade,
  }) onSubscribe;

  const PricingSection({
    super.key,
    required this.processing,
    required this.isTrial,
    required this.isPaid,
    this.trialEligible = false,
    required this.onComplete,
    required this.onStartTrial,
    required this.onSubscribe,
  });

  @override
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  SubscriptionCapacity? _capacity;
  bool _loadingCapacity = true;

  BillingCycle _billingCycle = 'monthly';
  ProductTier _productTier = tierErpPos;
  int _users = 1;
  int _branches = 1;
  String? _error;

  bool get _hasActivePlan => widget.isTrial || widget.isPaid;

  @override
  void initState() {
    super.initState();
    _loadCapacity();
  }

  Future<void> _loadCapacity() async {
    setState(() => _loadingCapacity = true);
    final cap = await SubscriptionLimitHelper.fetchCapacity();
    if (!mounted) return;
    if (cap != null) {
      final initialUsers = (cap.isTrial || cap.licensedUsers >= 999)
          ? (cap.usedUsers < 1 ? 1 : cap.usedUsers)
          : cap.licensedUsers;
      final initialBranches = (cap.isTrial || cap.licensedBranches >= 999)
          ? (cap.usedBranches < 1 ? 1 : cap.usedBranches)
          : cap.licensedBranches;
      setState(() {
        _capacity = cap;
        _billingCycle = cap.billingCycle;
        _productTier = cap.productTier;
        _users = initialUsers;
        _branches = initialBranches;
      });
    }
    setState(() => _loadingCapacity = false);
  }

  PriceQuote get _quote =>
      calculatePrice(_productTier, _billingCycle, _users, _branches);

  PriceQuote? get _currentQuote {
    final c = _capacity;
    if (c == null || !c.isPaid) return null;
    return calculatePrice(
      c.productTier,
      c.billingCycle,
      c.licensedUsers,
      c.licensedBranches,
    );
  }

  double get _priceDelta {
    final cur = _currentQuote;
    if (cur == null || !_hasActivePlan || _capacity?.isPaid != true) return 0;
    return _quote.amount - cur.amount;
  }

  String get _cycleLabel => _billingCycle == 'yearly' ? 'year' : 'month';

  bool _isCurrentSelection(ProductTier tier) {
    final c = _capacity;
    if (!widget.isPaid || c == null) return false;
    return tier == c.productTier &&
        _billingCycle == c.billingCycle &&
        _users == c.licensedUsers &&
        _branches == c.licensedBranches;
  }

  String _subscribeLabel(ProductTier tier) {
    if (StoreCompliance.blocksInAppDigitalPurchase) {
      return 'Subscribe on website';
    }
    if (widget.isTrial) {
      return tier == tierPos ? 'Subscribe to POS' : 'Subscribe to ERP + POS';
    }
    if (widget.isPaid && _capacity != null) {
      final changed = tier != _capacity!.productTier ||
          _billingCycle != _capacity!.billingCycle ||
          _users != _capacity!.licensedUsers ||
          _branches != _capacity!.licensedBranches;
      if (!changed) return 'Current selection';
      return 'Update subscription';
    }
    return tier == tierPos ? 'Subscribe to POS' : 'Subscribe to ERP + POS';
  }

  Future<void> _handleSubscribe(ProductTier tier) async {
    if (widget.processing) return;
    if (await StoreCompliance.redirectPaidCheckoutIfRequired()) return;
    setState(() {
      _productTier = tier;
      _error = null;
    });

    final quote = calculatePrice(tier, _billingCycle, _users, _branches);
    final c = _capacity;
    final sameTierUpgrade = c?.isPaid == true &&
        tier == c!.productTier &&
        _billingCycle == c.billingCycle;

    await widget.onSubscribe(
      billingCycle: _billingCycle,
      amount: quote.amount,
      productTier: tier,
      licensedUsers: _users,
      licensedBranches: tier == tierPos ? 1 : _branches,
      isUpgrade: sameTierUpgrade,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCapacity) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasActivePlan) ...[
          Text(
            widget.isTrial ? 'Subscribe after trial' : 'Upgrade or change plan',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: Color(0xFFA3A3A3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isTrial
                ? 'Choose a paid plan before your trial ends. Values below start from your trial usage.'
                : 'Adjust users or branches below. Your current plan details are shown above.',
            style: TextStyle(fontSize: 13, color: kSubText, height: 1.4),
          ),
          if (_capacity?.isPaid == true &&
              _currentQuote != null &&
              _priceDelta != 0) ...[
            const SizedBox(height: 8),
            Text(
              _priceDelta > 0
                  ? 'New total: ${formatUsd(_quote.amount)} / $_cycleLabel (+${formatUsd(_priceDelta)} vs current)'
                  : 'New total: ${formatUsd(_quote.amount)} / $_cycleLabel',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kPrimary,
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
        if (!widget.isTrial && !widget.isPaid && widget.trialEligible) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0x0F014582),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x40014582)),
            ),
            child: Column(
              children: [
                const Text(
                  'START FREE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$trialDays-day trial — everything included',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Full ERP + Desktop POS with offline mode. Unlimited users and branches during trial. No credit card required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: kSubText, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.processing ? null : widget.onStartTrial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: widget.processing
                        ? LoadingAnimationWidget.waveDots(
                            color: Colors.white,
                            size: 24,
                          )
                        : Text(
                            'Start $trialDays-day free trial',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _restaurantAddonNote(),
        const SizedBox(height: 20),
        Center(child: _billingToggle()),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _posCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _erpCard()),
                ],
              );
            }
            return Column(
              children: [
                _posCard(),
                const SizedBox(height: 16),
                _erpCard(),
              ],
            );
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: kDanger, fontSize: 13)),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: widget.processing
              ? null
              : () => _showCustomContact(context),
          child: const Text('Need custom features? Contact us'),
        ),
      ],
    );
  }

  Widget _billingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['monthly', 'yearly'].map((cycle) {
          final selected = _billingCycle == cycle;
          return GestureDetector(
            onTap: () => setState(() => _billingCycle = cycle),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                cycle[0].toUpperCase() + cycle.substring(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? kText : kSubText,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _restaurantAddonNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restaurant add-on (POS plan)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF78350F),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Choose Restaurant / Cafe at signup (or ask support to enable posMode=restaurant). Includes Order Picker app, Kitchen & Counter tabs on desktop POS.',
            style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _posCard() {
    final rate = _billingCycle == 'yearly'
        ? posPricing.yearlyPerUser
        : posPricing.monthlyPerUser;
    final selected = _productTier == tierPos;

    return _tierCard(
      selected: selected,
      popular: false,
      title: posPricing.label,
      subtitle: 'Per user · Desktop register app',
      price: formatUsd(rate),
      priceSuffix: '/ user / $_cycleLabel',
      features: posPricing.features,
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          _numberField(
            value: _users,
            onChanged: (v) => setState(() {
              _productTier = tierPos;
              _users = v;
            }),
          ),
        ],
      ),
      buttonLabel: _subscribeLabel(tierPos),
      onSubscribe: _isCurrentSelection(tierPos) || widget.processing
          ? null
          : () => _handleSubscribe(tierPos),
    );
  }

  Widget _erpCard() {
    final rate = _billingCycle == 'yearly'
        ? erpPosPricing.yearlyBase
        : erpPosPricing.monthlyBase;
    final selected = _productTier == tierErpPos;
    final quote = calculatePrice(
      tierErpPos,
      _billingCycle,
      _users,
      _branches,
    );

    return _tierCard(
      selected: selected,
      popular: true,
      title: erpPosPricing.label,
      subtitle: '1 user + 1 branch included',
      price: formatUsd(rate),
      priceSuffix: '/ $_cycleLabel base',
      note:
          '+ each extra user doubles price · + each extra branch doubles price',
      features: erpPosPricing.features,
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Users',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _numberField(
                      value: _users,
                      onChanged: (v) => setState(() {
                        _productTier = tierErpPos;
                        _users = v;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Branches',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _numberField(
                      value: _branches,
                      onChanged: (v) => setState(() {
                        _productTier = tierErpPos;
                        _branches = v;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x14014582),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total: ${formatUsd(quote.amount)} / $_cycleLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              ),
            ),
          ),
        ],
      ),
      buttonLabel: _subscribeLabel(tierErpPos),
      onSubscribe: _isCurrentSelection(tierErpPos) || widget.processing
          ? null
          : () => _handleSubscribe(tierErpPos),
    );
  }

  Widget _tierCard({
    required bool selected,
    required bool popular,
    required String title,
    required String subtitle,
    required String price,
    required String priceSuffix,
    String? note,
    required List<String> features,
    required Widget extra,
    required String buttonLabel,
    required VoidCallback? onSubscribe,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? kPrimary : const Color(0xFFE5E5E5),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: kPrimary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (popular)
            Positioned(
              top: -28,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'POPULAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      popular ? Icons.grid_view_rounded : Icons.desktop_windows_outlined,
                      color: kText,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: kSubText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: kText),
                  children: [
                    TextSpan(
                      text: price,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' $priceSuffix',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: kSubText,
                      ),
                    ),
                  ],
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 4),
                Text(note, style: TextStyle(fontSize: 11, color: kSubText)),
              ],
              const SizedBox(height: 12),
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 16, color: kPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(fontSize: 12, color: kSubText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              extra,
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected ? kPrimary : const Color(0xFF475569),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return TextFormField(
      initialValue: '$value',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (v) {
        final n = int.tryParse(v) ?? 1;
        onChanged(n < 1 ? 1 : n);
      },
    );
  }

  Future<void> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showCustomContact(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For a custom plan, contact BisonsTechs directly:',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _launchUri(Uri.parse('mailto:$_customPlanEmail')),
              onLongPress: () {
                Clipboard.setData(const ClipboardData(text: _customPlanEmail));
              },
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, size: 20, color: kPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _customPlanEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _launchUri(Uri.parse('tel:$_customPlanPhoneTel')),
              onLongPress: () {
                Clipboard.setData(const ClipboardData(text: _customPlanPhone));
              },
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 20, color: kPrimary),
                  const SizedBox(width: 10),
                  Text(
                    _customPlanPhone,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
