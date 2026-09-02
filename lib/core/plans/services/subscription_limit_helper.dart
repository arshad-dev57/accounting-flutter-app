import 'package:BisonsTechs_app/Services/subscription_service.dart';
import 'package:BisonsTechs_app/core/plans/utils/subscription_pricing.dart';
import 'package:BisonsTechs_app/core/plans/widgets/subscription_upgrade_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pre-check capacity before add user / add location — same flow as web app.
class SubscriptionLimitHelper {
  static final SubscriptionService _service = SubscriptionService();

  static Future<SubscriptionCapacity?> fetchCapacity() async {
    final res = await _service.fetchCapacity();
    if (res['success'] != true || res['data'] == null) return null;
    final data = res['data'];
    if (data is! Map<String, dynamic>) return null;
    return SubscriptionCapacity.fromJson(data);
  }

  /// Returns true if caller should proceed (open form / create).
  static Future<bool> guardAddUser(BuildContext context) async {
    try {
      final capacity = await fetchCapacity();
      if (capacity == null || capacity.canAddUser) return true;
      if (!context.mounted) return false;
      await showSubscriptionUpgradeDialog(
        context: context,
        reason: UpgradeReason.userSeat,
        capacity: capacity,
        upgrade: buildUserSeatUpgrade(capacity),
      );
      return false;
    } catch (_) {
      return true;
    }
  }

  static Future<bool> guardAddBranch(BuildContext context) async {
    try {
      final capacity = await fetchCapacity();
      if (capacity == null || capacity.canAddBranch) return true;
      if (!context.mounted) return false;
      await showSubscriptionUpgradeDialog(
        context: context,
        reason: UpgradeReason.branch,
        capacity: capacity,
        upgrade: buildBranchUpgrade(capacity),
      );
      return false;
    } catch (_) {
      return true;
    }
  }

  /// GetX-friendly variant when BuildContext may be from Get.context.
  static Future<bool> guardAddUserGet() async {
    final ctx = Get.context;
    if (ctx == null) return true;
    return guardAddUser(ctx);
  }

  static Future<bool> guardAddBranchGet() async {
    final ctx = Get.context;
    if (ctx == null) return true;
    return guardAddBranch(ctx);
  }
}
