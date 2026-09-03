import 'package:BisonsTechs_app/Services/subscription_service.dart';
import 'package:BisonsTechs_app/Utils/colors.dart';
import 'package:BisonsTechs_app/Utils/toast_utils.dart';
import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

enum UpgradeReason { userSeat, branch }

Future<void> showSubscriptionUpgradeDialog({
  required BuildContext context,
  required UpgradeReason reason,
  required SubscriptionCapacity capacity,
  required UpgradeQuote upgrade,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _SubscriptionUpgradeDialog(
      reason: reason,
      capacity: capacity,
      upgrade: upgrade,
    ),
  );
}

class _SubscriptionUpgradeDialog extends StatefulWidget {
  final UpgradeReason reason;
  final SubscriptionCapacity capacity;
  final UpgradeQuote upgrade;

  const _SubscriptionUpgradeDialog({
    required this.reason,
    required this.capacity,
    required this.upgrade,
  });

  @override
  State<_SubscriptionUpgradeDialog> createState() =>
      _SubscriptionUpgradeDialogState();
}

class _SubscriptionUpgradeDialogState extends State<_SubscriptionUpgradeDialog> {
  bool _processing = false;
  String? _error;

  String get _title => widget.reason == UpgradeReason.userSeat
      ? 'Add another user seat'
      : 'Add another branch / location';

  String get _description {
    final c = widget.capacity;
    if (widget.reason == UpgradeReason.userSeat) {
      return 'You are using ${c.usedUsers} of ${c.licensedUsers} licensed user seat(s). Upgrade to invite another team member.';
    }
    return 'You are using ${c.usedBranches} of ${c.licensedBranches} licensed branch(es). Upgrade to add another shop or warehouse.';
  }

  String get _cycleLabel =>
      widget.capacity.billingCycle == 'yearly' ? 'year' : 'month';

  PriceQuote get _preview {
    final c = widget.capacity;
    final u = widget.upgrade;
    if (widget.reason == UpgradeReason.userSeat) {
      return calculatePrice(
        c.productTier,
        c.billingCycle,
        u.licensedUsers,
        c.licensedBranches,
      );
    }
    return calculatePrice(
      c.productTier,
      c.billingCycle,
      c.licensedUsers,
      u.licensedBranches,
    );
  }

  Future<void> _confirmUpgrade() async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final res = await SubscriptionService().upgradeSubscription(
        licensedUsers: widget.upgrade.licensedUsers,
        licensedBranches: widget.upgrade.licensedBranches,
      );
      if (res['success'] != true) {
        throw Exception(res['message'] ?? 'Upgrade failed');
      }
      if (mounted) Navigator.of(context).pop();
      AppSnackbar.success(
        kSuccess,
        'Upgraded',
        'Subscription updated. You can add ${widget.reason == UpgradeReason.userSeat ? 'the user' : 'the location'} now.',
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.capacity;
    final u = widget.upgrade;
    final tierLabel =
        c.productTier == tierPos ? 'POS (Desktop)' : 'ERP + POS';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.reason == UpgradeReason.userSeat
                          ? Icons.people_outline
                          : Icons.store_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: kText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _description,
                          style: TextStyle(
                            fontSize: 13,
                            color: kSubText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'YOUR CURRENT PLAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: kSubText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row('Product', tierLabel),
                    _row(
                      'Billing',
                      c.isTrial ? 'Free trial' : c.billingCycle,
                    ),
                    _row(
                      'User seats',
                      '${c.usedUsers} used${!c.isTrial && c.licensedUsers < 999 ? ' / ${c.licensedUsers} licensed' : c.isTrial ? ' (unlimited on trial)' : ''}',
                    ),
                    if (c.productTier == tierErpPos)
                      _row(
                        'Branches',
                        '${c.usedBranches} used${!c.isTrial && c.licensedBranches < 999 ? ' / ${c.licensedBranches} licensed' : c.isTrial ? ' (unlimited on trial)' : ''}',
                      ),
                    if (!c.isTrial)
                      _row(
                        'Current price',
                        '${formatUsd(u.current.amount)} / $_cycleLabel',
                      ),
                    const Divider(height: 20),
                    _row(
                      'After upgrade',
                      c.isTrial
                          ? 'Choose a plan on Plans screen'
                          : '${formatUsd(_preview.amount)} / $_cycleLabel',
                      valueStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                    if (!c.isTrial && u.delta > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Additional ${formatUsd(u.delta)} / $_cycleLabel for this upgrade.',
                          style: const TextStyle(fontSize: 11, color: kSubTextLight),
                        ),
                      ),
                  ],
                ),
              ),
              if (c.isTrial) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'You are on a free trial — all features included. No charge until you subscribe.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF065F46)),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: kDanger),
                ),
              ],
              const SizedBox(height: 16),
              if (!c.isTrial)
                ElevatedButton(
                  onPressed: _processing ? null : _confirmUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _processing
                      ? LoadingAnimationWidget.waveDots(
                          color: Colors.white,
                          size: 24,
                        )
                      : const Text(
                          'Confirm upgrade',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              if (!c.isTrial) const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Get.toNamed('/plans'),
                child: Text(
                  c.isTrial || !c.isPaid ? 'View plans' : 'Billing & invoices',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: kSubText)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ??
                  TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kText,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
