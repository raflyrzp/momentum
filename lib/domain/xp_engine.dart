import 'dart:math' as math;

const baseXp = 10;

/// XP untuk satu penyelesaian: +10% per 7 periode streak, maksimal +50%.
int xpForCompletion(int streak) {
  final bonusSteps = math.min(5, streak ~/ 7);
  return (baseXp * (1 + 0.1 * bonusSteps)).round();
}

/// Total XP yang dibutuhkan untuk mencapai [level] (level 1 = 0 XP).
/// Kurva kuadratik: L2 = 100, L3 = 300, L4 = 600, …
int xpToReachLevel(int level) => 50 * (level - 1) * level;

class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.xpIntoLevel,
    required this.xpForLevel,
  });

  factory LevelInfo.fromXp(int xp) {
    var level = 1;
    while (xpToReachLevel(level + 1) <= xp) {
      level++;
    }
    final floor = xpToReachLevel(level);
    return LevelInfo(
      level: level,
      xpIntoLevel: xp - floor,
      xpForLevel: xpToReachLevel(level + 1) - floor,
    );
  }

  final int level;
  final int xpIntoLevel;
  final int xpForLevel;

  double get progress => xpIntoLevel / xpForLevel;
}
