import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/features/metrics/domain/level_calculator.dart';

void main() {
  group('LevelCalculator', () {
    test('stays at A0 until 100 five-star sentences', () {
      final progress = LevelCalculator.calculateComprehension(50);
      expect(progress.currentLevel, 'A0');
      expect(progress.nextLevel, 'A1');
      expect(progress.nextLevelTarget, 100);
      expect(progress.progress, 0.5);
      expect(progress.masteredCount, 50);
    });

    test('unlocks A1 at 100 and measures progress toward A2', () {
      final atThreshold = LevelCalculator.calculateSpeaking(100);
      expect(atThreshold.currentLevel, 'A1');
      expect(atThreshold.nextLevel, 'A2');
      expect(atThreshold.progress, 0.0);
      expect(atThreshold.nextLevelTarget, 300);

      final mid = LevelCalculator.calculateSpeaking(200);
      expect(mid.currentLevel, 'A1');
      expect(mid.nextLevel, 'A2');
      expect(mid.progress, 0.5);
    });

    test('reaches C2 at 4000', () {
      final progress = LevelCalculator.calculate(4000);
      expect(progress.currentLevel, 'C2');
      expect(progress.nextLevel, 'C2');
      expect(progress.progress, 1.0);
      expect(progress.nextLevelTarget, 4000);
    });
  });
}
