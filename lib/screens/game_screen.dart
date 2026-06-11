import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/board.dart';
import '../game/skins.dart';
import '../services/ads_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/game_juice.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Board2048 _board = Board2048();
  int _highScore = 0;
  bool _wonShown = false;
  bool _rewardedBusy = false;
  bool _coinsAwarded = false;
  // Snapshot grilă/scor pentru rewarded undo (în caz că _previousGrid lipsește).
  List<List<int>>? _snapshotGrid;
  int _snapshotScore = 0;

  @override
  void initState() {
    super.initState();
    _board.newGame();
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _highScore = p.getInt('highScore2048') ?? 0);
  }

  Future<void> _onRewardedUndo() async {
    if (_rewardedBusy) return;
    final hasUndo = _snapshotGrid != null;
    if (!hasUndo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nimic de anulat.')),
      );
      return;
    }
    setState(() => _rewardedBusy = true);
    final earned = await AdsService.instance.showRewarded();
    if (!mounted) return;
    setState(() {
      _rewardedBusy = false;
      if (earned) {
        _board.grid = _snapshotGrid!.map((r) => List<int>.from(r)).toList();
        _board.score = _snapshotScore;
        _snapshotGrid = null;
      }
    });
    if (!earned && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reclama nu e disponibilă acum.')),
      );
    }
  }

  Future<void> _saveHighScore() async {
    if (_board.score > _highScore) {
      _highScore = _board.score;
      final p = await SharedPreferences.getInstance();
      await p.setInt('highScore2048', _highScore);
    }
  }

  /// Coins earned at the end of a run, based on the score.
  int _coinsForRun() => (_board.score ~/ 100).clamp(0, 999);

  void _move(int dir) {
    final preGrid = _board.grid.map((r) => List<int>.from(r)).toList();
    final preScore = _board.score;
    if (_board.move(dir)) {
      _snapshotGrid = preGrid;
      _snapshotScore = preScore;
      HapticFeedback.lightImpact();
      _saveHighScore();
      if (_board.won && !_wonShown) {
        _wonShown = true;
        Celebrate.show(context);
        SkinStore.instance.addCoins(100); // bonus pentru 2048
        Future.microtask(() {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('🎉 Ai reușit!'),
              content: const Text('Felicitări! +100 monede 🪙\nContinuă pentru scor mai mare?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Continuă')),
              ],
            ),
          );
        });
      }
      if (!_board.canMove) {
        final earned = _coinsForRun();
        if (!_coinsAwarded) {
          _coinsAwarded = true;
          if (earned > 0) SkinStore.instance.addCoins(earned);
        }
        Future.microtask(() async {
          await AdsService.instance.maybeShowInterstitial();
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (c) => StatefulBuilder(
              builder: (c, setLocal) => AlertDialog(
                title: const Text('Game Over'),
                content: Text('Scor final: ${_board.score}\n+$earned monede 🪙'),
                actions: [
                  TextButton(onPressed: () {
                    Navigator.pop(c);
                    setState(() {
                      _board.newGame();
                      _wonShown = false;
                      _coinsAwarded = false;
                    });
                  }, child: const Text('Joc Nou')),
                  TextButton.icon(
                    onPressed: _rewardedBusy
                        ? null
                        : () async {
                            setLocal(() => _rewardedBusy = true);
                            final ok = await AdsService.instance.showRewarded();
                            _rewardedBusy = false;
                            if (!c.mounted) return;
                            if (ok) {
                              Navigator.pop(c);
                              setState(() {
                                _board.clearTopTiles(rows: 2);
                                _coinsAwarded = false;
                              });
                            } else {
                              setLocal(() {});
                              ScaffoldMessenger.of(c).showSnackBar(
                                const SnackBar(
                                  content: Text('Reclama nu e disponibilă acum.'),
                                ),
                              );
                            }
                          },
                    icon: _rewardedBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.favorite, color: Color(0xFFE53935)),
                    label: const Text('❤️ Continuă (urmărește reclamă)'),
                  ),
                ],
              ),
            ),
          );
        });
      }
      setState(() {});
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Number Merge',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900, color: fg)),
                    Row(
                      children: [
                        _scoreBox('SCOR', _board.score, skin),
                        const SizedBox(width: 8),
                        _scoreBox('TOP', _highScore, skin),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Undo (reclamă)',
                          onPressed: _rewardedBusy ? null : _onRewardedUndo,
                          icon: _rewardedBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.replay, color: fg),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Combină blocurile cu numere egale!',
                        style: TextStyle(color: fg.withValues(alpha: 0.85))),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _board.undo()),
                          icon: const Icon(Icons.undo, size: 16),
                          label: const Text('Înapoi'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8F7A66),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _board.newGame();
                              _wonShown = false;
                              _coinsAwarded = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8F7A66),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          child: const Text('Nou'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildBoard(skin)),
                const SizedBox(height: 16),
                Text(
                  'Glisează ↑ ↓ ← → pentru a muta',
                  style: TextStyle(color: fg.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreBox(String label, int v, Skin2048 skin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: skin.frame,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFEEE4DA), fontSize: 12, fontWeight: FontWeight.w700)),
          Text('$v', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildBoard(Skin2048 skin) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0).abs() < 100) return;
            _move(d.primaryVelocity! > 0 ? 1 : 3);
          },
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0).abs() < 100) return;
            _move(d.primaryVelocity! > 0 ? 2 : 0);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: skin.frame,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (c, cons) {
                final cellSize = (cons.maxWidth - 8 * 5) / 4;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    for (var r = 0; r < 4; r++)
                      for (var c = 0; c < 4; c++)
                        Positioned(
                          left: 8 + c * (cellSize + 8),
                          top: 8 + r * (cellSize + 8),
                          width: cellSize,
                          height: cellSize,
                          child: Container(
                            decoration: BoxDecoration(
                              color: skin.emptyCell,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                    for (var r = 0; r < 4; r++)
                      for (var c = 0; c < 4; c++)
                        if (_board.grid[r][c] != 0)
                          Positioned(
                            left: 8 + c * (cellSize + 8),
                            top: 8 + r * (cellSize + 8),
                            width: cellSize,
                            height: cellSize,
                            child: _tile(_board.grid[r][c], cellSize, skin),
                          ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(int v, double size, Skin2048 skin) {
    final fontScale = v >= 1024 ? 0.32 : (v >= 100 ? 0.4 : 0.5);
    final color = skin.tileColor(v);
    final glow = v >= 128 && skin.id != 'default';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: glow
            ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 12, spreadRadius: 1)]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$v',
        style: TextStyle(
          fontSize: size * fontScale,
          fontWeight: FontWeight.w900,
          color: skin.textColor(v),
        ),
      ),
    );
  }
}
