import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/daily_sentence_entry.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/models/user_metrics.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/data/repositories/user_metrics_repository.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/metrics/presentation/screens/daily_history_screen.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/sentence_card_widget.dart';

class _TestCollectionsController extends CollectionsController {
  @override
  Future<List<SentenceCollection>> build() async => [
        const SentenceCollection(
          id: 'col_1',
          title: 'Wyspa Powitań',
          cefrLevel: 'A1',
          tags: ['greeting'],
          isCustomIsland: false,
          sentences: [],
        ),
      ];
}

void main() {
  group('Daily History in UserMetricsRepository', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('user_metrics_repo_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('logSentenceRating and saveDayRating and saveDailyNote record properly', () async {
      final repo = UserMetricsRepository(
        metricsFileOverride: File('${tempDir.path}/user_metrics.json'),
      );
      final date = DateTime(2026, 9, 30);
      final dateKey = UserMetrics.dateKey(date);

      // Log a sentence rating
      await repo.logSentenceRating(
        sentenceId: 'sent_1',
        targetText: 'すみません',
        sourceText: 'Przepraszam',
        stars: 4,
        mode: 'Shadowing',
        now: date,
      );

      // Log reps for that sentence
      await repo.logRepetition(
        count: 3,
        sentenceId: 'sent_1',
        targetText: 'すみません',
        sourceText: 'Przepraszam',
        mode: 'Shadowing',
        now: date,
      );

      // Save day rating and note
      await repo.saveDayRating(dateKey: dateKey, stars: 5);
      await repo.saveDailyNote(dateKey: dateKey, note: 'Bardzo udany trening.');

      final metrics = await repo.loadMetrics();
      expect(metrics.dayRatingOn(dateKey), 5);
      expect(metrics.noteOn(dateKey), 'Bardzo udany trening.');
      expect(metrics.repsOn(dateKey), 3);

      final entries = metrics.sentenceEntriesOn(dateKey);
      expect(entries.length, 1);
      expect(entries.first.sentenceId, 'sent_1');
      expect(entries.first.targetText, 'すみません');
      expect(entries.first.sourceText, 'Przepraszam');
      expect(entries.first.stars, 4);
      expect(entries.first.reps, 3);
      expect(entries.first.mode, 'Shadowing');
    });
  });

  group('Rating Stars Size & Tapping', () {
    testWidgets('SentenceCardWidget star rating has larger size (28) and responds to tap', (tester) async {
      int ratedStars = 0;
      const sentence = Sentence(
        id: 's_test_1',
        targetText: 'ありがとう',
        sourceText: 'Dziękuję',
        comprehensionScore: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceCardWidget(
              sentence: sentence,
              displayIndex: 1,
              isActive: true,
              isRevealed: false,
              currentMode: PracticeMode.shadowing,
              onPlayAudio: () {},
              onToggleReveal: () {},
              onRate: (stars) => ratedStars = stars,
            ),
          ),
        ),
      );

      // Find all star icons
      final starIcons = tester.widgetList<Icon>(find.byIcon(Icons.star_rounded)).toList();
      expect(starIcons.isNotEmpty, isTrue);

      // Check star icon size is 28 (enlarged from 18)
      expect(starIcons.first.size, 28);

      // Tap on the 5th star
      final fifthStarFinder = find.ancestor(
        of: find.byIcon(Icons.star_rounded),
        matching: find.byType(InkWell),
      );
      expect(fifthStarFinder, findsNWidgets(5));

      await tester.tap(fifthStarFinder.at(4));
      await tester.pumpAndSettle();

      expect(ratedStars, 5);
    });
  });

  group('DailyHistoryScreen UI', () {
    testWidgets('displays date navigation, rating, stats, notes, and sentence entries', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testDate = DateTime(2026, 9, 30);
      final testDateKey = UserMetrics.dateKey(testDate);

      final initialMetrics = UserMetrics(
        dailyRepsHistory: {testDateKey: 15},
        dailySecondsHistory: {testDateKey: 300},
        dailyDayRatings: {testDateKey: 4},
        dailyNotes: {testDateKey: 'Dobra sesja poranna.'},
        dailySentenceEntries: {
          testDateKey: [
            DailySentenceEntry(
              sentenceId: 'sent_test',
              targetText: 'おはようございます',
              sourceText: 'Dzień dobry (rano)',
              stars: 5,
              mode: 'Active Recall',
              reps: 8,
              timestamp: testDate,
            ),
          ],
        },
      );

      final fakeRepo = _InMemoryMetricsRepository(initialMetrics);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userMetricsRepositoryProvider.overrideWithValue(fakeRepo),
            collectionsControllerProvider.overrideWith(_TestCollectionsController.new),
          ],
          child: MaterialApp(
            home: DailyHistoryScreen(initialDate: testDate),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify date navigation is visible
      expect(find.text('OCENA TEGO DNIA'), findsOneWidget);
      expect(find.text('4 / 5 ★'), findsOneWidget);

      // Verify stats
      expect(find.text('POWTÓRZENIA'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('OCENIONE ZDANIA'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2)); // in stat tile and count badge

      // Verify note loaded in text field
      expect(find.text('NOTATKA Z DNIA'), findsOneWidget);
      expect(find.text('Dobra sesja poranna.'), findsOneWidget);

      // Verify sentence entry card
      expect(find.text('HISTORIA ZDAŃ I OCEN'), findsOneWidget);
      expect(find.text('おはようございます'), findsOneWidget);
      expect(find.text('Dzień dobry (rano)'), findsOneWidget);
      expect(find.text('8 powt.'), findsOneWidget);
      expect(find.text('Active Recall'), findsOneWidget);
      expect(find.text('5★'), findsOneWidget);

      // Tap 5th star in day rating
      final dayRatingStarIcons = find.descendant(
        of: find.byType(DailyHistoryScreen),
        matching: find.byIcon(Icons.star_rounded),
      );
      // We have 5 day rating stars (size 38) + 5 sentence stars (size 18)
      final size38Stars = tester.widgetList<Icon>(dayRatingStarIcons).where((i) => i.size == 38).toList();
      expect(size38Stars.length, 5);

      // Edit note and click save
      await tester.enterText(find.byType(TextField), 'Zaktualizowana notatka wieczorem.');
      await tester.tap(find.text('Zapisz notatkę'));
      await tester.pumpAndSettle();

      expect(find.text('Zapisano'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(fakeRepo.currentMetrics.noteOn(testDateKey), 'Zaktualizowana notatka wieczorem.');
    });
  });
}

class _InMemoryMetricsRepository extends UserMetricsRepository {
  _InMemoryMetricsRepository(this._metrics);

  UserMetrics _metrics;

  UserMetrics get currentMetrics => _metrics;

  @override
  Future<UserMetrics> loadMetrics() async {
    return _metrics;
  }

  @override
  Future<void> saveDayRating({required String dateKey, required int stars}) async {
    final nextRatings = Map<String, int>.from(_metrics.dailyDayRatings);
    nextRatings[dateKey] = stars;
    _metrics = _metrics.copyWith(dailyDayRatings: nextRatings);
  }

  @override
  Future<void> saveDailyNote({required String dateKey, required String note}) async {
    final nextNotes = Map<String, String>.from(_metrics.dailyNotes);
    nextNotes[dateKey] = note;
    _metrics = _metrics.copyWith(dailyNotes: nextNotes);
  }

  @override
  Future<void> logSentenceRating({
    required String sentenceId,
    required String targetText,
    required String sourceText,
    required int stars,
    String? mode,
    DateTime? now,
  }) async {
    final effectiveDate = now ?? DateTime.now();
    final today = UserMetrics.dateKey(effectiveDate);
    final nextEntries = Map<String, List<DailySentenceEntry>>.from(_metrics.dailySentenceEntries);
    final list = List<DailySentenceEntry>.from(nextEntries[today] ?? const []);
    list.add(
      DailySentenceEntry(
        sentenceId: sentenceId,
        targetText: targetText,
        sourceText: sourceText,
        stars: stars,
        mode: mode,
        reps: 0,
        timestamp: effectiveDate,
      ),
    );
    nextEntries[today] = list;
    _metrics = _metrics.copyWith(dailySentenceEntries: nextEntries);
  }

  @override
  Future<void> logRepetition({
    required int count,
    String? sentenceId,
    String? targetText,
    String? sourceText,
    String? mode,
    DateTime? now,
  }) async {
    final effectiveDate = now ?? DateTime.now();
    final today = UserMetrics.dateKey(effectiveDate);
    final nextReps = Map<String, int>.from(_metrics.dailyRepsHistory);
    nextReps[today] = (nextReps[today] ?? 0) + count;
    _metrics = _metrics.copyWith(
      totalReps: _metrics.totalReps + count,
      dailyRepsHistory: nextReps,
    );
  }
}
