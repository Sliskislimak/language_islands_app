class LevelProgress {
  const LevelProgress({
    required this.currentLevel,
    required this.nextLevel,
    required this.progress,
    required this.masteredCount,
    required this.nextLevelTarget,
  });

  final String currentLevel;
  final String nextLevel;
  final double progress;
  final int masteredCount;
  final int nextLevelTarget;
}

/// CEFR bands from 5-star sentence counts. Both tracks share the same
/// thresholds; the source of the count is what separates them.
class LevelCalculator {
  const LevelCalculator._();

  static const List<({String level, int target})> _thresholds = [
    (level: 'A1', target: 100),
    (level: 'A2', target: 300),
    (level: 'B1', target: 700),
    (level: 'B2', target: 1500),
    (level: 'C1', target: 2500),
    (level: 'C2', target: 4000),
  ];

  static LevelProgress calculateComprehension(int fiveStarShadowingCount) {
    return calculate(fiveStarShadowingCount);
  }

  static LevelProgress calculateSpeaking(int fiveStarRecallCount) {
    return calculate(fiveStarRecallCount);
  }

  static LevelProgress calculate(int masteredCount) {
    final count = masteredCount < 0 ? 0 : masteredCount;
    final first = _thresholds.first;
    final last = _thresholds.last;

    if (count >= last.target) {
      return LevelProgress(
        currentLevel: last.level,
        nextLevel: last.level,
        progress: 1.0,
        masteredCount: count,
        nextLevelTarget: last.target,
      );
    }

    if (count < first.target) {
      return LevelProgress(
        currentLevel: 'A0',
        nextLevel: first.level,
        progress: (count / first.target).clamp(0.0, 1.0),
        masteredCount: count,
        nextLevelTarget: first.target,
      );
    }

    var previousLevel = first.level;
    var previousTarget = first.target;
    for (var i = 1; i < _thresholds.length; i++) {
      final band = _thresholds[i];
      if (count < band.target) {
        final span = band.target - previousTarget;
        final gained = count - previousTarget;
        final fraction = span <= 0 ? 1.0 : gained / span;
        return LevelProgress(
          currentLevel: previousLevel,
          nextLevel: band.level,
          progress: fraction.clamp(0.0, 1.0),
          masteredCount: count,
          nextLevelTarget: band.target,
        );
      }
      previousLevel = band.level;
      previousTarget = band.target;
    }

    return LevelProgress(
      currentLevel: last.level,
      nextLevel: last.level,
      progress: 1.0,
      masteredCount: count,
      nextLevelTarget: last.target,
    );
  }
}
