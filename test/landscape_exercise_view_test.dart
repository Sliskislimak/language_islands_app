import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/models/user_metrics.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/core/services/audio_playback_service.dart';
import 'package:language_islands_app/core/services/pip_service.dart';
import 'package:language_islands_app/data/repositories/collection_repository.dart';
import 'package:language_islands_app/data/repositories/user_metrics_repository.dart';
import 'package:language_islands_app/features/practice/presentation/practice_session_screen.dart';
import 'package:language_islands_app/features/practice/presentation/screens/focus_mode_screen.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/landscape_exercise_view.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_state.dart';

class _FakeAudioPlaybackService extends AudioPlaybackService {
  @override
  Future<Duration> playFile(String filePath, {double speed = 1.0}) async {
    return const Duration(milliseconds: 500);
  }

  @override
  Future<Duration> playFileUntilComplete(
    String filePath, {
    double speed = 1.0,
  }) async {
    return const Duration(milliseconds: 500);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}
}

class _FakePipService extends PipService {
  @override
  Future<bool> isSupported() async => false;

  @override
  Future<bool> start() async => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> updateContent({
    String? primaryText,
    String? phoneticText,
    String? translationText,
  }) async {}

  @override
  Future<void> clearContent() async {}
}

class _MemoryCollectionRepository extends CollectionRepository {
  final Map<String, SentenceCollection> _collections = {};

  void seed(SentenceCollection collection) {
    _collections[collection.id] = collection;
  }

  @override
  Future<List<SentenceCollection>> loadAll() async =>
      _collections.values.toList();

  @override
  Future<SentenceCollection?> getById(String id) async => _collections[id];

  @override
  Future<void> updateSentence(String collectionId, Sentence sentence) async {
    final col = _collections[collectionId];
    if (col == null) return;
    final list = List<Sentence>.from(col.sentences);
    final idx = list.indexWhere((s) => s.id == sentence.id);
    if (idx >= 0) {
      list[idx] = sentence;
      _collections[collectionId] = col.copyWith(sentences: list);
    }
  }
}

class _FakeUserMetricsRepository extends UserMetricsRepository {
  @override
  Future<UserMetrics> loadMetrics() async => const UserMetrics();

  @override
  Future<void> logSentenceRating({
    required String sentenceId,
    required String targetText,
    required String sourceText,
    required int stars,
    String? mode,
    DateTime? now,
  }) async {}

  @override
  Future<void> logRepetition({
    required int count,
    String? sentenceId,
    String? targetText,
    String? sourceText,
    String? mode,
    DateTime? now,
  }) async {}

  @override
  Future<void> logListeningTime({required int seconds}) async {}

  @override
  Future<void> logSpeakingRating({
    required String sentenceId,
    required int stars,
  }) async {}
}

void main() {
  const testSentence1 = Sentence(
    id: 's1',
    sourceText: 'Dzień dobry',
    targetText: 'おはようございます',
    phoneticReading: 'Ohayou gozaimasu',
    katakana: 'オハヨウゴザイマス',
    comprehensionScore: 3,
    speakingScore: 2,
  );

  const testSentence2 = Sentence(
    id: 's2',
    sourceText: 'Dziękuję bardzo',
    targetText: 'ありがとうございます',
    phoneticReading: 'Arigatou gozaimasu',
    katakana: 'アリガトウゴザイマス',
    comprehensionScore: 5,
    speakingScore: 4,
  );

  const testCollection = SentenceCollection(
    id: 'col_landscape_test',
    title: 'Kolekcja Desk Mode',
    cefrLevel: 'A1',
    tags: ['test'],
    isCustomIsland: false,
    sentences: [testSentence1, testSentence2],
  );

  late ProviderContainer container;
  late _MemoryCollectionRepository memoryRepo;

  setUp(() {
    memoryRepo = _MemoryCollectionRepository();
    memoryRepo.seed(testCollection);

    container = ProviderContainer(
      overrides: [
        audioPlaybackServiceProvider.overrideWithValue(
          _FakeAudioPlaybackService(),
        ),
        pipServiceProvider.overrideWithValue(_FakePipService()),
        collectionRepositoryProvider.overrideWithValue(memoryRepo),
        userMetricsRepositoryProvider.overrideWithValue(
          _FakeUserMetricsRepository(),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  void setLandscape(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
  }

  void setPortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
  }

  group('LandscapeExerciseView Layout and 4-Row Typography', () {
    testWidgets('renders compact top bar and 4 rows in Shadowing mode', (tester) async {
      setLandscape(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      var didExit = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: LandscapeExerciseView(
              onExit: () => didExit = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar elements
      expect(find.byTooltip('Powrót do listy'), findsOneWidget);
      expect(find.text('Shadowing'), findsOneWidget);
      expect(find.text('Recall'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
      expect(find.byTooltip('Poprzednie zdanie'), findsOneWidget);
      expect(find.byTooltip('Odtwarzaj ciągle'), findsOneWidget);
      expect(find.byTooltip('Następne zdanie'), findsOneWidget);
      expect(find.byTooltip('Ustawienia odtwarzacza & audio'), findsOneWidget);

      // Core 4 rows in Shadowing
      expect(find.text('おはようございます'), findsOneWidget); // Row 1: Japanese target
      expect(find.text('オハヨウゴザイマス'), findsOneWidget); // Row 2: Katakana
      expect(find.text('Ohayou gozaimasu'), findsOneWidget); // Row 3: Romaji
      expect(find.text('Dzień dobry'), findsOneWidget); // Row 4: Polish translation

      // Check FittedBox usage for auto-fit scaling
      expect(find.byType(FittedBox), findsWidgets);

      // Test exit button tap
      await tester.tap(find.byTooltip('Powrót do listy'));
      expect(didExit, isTrue);
    });

    testWidgets('conceals Japanese rows in Active Recall before reveal, shows prompt', (tester) async {
      setLandscape(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);
      notifier.setMode(PracticeMode.recall);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: LandscapeExerciseView(onExit: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Unrevealed Active Recall: Japanese is concealed, placeholder is shown
      expect(find.text('• • •   [ Japoński ukryty ]   • • •'), findsOneWidget);
      expect(find.text('Odsłoń odpowiedź (Spacja)'), findsOneWidget);
      expect(find.text('おはようございます'), findsNothing);
      expect(find.text('オハヨウゴザイマス'), findsNothing);
      expect(find.text('Ohayou gozaimasu'), findsNothing);
      expect(find.text('Dzień dobry'), findsOneWidget); // Semantic prompt is visible

      // Tap reveal button
      await tester.tap(find.text('Odsłoń odpowiedź (Spacja)'));
      await tester.pumpAndSettle();

      // Now all 4 rows are revealed
      expect(find.text('おはようございます'), findsOneWidget);
      expect(find.text('オハヨウゴザイマス'), findsOneWidget);
      expect(find.text('Ohayou gozaimasu'), findsOneWidget);
      expect(find.text('Dzień dobry'), findsOneWidget);
      expect(find.text('• • •   [ Japoński ukryty ]   • • •'), findsNothing);
    });

    testWidgets('shows audio highlight badges for active channels', (tester) async {
      setLandscape(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: LandscapeExerciseView(onExit: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Set target audio active
      notifier.updateActiveAudioChannel(ActiveAudioChannel.target);
      await tester.pumpAndSettle();
      expect(find.text('Audio docelowe'), findsOneWidget);

      // Set translation audio active
      notifier.updateActiveAudioChannel(ActiveAudioChannel.translation);
      await tester.pumpAndSettle();
      expect(find.text('Lektor tłumaczenia (PL)'), findsOneWidget);
    });

    testWidgets('star rating updates score and notifier', (tester) async {
      setLandscape(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: LandscapeExerciseView(onExit: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial comprehension score is 3. Stars: index 0 to 4. Tap star 4 (index 3).
      final stars = find.byIcon(Icons.star_rounded);
      expect(stars, findsNWidgets(5));

      await tester.tap(stars.at(3)); // 4 stars
      await tester.pumpAndSettle();

      final current = container.read(practiceSessionProvider);
      final currentSentence = current!.collection.sentences.first;
      expect(currentSentence.comprehensionScore, 4);
    });

    testWidgets('playback skip controls navigate through sentences', (tester) async {
      setLandscape(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: LandscapeExerciseView(onExit: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('おはようございます'), findsOneWidget);

      // Tap Next sentence
      await tester.tap(find.byTooltip('Następne zdanie'));
      await tester.pumpAndSettle();

      expect(find.text('2/2'), findsOneWidget);
      expect(find.text('ありがとうございます'), findsOneWidget);

      // Tap Previous sentence
      await tester.tap(find.byTooltip('Poprzednie zdanie'));
      await tester.pumpAndSettle();

      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('おはようございます'), findsOneWidget);
    });

    testWidgets('keyboard shortcuts support space, arrows, and digits 1-5', (tester) async {
      setLandscape(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: LandscapeExerciseView(onExit: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Press ArrowRight -> skip to s2
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('2/2'), findsOneWidget);

      // Press Digit 2 -> rate s2 with 2 stars
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      expect(
        container
            .read(practiceSessionProvider)!
            .collection
            .sentences[1]
            .comprehensionScore,
        2,
      );

      // Press ArrowLeft -> skip back to s1
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
    });
  });

  group('PracticeSessionScreen Orientation Detection & Continuity', () {
    testWidgets('shows list in portrait, LandscapeExerciseView in landscape, and allows toggle back', (tester) async {
      // 1. Portrait mode
      setPortrait(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PracticeSessionScreen(collection: testCollection),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In portrait, the AppBar shows collection title
      expect(find.text('Kolekcja Desk Mode'), findsOneWidget);
      expect(find.byTooltip('Powrót do listy'), findsNothing);

      // 2. Rotate to landscape
      setLandscape(tester);
      await tester.pumpAndSettle();

      // Now LandscapeExerciseView is active!
      expect(find.byType(LandscapeExerciseView), findsOneWidget);
      expect(find.byTooltip('Powrót do listy'), findsOneWidget);

      // 3. User taps "Powrót do listy" in landscape
      await tester.tap(find.byTooltip('Powrót do listy'));
      await tester.pumpAndSettle();

      // Shows list view in landscape with a Desk Mode toggle icon button
      expect(find.byType(LandscapeExerciseView), findsNothing);
      expect(find.byTooltip('Włącz tryb biurkowy (Landscape)'), findsOneWidget);

      // 4. Tap the Desk Mode button to return to LandscapeExerciseView
      await tester.tap(find.byTooltip('Włącz tryb biurkowy (Landscape)'));
      await tester.pumpAndSettle();

      expect(find.byType(LandscapeExerciseView), findsOneWidget);
    });
  });

  group('FocusModeScreen Orientation Detection', () {
    testWidgets('renders portrait card and switches to LandscapeExerciseView in landscape', (tester) async {
      setPortrait(tester);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FocusModeScreen(initialIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In portrait Focus Mode
      expect(find.byType(LandscapeExerciseView), findsNothing);

      // Rotate to landscape
      setLandscape(tester);
      await tester.pumpAndSettle();

      // Switched to LandscapeExerciseView
      expect(find.byType(LandscapeExerciseView), findsOneWidget);
    });
  });
}
