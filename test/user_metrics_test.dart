import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/daily_sentence_entry.dart';
import 'package:language_islands_app/core/models/user_metrics.dart';

void main() {
  group('UserMetrics', () {
    test('round-trips through JSON including dailyDayRatings, dailyNotes, and dailySentenceEntries', () {
      final original = UserMetrics(
        totalListeningSeconds: 90,
        totalReps: 12,
        dailyRepsHistory: const {'2026-09-22': 12},
        dailySecondsHistory: const {'2026-09-22': 90},
        dailyPracticedSentenceIds: const {
          '2026-09-22': ['s1', 's2'],
        },
        dailyMasteredSpeakingIds: const {
          '2026-09-22': ['s1'],
        },
        dailyDayRatings: const {
          '2026-09-22': 4,
        },
        dailyNotes: const {
          '2026-09-22': 'Świetny trening wymowy.',
        },
        dailySentenceEntries: {
          '2026-09-22': [
            DailySentenceEntry(
              sentenceId: 's1',
              targetText: 'こんにちは',
              sourceText: 'Dzień dobry',
              stars: 5,
              mode: 'Active Recall',
              reps: 6,
              timestamp: DateTime.parse('2026-09-22T14:30:00.000Z'),
            ),
          ],
        },
      );

      final restored = UserMetrics.fromJsonString(original.toJsonString());
      expect(restored.totalListeningSeconds, 90);
      expect(restored.totalReps, 12);
      expect(restored.dailyRepsHistory['2026-09-22'], 12);
      expect(restored.dailySecondsHistory['2026-09-22'], 90);
      expect(restored.dailyPracticedSentenceIds['2026-09-22'], ['s1', 's2']);
      expect(restored.dailyMasteredSpeakingIds['2026-09-22'], ['s1']);
      expect(restored.dayRatingOn('2026-09-22'), 4);
      expect(restored.noteOn('2026-09-22'), 'Świetny trening wymowy.');

      final entries = restored.sentenceEntriesOn('2026-09-22');
      expect(entries.length, 1);
      expect(entries.first.sentenceId, 's1');
      expect(entries.first.targetText, 'こんにちは');
      expect(entries.first.sourceText, 'Dzień dobry');
      expect(entries.first.stars, 5);
      expect(entries.first.mode, 'Active Recall');
      expect(entries.first.reps, 6);
    });

    test('fromMap treats missing fields as empty metrics', () {
      final metrics = UserMetrics.fromMap(const {});
      expect(metrics.totalListeningSeconds, 0);
      expect(metrics.totalReps, 0);
      expect(metrics.dailyRepsHistory, isEmpty);
      expect(metrics.dailyPracticedSentenceIds, isEmpty);
      expect(metrics.dailyDayRatings, isEmpty);
      expect(metrics.dailyNotes, isEmpty);
      expect(metrics.dailySentenceEntries, isEmpty);
      expect(metrics.dayRatingOn('2026-09-22'), 0);
      expect(metrics.noteOn('2026-09-22'), '');
      expect(metrics.sentenceEntriesOn('2026-09-22'), isEmpty);
    });

    test('allRecordedDates returns sorted descending date keys', () {
      const metrics = UserMetrics(
        dailyRepsHistory: {'2026-09-20': 5},
        dailyDayRatings: {'2026-09-25': 4},
        dailyNotes: {'2026-09-22': 'Note'},
      );

      expect(metrics.allRecordedDates, ['2026-09-25', '2026-09-22', '2026-09-20']);
    });
  });
}
