import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinPack {
  final String id;
  final int coins;
  final int bonus;
  const CoinPack(this.id, this.coins, this.bonus);
  int get total => coins + bonus;
}

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  static const String noAdsId = 'noads';
  static const List<CoinPack> coinPacks = [
    CoinPack('coins_500', 500, 0),
    CoinPack('coins_1500', 1500, 200),
    CoinPack('coins_5000', 5000, 1000),
    CoinPack('coins_15000', 15000, 5000),
  ];

  static const _kNoAdsKey = 'g2048_no_ads';
  static const _kCoinsKey = 'coins2048';

  static String _platformId(String logicalId) =>
      Platform.isIOS ? '${logicalId}_2048' : logicalId;

  static String _logicalId(String platformId) =>
      platformId.endsWith('_2048') ? platformId.substring(0, platformId.length - 5) : platformId;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, ProductDetails> _products = {}; // keyed by logical ID
  bool _available = false;
  bool _noAds = false;
  final ValueNotifier<bool> noAdsNotifier = ValueNotifier(false);

  bool get available => _available;
  bool get noAds => _noAds;
  ProductDetails? productFor(String logicalId) => _products[logicalId];
  List<ProductDetails> get coinProducts =>
      coinPacks.map((p) => _products[p.id]).whereType<ProductDetails>().toList();

  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final prefs = await SharedPreferences.getInstance();
    _noAds = prefs.getBool(_kNoAdsKey) ?? false;
    noAdsNotifier.value = _noAds;
    _available = await _iap.isAvailable();
    if (!_available) return;
    final logicalIds = <String>{noAdsId, ...coinPacks.map((p) => p.id)};
    final platformIds = logicalIds.map(_platformId).toSet();
    final response = await _iap.queryProductDetails(platformIds);
    for (final p in response.productDetails) {
      _products[_logicalId(p.id)] = p;
    }
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdated, onDone: () => _sub?.cancel());
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
        await _grant(p);
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _grant(PurchaseDetails p) async {
    final prefs = await SharedPreferences.getInstance();
    final logicalId = _logicalId(p.productID);
    if (logicalId == noAdsId) {
      _noAds = true;
      noAdsNotifier.value = true;
      await prefs.setBool(_kNoAdsKey, true);
      return;
    }
    final pack = coinPacks.where((cp) => cp.id == logicalId).firstOrNull;
    if (pack != null) {
      final current = prefs.getInt(_kCoinsKey) ?? 0;
      await prefs.setInt(_kCoinsKey, current + pack.total);
    }
  }

  Future<bool> buy(String logicalId) async {
    final product = _products[logicalId];
    if (product == null || !_available) return false;
    final param = PurchaseParam(productDetails: product);
    if (logicalId == noAdsId) {
      return _iap.buyNonConsumable(purchaseParam: param);
    }
    return _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> restore() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _sub?.cancel();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
