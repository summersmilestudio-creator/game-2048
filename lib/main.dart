import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'services/notification_service.dart';
import 'services/review_service.dart';
import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/purchase_service.dart';
import 'game/skins.dart';
import 'widgets/remove_ads_offer.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SkinStore.instance.init();
  await PurchaseService.instance.initialize();  if (Platform.isIOS) {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (_) {}
  }

  AdsService.instance.initialize();
  ReviewService.instance.registerLaunch();
  NotificationService.instance.scheduleDailyReminder(title: 'Number Merge', body: 'Poți ajunge la blocul de aur azi? 🔢');
  runApp(const Game2048App());
}

class Game2048App extends StatefulWidget {
  const Game2048App({super.key});

  @override
  State<Game2048App> createState() => _Game2048AppState();
}

class _Game2048AppState extends State<Game2048App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Show the upsell right after a full-screen ad (App Open / interstitial) closes.
    AdsService.instance.adClosedTick.addListener(_onAdClosed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AdsService.instance.adClosedTick.removeListener(_onAdClosed);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdsService.instance.showAppOpenIfReady();
    }
  }

  void _onAdClosed() {
    final ctx = navigatorKey.currentContext;
    if (ctx != null) RemoveAdsOffer.maybeShow(ctx);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Merge',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF8EF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEDC22E)),
      ),
      home: UpgradeAlert(child: const HomeScreen()),
    );
  }
}
