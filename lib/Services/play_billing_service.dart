import 'dart:async';

import 'package:BisonsTechs_app/core/plans/utils/play_product_ids.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

class PlayPurchaseResult {
  final bool success;
  final String? purchaseToken;
  final String? productId;
  final String? message;
  final bool canceled;

  const PlayPurchaseResult({
    required this.success,
    this.purchaseToken,
    this.productId,
    this.message,
    this.canceled = false,
  });
}

/// Google Play Billing wrapper. No-op on iOS/web.
class PlayBillingService {
  PlayBillingService._();
  static final PlayBillingService instance = PlayBillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Completer<PlayPurchaseResult>? _pending;
  String? _pendingProductId;
  bool _inited = false;
  bool _available = false;
  final Map<String, ProductDetails> products = {};

  Future<void> init() async {
    if (_inited) return;
    _inited = true;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    _available = await _iap.isAvailable();
    if (!_available) return;

    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        _finish(
          PlayPurchaseResult(success: false, message: e.toString()),
        );
      },
    );
    await queryProducts();
  }

  Future<void> queryProducts() async {
    if (!_available) {
      _available = await _iap.isAvailable();
      if (!_available) return;
    }
    final response = await _iap.queryProductDetails(PlayProductIds.all);
    products
      ..clear()
      ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
  }

  String? localizedPrice(String productId) => products[productId]?.price;

  Future<PlayPurchaseResult> buy(String productId) async {
    await init();
    if (!_available) {
      return const PlayPurchaseResult(
        success: false,
        message: 'Google Play Billing is not available on this device.',
      );
    }
    if (products.isEmpty) await queryProducts();
    final product = products[productId];
    if (product == null) {
      return PlayPurchaseResult(
        success: false,
        message:
            'Play product "$productId" was not found. Create it in Play Console first.',
      );
    }

    if (_pending != null && !(_pending!.isCompleted)) {
      return const PlayPurchaseResult(
        success: false,
        message: 'A purchase is already in progress.',
      );
    }

    _pending = Completer<PlayPurchaseResult>();
    _pendingProductId = productId;

    GooglePlayPurchaseDetails? oldSub;
    try {
      final android = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final past = await android.queryPastPurchases();
      for (final p in past.pastPurchases) {
        if (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored) {
          oldSub = p;
          break;
        }
      }
    } catch (e) {
      debugPrint('Play past purchases: $e');
    }

    final param = GooglePlayPurchaseParam(
      productDetails: product,
      changeSubscriptionParam: (oldSub == null || oldSub.productID == productId)
          ? null
          : ChangeSubscriptionParam(oldPurchaseDetails: oldSub),
    );

    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      _pending = null;
      _pendingProductId = null;
      return const PlayPurchaseResult(
        success: false,
        message: 'Could not start Google Play purchase.',
      );
    }

    return _pending!.future.timeout(
      const Duration(minutes: 4),
      onTimeout: () {
        _pending = null;
        _pendingProductId = null;
        return const PlayPurchaseResult(
          success: false,
          message: 'Purchase timed out. Please try again.',
        );
      },
    );
  }

  Future<void> restore() async {
    await init();
    if (_available) await _iap.restorePurchases();
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      unawaited(_handle(purchase));
    }
  }

  Future<void> _handle(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) return;

    if (purchase.status == PurchaseStatus.error) {
      _finish(
        PlayPurchaseResult(
          success: false,
          message: purchase.error?.message ?? 'Purchase failed.',
        ),
      );
    } else if (purchase.status == PurchaseStatus.canceled) {
      _finish(const PlayPurchaseResult(success: false, canceled: true));
    } else if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      final expected = _pendingProductId;
      if (expected != null && purchase.productID != expected) {
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        return;
      }
      String? token;
      if (purchase is GooglePlayPurchaseDetails) {
        token = purchase.billingClientPurchase.purchaseToken;
      }
      _finish(
        PlayPurchaseResult(
          success: token != null && token.isNotEmpty,
          purchaseToken: token,
          productId: purchase.productID,
          message: token == null ? 'Missing Play purchase token.' : null,
        ),
      );
    }

    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  void _finish(PlayPurchaseResult result) {
    final pending = _pending;
    _pending = null;
    _pendingProductId = null;
    if (pending != null && !pending.isCompleted) {
      pending.complete(result);
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
