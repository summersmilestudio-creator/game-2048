import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'services/notification_service.dart';
import 'services/review_service.dart';
import 'screens/home_screen.dart';
import 'services/ads_service.dart';
import 'services/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  NotificationService.instance.scheduleDailyReminder(title: '2048 Slide Puzzle', body: 'Poți ajunge la 2048 azi? 🔢');
  runApp(const Game2048App());
}

class Game2048App extends StatelessWidget {
  const Game2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAF8EF),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEDC22E)),
      ),
      home: UpgradeAlert(child: const HomeScreen()),
    );
  }
}
