import 'dart:math';

class Board2048 {
  static const int size = 4;
  List<List<int>> grid =
      List.generate(size, (_) => List.filled(size, 0));
  final _rng = Random();
  int score = 0;
  int previousScore = 0;
  List<List<int>>? _previousGrid;

  void newGame() {
    grid = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    _previousGrid = null;
    _addRandom();
    _addRandom();
  }

  void _addRandom() {
    final empty = <List<int>>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == 0) empty.add([r, c]);
      }
    }
    if (empty.isEmpty) return;
    final spot = empty[_rng.nextInt(empty.length)];
    grid[spot[0]][spot[1]] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  void _saveState() {
    _previousGrid = grid.map((r) => List<int>.from(r)).toList();
    previousScore = score;
  }

  bool undo() {
    if (_previousGrid == null) return false;
    grid = _previousGrid!.map((r) => List<int>.from(r)).toList();
    score = previousScore;
    _previousGrid = null;
    return true;
  }

  // Direction: 0=up, 1=right, 2=down, 3=left
  bool move(int dir) {
    final before = grid.map((r) => List<int>.from(r)).toList();
    final beforeScore = score;
    var moved = false;

    List<int> slide(List<int> row) {
      final out = row.where((v) => v != 0).toList();
      for (var i = 0; i < out.length - 1; i++) {
        if (out[i] == out[i + 1]) {
          out[i] *= 2;
          score += out[i];
          out.removeAt(i + 1);
        }
      }
      while (out.length < size) {
        out.add(0);
      }
      return out;
    }

    for (var i = 0; i < size; i++) {
      List<int> line;
      if (dir == 3) {
        line = grid[i];
      } else if (dir == 1) {
        line = grid[i].reversed.toList();
      } else if (dir == 0) {
        line = [for (var r = 0; r < size; r++) grid[r][i]];
      } else {
        line = [for (var r = size - 1; r >= 0; r--) grid[r][i]];
      }

      final slid = slide(line);

      if (dir == 3) {
        grid[i] = slid;
      } else if (dir == 1) {
        grid[i] = slid.reversed.toList();
      } else if (dir == 0) {
        for (var r = 0; r < size; r++) {
          grid[r][i] = slid[r];
        }
      } else {
        for (var r = 0; r < size; r++) {
          grid[size - 1 - r][i] = slid[r];
        }
      }
    }

    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] != before[r][c]) {
          moved = true;
          break;
        }
      }
      if (moved) break;
    }

    if (moved) {
      // Save state for undo BEFORE the move (use before snapshot)
      _previousGrid = before;
      previousScore = beforeScore;
      _addRandom();
    }
    return moved;
  }

  bool get canMove {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == 0) return true;
        if (c < size - 1 && grid[r][c] == grid[r][c + 1]) return true;
        if (r < size - 1 && grid[r][c] == grid[r + 1][c]) return true;
      }
    }
    return false;
  }

  bool get won {
    for (final row in grid) {
      for (final v in row) {
        if (v >= 2048) return true;
      }
    }
    return false;
  }
}
