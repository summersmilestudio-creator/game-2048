import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/skins.dart';
import '../services/rewards_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/game_juice.dart';
import 'daily_reward_screen.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _rewards = RewardsService();
  int _highScore = 0;

  @override
  void initState() {
    super.initState();
    _checkDaily();
  }

  Future<void> _checkDaily() async {
    final r = await _rewards.claimDailyIfAvailable();
    if (r.reward > 0 && mounted) {
      await Navigator.push(context, MaterialPageRoute(
          builder: (_) => DailyRewardScreen(day: r.day, reward: r.reward)));
    }
    SkinStore.instance.reload(); // pick up the coins the daily bonus added
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _highScore = p.getInt('highScore2048') ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = activeSkin2048();
    final dark = skin.bg.first.computeLuminance() < 0.5;
    final fg = dark ? Colors.white : const Color(0xFF776E65);
    return Scaffold(
      bottomNavigationBar: const BannerAdWidget(),
      body: PremiumBackground(
        colors: skin.bg,
        bokeh: skin.bokeh,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.settings, color: fg),
                      onPressed: () async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()));
                      },
                    ),
                    Row(
                      children: [
                        // Shop button
                        PressableScale(
                          onTap: () async {
                            await Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const ShopScreen()));
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: skin.frame,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.palette_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ListenableBuilder(
                          listenable: SkinStore.instance,
                          builder: (context, _) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: skin.frame,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on,
                                    color: Color(0xFFFFD740), size: 20),
                                const SizedBox(width: 6),
                                Text('${SkinStore.instance.coins}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text('2048',
                    style: TextStyle(
                        color: fg,
                        fontSize: 90,
                        fontWeight: FontWeight.w900,
                        shadows: dark
                            ? [Shadow(color: skin.bokeh.withValues(alpha: 0.6), blurRadius: 24)]
                            : null)),
                const SizedBox(height: 8),
                Text(
                  'Glisează pentru a uni tile-urile.\nAjunge la 2048!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 14),
                ),
                const SizedBox(height: 32),
                _buildPreview(skin),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: skin.frame,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text('TOP SCORE',
                          style: TextStyle(
                              color: Color(0xFFEEE4DA), fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 6),
                      Text('$_highScore',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F7A66),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 6,
                    ),
                    onPressed: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const GameScreen()));
                      SkinStore.instance.reload();
                      _load();
                    },
                    child: const Text('JOC NOU'),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(Skin2048 skin) {
    final rows = [
      [2, 8, 32],
      [4, 128, 512],
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: skin.frame,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((v) => Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: skin.tileColor(v),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text('$v',
                  style: TextStyle(
                      color: skin.textColor(v),
                      fontSize: v < 100 ? 24 : 18,
                      fontWeight: FontWeight.w900)),
            )).toList(),
          ),
        )).toList(),
      ),
    );
  }
}
