import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/user_metrics.dart';

void main() {
  group('UserMetrics', () {
    test('round-trips through JSON', () {
      const original = UserMetrics(
        totalListeningSeconds: 90,
        totalReps: 12,
        dailyRepsHistory: {'2026-09-22': 12},
        dailySecondsHistory: {'2026-09-22': 90},
        dailyPracticedSentenceIds: {
          '2026-09-22': ['s1', 's2'],
        },
        dailyMasteredSpeakingIds: {
          '2026-09-22': ['s1'],
        },
      );

      final restored = UserMetrics.fromJsonString(original.toJsonString());
      expect(restored.totalListeningSeconds, 90);
      expect(restored.totalReps, 12);
      expect(restored.dailyRepsHistory['2026-09-22'], 12);
      expect(restored.dailySecondsHistory['2026-09-22'], 90);
      expect(restored.dailyPracticedSentenceIds['2026-09-22'], ['s1', 's2']);
      expect(restored.dailyMasteredSpeakingIds['2026-09-22'], ['s1']);
    });

    test('fromMap treats missing fields as empty metrics', () {
      final metrics = UserMetrics.fromMap(const {});
      expect(metrics.totalListeningSeconds, 0);
      expect(metrics.totalReps, 0);
      expect(metrics.dailyRepsHistory, isEmpty);
      expect(metrics.dailyPracticedSentenceIds, isEmpty);
    });
  });
}
