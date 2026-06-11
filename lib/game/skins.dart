import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A cosmetic board theme for 2048: background, frame, empty cells and the
/// 11-tile palette (2 → 2048). Unlockable with the coins the player already
/// earns from daily bonuses and play — the long-term retention lever.
class Skin2048 {
  final String id;
  final String name;
  final int cost; // 0 = free/default
  final List<Color> bg; // 3: center → mid → edge of the radial background
  final Color bokeh;
  final Color frame; // board frame + score boxes
  final Color emptyCell;
  final List<Color> tiles; // 11 colors for 2,4,8,...,2048
  final Color overflow; // values above 2048

  const Skin2048({
    required this.id,
    required this.name,
    required this.cost,
    required this.bg,
    required this.bokeh,
    required this.frame,
    required this.emptyCell,
    required this.tiles,
    required this.overflow,
  });

  /// Tile color for a value (2,4,8,...). Falls back to [overflow].
  Color tileColor(int value) {
    final i = _log2(value) - 1;
    if (i < 0) return emptyCell;
    if (i >= tiles.length) return overflow;
    return tiles[i];
  }

  /// Readable text color picked from the tile's luminance.
  Color textColor(int value) =>
      tileColor(value).computeLuminance() > 0.5
          ? const Color(0xFF5A5145)
          : Colors.white;

  static int _log2(int v) {
    var n = 0;
    while (v > 1) {
      v >>= 1;
      n++;
    }
    return n;
  }
}

const skins2048 = <Skin2048>[
  Skin2048(
    id: 'default',
    name: 'Clasic',
    cost: 0,
    bg: [Color(0xFFFAF8EF), Color(0xFFF3EDE0), Color(0xFFEAE0CF)],
    bokeh: Color(0xFFEDC22E),
    frame: Color(0xFFBBADA0),
    emptyCell: Color(0xFFCDC1B4),
    tiles: [
      Color(0xFFEEE4DA), Color(0xFFEDE0C8), Color(0xFFF2B179), Color(0xFFF59563),
      Color(0xFFF67C5F), Color(0xFFF65E3B), Color(0xFFEDCF72), Color(0xFFEDCC61),
      Color(0xFFEDC850), Color(0xFFEDC53F), Color(0xFFEDC22E),
    ],
    overflow: Color(0xFF3C3A32),
  ),
  Skin2048(
    id: 'neon',
    name: 'Neon',
    cost: 300,
    bg: [Color(0xFF1A0B2E), Color(0xFF120820), Color(0xFF05030F)],
    bokeh: Color(0xFF00E5FF),
    frame: Color(0xFF2A1B45),
    emptyCell: Color(0xFF231539),
    tiles: [
      Color(0xFF00E5FF), Color(0xFF18FFFF), Color(0xFF1DE9B6), Color(0xFF00E676),
      Color(0xFF76FF03), Color(0xFFFFEA00), Color(0xFFFF9100), Color(0xFFFF3D71),
      Color(0xFFF50057), Color(0xFFD500F9), Color(0xFF7C4DFF),
    ],
    overflow: Color(0xFFFFFFFF),
  ),
  Skin2048(
    id: 'midnight',
    name: 'Miez de Noapte',
    cost: 400,
    bg: [Color(0xFF1B2A4A), Color(0xFF111C33), Color(0xFF070D1A)],
    bokeh: Color(0xFF5C8DFF),
    frame: Color(0xFF24344F),
    emptyCell: Color(0xFF1C2A41),
    tiles: [
      Color(0xFF3D5A8A), Color(0xFF4A6FA8), Color(0xFF5C8DFF), Color(0xFF7AA2FF),
      Color(0xFF64B5F6), Color(0xFF4FC3F7), Color(0xFF4DD0E1), Color(0xFF26C6DA),
      Color(0xFF7E57C2), Color(0xFF9575CD), Color(0xFFB388FF),
    ],
    overflow: Color(0xFFE3F2FD),
  ),
  Skin2048(
    id: 'candy',
    name: 'Bomboane',
    cost: 500,
    bg: [Color(0xFF3A1430), Color(0xFF2A0E24), Color(0xFF170614)],
    bokeh: Color(0xFFFF80AB),
    frame: Color(0xFF4A1E3E),
    emptyCell: Color(0xFF391830),
    tiles: [
      Color(0xFFFFB3C7), Color(0xFFFF94B8), Color(0xFFFF6FA3), Color(0xFFFF4081),
      Color(0xFFF06292), Color(0xFFBA68C8), Color(0xFFAB47BC), Color(0xFF9C27B0),
      Color(0xFFCE93D8), Color(0xFFFFA726), Color(0xFFFFCA28),
    ],
    overflow: Color(0xFFFFF8E1),
  ),
  Skin2048(
    id: 'ocean',
    name: 'Ocean',
    cost: 700,
    bg: [Color(0xFF0A3D5C), Color(0xFF062A40), Color(0xFF021622)],
    bokeh: Color(0xFF18FFFF),
    frame: Color(0xFF0D4A6E),
    emptyCell: Color(0xFF0A3850),
    tiles: [
      Color(0xFF80DEEA), Color(0xFF4DD0E1), Color(0xFF26C6DA), Color(0xFF00BCD4),
      Color(0xFF00ACC1), Color(0xFF0097A7), Color(0xFF26A69A), Color(0xFF00897B),
      Color(0xFF1DE9B6), Color(0xFF64FFDA), Color(0xFFA7FFEB),
    ],
    overflow: Color(0xFFE0F7FA),
  ),
];

Skin2048 skin2048ById(String id) =>
    skins2048.firstWhere((s) => s.id == id, orElse: () => skins2048.first);

/// Persistent skin/coin store. Coins share the existing `g2048Coins` key so the
/// daily bonus (RewardsService) and the shop draw from one wallet.
class SkinStore extends ChangeNotifier {
  SkinStore._();
  static final SkinStore instance = SkinStore._();

  static const _kCoins = 'g2048Coins';
  static const _kEquipped = 'g2048_equipped';
  static const _kUnlocked = 'g2048_unlocked';

  SharedPreferences? _p;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _p = await SharedPreferences.getInstance();
    _ready = true;
  }

  int get coins => _p?.getInt(_kCoins) ?? 50;

  /// Re-publish coin state (e.g. after the daily bonus wrote the wallet).
  void reload() => notifyListeners();

  Future<void> addCoins(int n) async {
    await _p?.setInt(_kCoins, coins + n);
    notifyListeners();
  }

  Future<bool> spend(int n) async {
    if (coins < n) return false;
    await _p?.setInt(_kCoins, coins - n);
    notifyListeners();
    return true;
  }

  Set<String> get unlocked =>
      (_p?.getStringList(_kUnlocked) ?? const <String>[]).toSet()..add('default');

  bool isUnlocked(String id) => id == 'default' || unlocked.contains(id);

  Future<void> unlock(String id) async {
    final s = unlocked..add(id);
    await _p?.setStringList(_kUnlocked, s.toList());
    notifyListeners();
  }

  String get equippedId => _p?.getString(_kEquipped) ?? 'default';

  Future<void> equip(String id) async {
    await _p?.setString(_kEquipped, id);
    notifyListeners();
  }
}

/// The currently equipped 2048 theme (synchronous, safe to read during paint).
Skin2048 activeSkin2048() => skin2048ById(SkinStore.instance.equippedId);
