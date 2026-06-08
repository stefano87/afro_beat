import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../data/premium_beats_data.dart';
import '../data/store_products_data.dart';

class PurchaseService extends ChangeNotifier {
  static const _prefsKey = AppConfig.ownedBeatPackIdsKey;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  bool _loading = true;
  String? _error;
  Set<String> _ownedProductIds = {};
  Map<String, ProductDetails> _products = {};

  bool get isAvailable => _available;
  bool get loading => _loading;
  String? get error => _error;
  Set<String> get ownedProductIds => Set.unmodifiable(_ownedProductIds);
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  bool ownsProduct(String productId) => _ownedProductIds.contains(productId);

  bool get hasRemovedInterstitials =>
      ownsProduct(kRemoveInterstitialAdsProductId);

  bool get hasAnyPremiumBeats =>
      _ownedProductIds.any(kAllBeatPackProductIds.contains);

  bool get hasAnyPremium => hasAnyPremiumBeats || hasRemovedInterstitials;

  Future<void> initialize() async {
    await _loadOwnedProducts();

    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      _available = false;
      _loading = false;
      notifyListeners();
      return;
    }

    _available = await _iap.isAvailable();
    if (!_available) {
      _loading = false;
      notifyListeners();
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    await _queryProducts();
    await restorePurchases();
    _loading = false;
    notifyListeners();
  }

  Future<void> _loadOwnedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    _ownedProductIds = raw?.toSet() ?? {};
    await _migrateLegacyPackIds();
    await _normalizeBundleOwnership();
  }

  /// Maps old Play product IDs from the first store draft.
  Future<void> _migrateLegacyPackIds() async {
    var changed = false;
    if (_ownedProductIds.remove('beat_pack_street')) {
      _ownedProductIds.add('beat_pack_afrobeats');
      changed = true;
    }
    if (_ownedProductIds.remove('beat_pack_vibes')) {
      _ownedProductIds.add('beat_pack_afrotrap');
      changed = true;
    }
    if (changed) await _saveOwnedProducts();
  }

  /// Full bundle grants all beats once; drop redundant single-pack flags.
  Future<void> _normalizeBundleOwnership() async {
    if (!_ownedProductIds.contains('beat_pack_full')) return;
    final before = _ownedProductIds.length;
    _ownedProductIds
      ..remove('beat_pack_afrobeats')
      ..remove('beat_pack_afrotrap')
      ..remove('beat_pack_afropop');
    if (_ownedProductIds.length != before) {
      await _saveOwnedProducts();
    }
  }

  Future<void> _saveOwnedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _ownedProductIds.toList());
  }

  Future<void> _queryProducts() async {
    final response = await _iap.queryProductDetails(kAllStoreProductIds);
    if (response.error != null) {
      _error = response.error!.message;
    }
    _products = {for (final p in response.productDetails) p.id: p};
  }

  Future<void> buy(String productId) async {
    if (!_available) {
      _error = 'Purchases are only available on the Android/iOS app.';
      notifyListeners();
      return;
    }

    final product = _products[productId];
    if (product == null) {
      _error = 'Product not found. Configure it in Google Play Console.';
      notifyListeners();
      return;
    }

    _error = null;
    final param = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        _error = purchase.error?.message ?? 'Purchase failed';
        notifyListeners();
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _grantProduct(purchase.productID);
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _grantProduct(String productId) async {
    if (productId == 'beat_pack_full') {
      _ownedProductIds.add('beat_pack_full');
      _ownedProductIds
        ..remove('beat_pack_afrobeats')
        ..remove('beat_pack_afrotrap')
        ..remove('beat_pack_afropop');
    } else if (productId == kRemoveInterstitialAdsProductId ||
        kAllBeatPackProductIds.contains(productId)) {
      _ownedProductIds.add(productId);
    }
    await _saveOwnedProducts();
    _error = null;
    notifyListeners();
  }

  /// Debug-only: simulates purchase without Play Store (web/local testing).
  Future<void> debugUnlockPack(String productId) async {
    assert(kDebugMode);
    await _grantProduct(productId);
  }

  String priceLabel(String productId, {String fallback = '€2.99'}) {
    return _products[productId]?.price ?? fallback;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
