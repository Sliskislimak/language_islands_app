import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/core/services/audio_playback_service.dart';
import 'package:language_islands_app/core/services/pip_service.dart';
import 'package:language_islands_app/data/repositories/collection_repository.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/audio_settings_sheet.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/sentence_card_widget.dart';
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
  Future<List<SentenceCollection>> loadAll() async => _collections.values.toList();

  @override
  Future<SentenceCollection?> getById(String id) async => _collections[id];

  @override
  Future<void> updateSentence(String collectionId, Sentence sentence) async {
    final col = _collections[collectionId];
    if (col == null) return;
    final updated = col.sentences.map((s) => s.id == sentence.id ? sentence : s).toList();
    _collections[collectionId] = col.copyWith(sentences: updated);
  }
}

void main() {
  const testSentence1 = Sentence(
    id: 's1',
    sourceText: 'Dzień dobry',
    targetText: 'おはようございます',
    phoneticReading: 'Ohayou gozaimasu',
    katakana: 'オハヨウゴザイマス',
  );

  const testSentence2 = Sentence(
    id: 's2',
    sourceText: 'Dziękuję bardzo',
    targetText: 'ありがとうございます',
    phoneticReading: 'Arigatou gozaimasu',
    katakana: 'アリガトウゴザイマス',
  );

  const testCollection = SentenceCollection(
    id: 'col_audio_test',
    title: 'Wyspa Testowa Audio',
    cefrLevel: 'A1',
    tags: ['test'],
    isCustomIsland: false,
    sentences: [testSentence1, testSentence2],
  );

  group('AudioTranslationMode and ActiveAudioChannel Enums', () {
    test('AudioTranslationMode labels and shortLabels', () {
      expect(AudioTranslationMode.disabled.label, 'Wyłączone');
      expect(AudioTranslationMode.prefix.label, 'Tłumaczenie na początku');
      expect(AudioTranslationMode.alternating.label, 'Naprzemiennie');

      expect(AudioTranslationMode.disabled.shortLabel, 'Tylko JP');
      expect(AudioTranslationMode.prefix.shortLabel, '1x PL → N× JP');
      expect(AudioTranslationMode.alternating.shortLabel, 'PL ⇄ JP');
    });

    test('AudioTranslationMode.next cycles sequentially', () {
      expect(AudioTranslationMode.disabled.next, AudioTranslationMode.prefix);
      expect(AudioTranslationMode.prefix.next, AudioTranslationMode.alternating);
      expect(AudioTranslationMode.alternating.next, AudioTranslationMode.disabled);
    });

    test('ActiveAudioChannel properties and flags', () {
      expect(ActiveAudioChannel.none.isTranslation, isFalse);
      expect(ActiveAudioChannel.none.isTarget, isFalse);

      expect(ActiveAudioChannel.translation.isTranslation, isTrue);
      expect(ActiveAudioChannel.translation.isTarget, isFalse);

      expect(ActiveAudioChannel.target.isTranslation, isFalse);
      expect(ActiveAudioChannel.target.isTarget, isTrue);
    });
  });

  group('Sentence translationAudioPath serialization', () {
    test('Sentence constructor, copyWith, toMap, and fromMap', () {
      final sentence = const Sentence(
        id: 's_trans',
        sourceText: 'Do widzenia',
        targetText: 'さようなら',
        translationAudioPath: '/cache/audio/s_trans_pl.wav',
      );

      expect(sentence.translationAudioPath, '/cache/audio/s_trans_pl.wav');

      final map = sentence.toMap();
      expect(map['translationAudioPath'], '/cache/audio/s_trans_pl.wav');

      final fromMap1 = Sentence.fromMap(map);
      expect(fromMap1.translationAudioPath, '/cache/audio/s_trans_pl.wav');

      // Test backwards-compatible aliases
      final fromAlias1 = Sentence.fromMap({
        'id': 's_alias',
        'sourceText': 'PL',
        'targetText': 'JP',
        'translationAudio': '/audio/alias.wav',
      });
      expect(fromAlias1.translationAudioPath, '/audio/alias.wav');

      final fromAlias2 = Sentence.fromMap({
        'id': 's_alias2',
        'sourceText': 'PL',
        'targetText': 'JP',
        'sourceAudioPath': '/audio/source.wav',
      });
      expect(fromAlias2.translationAudioPath, '/audio/source.wav');

      final copied = sentence.copyWith(
        translationAudioPath: '/cache/audio/new_pl.wav',
      );
      expect(copied.translationAudioPath, '/cache/audio/new_pl.wav');
      expect(copied.targetText, 'さようなら');
    });
  });

  group('PracticeSessionState Audio Translation Settings', () {
    test('Initial defaults reflect required Active Recall parameters', () {
      final state = const PracticeSessionState(
        collection: testCollection,
        mode: PracticeMode.shadowing,
      );

      expect(state.audioTranslationMode, AudioTranslationMode.disabled);
      expect(state.activeAudioChannel, ActiveAudioChannel.none);
      expect(state.repsPerSentence, 3);
      expect(state.targetReps, 3);
      expect(state.pauseBetweenLanguages, const Duration(milliseconds: 1500));
      expect(state.pauseBetweenLanguagesMs, 1500);
      expect(state.pauseBetweenReps, const Duration(milliseconds: 1000));
      expect(state.pauseBetweenRepsMs, 1000);
      expect(state.pauseBetweenSentences, const Duration(milliseconds: 1500));
      expect(state.pauseBetweenSentencesMs, 1500);
      expect(state.playbackSpeed, 1.0);
    });

    test('copyWith properly updates all audio translation parameters', () {
      final state = const PracticeSessionState(
        collection: testCollection,
        mode: PracticeMode.shadowing,
      );

      final updated = state.copyWith(
        audioTranslationMode: AudioTranslationMode.prefix,
        activeAudioChannel: ActiveAudioChannel.translation,
        repsPerSentence: 4,
        pauseBetweenLanguages: const Duration(milliseconds: 2000),
        pauseBetweenSentences: const Duration(milliseconds: 2500),
      );

      expect(updated.audioTranslationMode, AudioTranslationMode.prefix);
      expect(updated.activeAudioChannel, ActiveAudioChannel.translation);
      expect(updated.targetReps, 4);
      expect(updated.pauseBetweenLanguagesMs, 2000);
      expect(updated.pauseBetweenSentencesMs, 2500);
    });
  });

  group('PracticeSessionNotifier Audio Controls and Queues', () {
    late ProviderContainer container;
    late _MemoryCollectionRepository repo;

    setUp(() {
      repo = _MemoryCollectionRepository();
      repo.seed(testCollection);

      container = ProviderContainer(
        overrides: [
          collectionRepositoryProvider.overrideWithValue(repo),
          audioPlaybackServiceProvider.overrideWithValue(_FakeAudioPlaybackService()),
          pipServiceProvider.overrideWithValue(_FakePipService()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('setAudioTranslationMode and cycleAudioTranslationMode', () {
      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      expect(
        container.read(practiceSessionProvider)!.audioTranslationMode,
        AudioTranslationMode.disabled,
      );

      notifier.setAudioTranslationMode(AudioTranslationMode.prefix);
      expect(
        container.read(practiceSessionProvider)!.audioTranslationMode,
        AudioTranslationMode.prefix,
      );

      notifier.cycleAudioTranslationMode();
      expect(
        container.read(practiceSessionProvider)!.audioTranslationMode,
        AudioTranslationMode.alternating,
      );

      notifier.cycleAudioTranslationMode();
      expect(
        container.read(practiceSessionProvider)!.audioTranslationMode,
        AudioTranslationMode.disabled,
      );
    });

    test('setTargetReps and reps clamping between 1 and 5', () {
      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      notifier.setTargetReps(4);
      expect(container.read(practiceSessionProvider)!.targetReps, 4);

      notifier.setTargetReps(10);
      expect(container.read(practiceSessionProvider)!.targetReps, 5);

      notifier.setTargetReps(-2);
      expect(container.read(practiceSessionProvider)!.targetReps, 1);

      notifier.cycleRepsPerSentence();
      expect(container.read(practiceSessionProvider)!.targetReps, 2);
    });

    test('pause durations clamping within configured bounds', () {
      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      // pauseBetweenLanguages (500 ms - 3000 ms)
      notifier.setPauseBetweenLanguages(const Duration(milliseconds: 2250));
      expect(
        container.read(practiceSessionProvider)!.pauseBetweenLanguagesMs,
        2250,
      );

      notifier.setPauseBetweenLanguages(const Duration(milliseconds: 100));
      expect(
        container.read(practiceSessionProvider)!.pauseBetweenLanguagesMs,
        500,
      );

      notifier.setPauseBetweenLanguages(const Duration(milliseconds: 5000));
      expect(
        container.read(practiceSessionProvider)!.pauseBetweenLanguagesMs,
        3000,
      );

      // pauseBetweenSentences (500 ms - 4000 ms)
      notifier.setPauseBetweenSentences(const Duration(milliseconds: 2500));
      expect(
        container.read(practiceSessionProvider)!.pauseBetweenSentencesMs,
        2500,
      );

      notifier.setPauseBetweenSentences(const Duration(milliseconds: 100));
      expect(
        container.read(practiceSessionProvider)!.pauseBetweenSentencesMs,
        500,
      );

      notifier.setPauseBetweenSentences(const Duration(milliseconds: 6000));
      expect(
        container.read(practiceSessionProvider)!.pauseBetweenSentencesMs,
        4000,
      );
    });

    test('skipToNextSentence and skipToPreviousSentence navigate without audio overlap', () {
      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(testCollection);

      expect(container.read(practiceSessionProvider)!.activeSentenceId, 's1');

      notifier.skipToNextSentence();
      expect(container.read(practiceSessionProvider)!.activeSentenceId, 's2');

      notifier.skipToNextSentence();
      expect(container.read(practiceSessionProvider)!.activeSentenceId, 's1');

      notifier.skipToPreviousSentence();
      expect(container.read(practiceSessionProvider)!.activeSentenceId, 's2');
    });
  });

  group('AudioSettingsSheet UI', () {
    testWidgets('renders all controls and updates state on selection', (tester) async {
      final repo = _MemoryCollectionRepository();
      repo.seed(testCollection);

      final container = ProviderContainer(
        overrides: [
          collectionRepositoryProvider.overrideWithValue(repo),
          audioPlaybackServiceProvider.overrideWithValue(_FakeAudioPlaybackService()),
          pipServiceProvider.overrideWithValue(_FakePipService()),
        ],
      );
      addTearDown(container.dispose);

      container.read(practiceSessionProvider.notifier).startSession(testCollection);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => showAudioSettingsSheet(context, ref),
                    child: const Text('Open Settings'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Lektor Tłumaczenia & Audio'), findsOneWidget);
      expect(find.text('TRYB LEKTORA TŁUMACZENIA'), findsOneWidget);
      expect(find.text('POWTÓRZENIA ZDANIA DOCELOWEGO (1 – 5)'), findsOneWidget);
      expect(find.text('PAUZA MIĘDZY JĘZYKAMI (ACTIVE RECALL BUFFER)'), findsOneWidget);

      // Check segmented control buttons
      expect(find.text('Wyłączone'), findsOneWidget);
      expect(find.text('Tłumaczenie na początku'), findsOneWidget);
      expect(find.text('Naprzemiennie'), findsOneWidget);

      // Select 'Tłumaczenie na początku'
      await tester.tap(find.text('Tłumaczenie na początku'));
      await tester.pumpAndSettle();

      expect(
        container.read(practiceSessionProvider)!.audioTranslationMode,
        AudioTranslationMode.prefix,
      );

      // Select 'Naprzemiennie'
      await tester.tap(find.text('Naprzemiennie'));
      await tester.pumpAndSettle();

      expect(
        container.read(practiceSessionProvider)!.audioTranslationMode,
        AudioTranslationMode.alternating,
      );
    });
  });

  group('SentenceCardWidget Channel Visual Highlighting', () {
    testWidgets('highlights translation text when ActiveAudioChannel.translation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceCardWidget(
              sentence: testSentence1,
              displayIndex: 1,
              isActive: true,
              isRevealed: true,
              currentMode: PracticeMode.shadowing,
              onPlayAudio: () {},
              onToggleReveal: () {},
              onRate: (_) {},
              activeAudioChannel: ActiveAudioChannel.translation,
            ),
          ),
        ),
      );

      expect(find.textContaining('Tłumaczenie (Lektor PL)'), findsOneWidget);
      expect(find.text('Dzień dobry'), findsOneWidget);
    });

    testWidgets('highlights target text when ActiveAudioChannel.target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceCardWidget(
              sentence: testSentence1,
              displayIndex: 1,
              isActive: true,
              isRevealed: true,
              currentMode: PracticeMode.shadowing,
              onPlayAudio: () {},
              onToggleReveal: () {},
              onRate: (_) {},
              activeAudioChannel: ActiveAudioChannel.target,
            ),
          ),
        ),
      );

      expect(find.text('Japoński (Audio docelowe)'), findsOneWidget);
      expect(find.text('おはようございます'), findsOneWidget);
    });
  });
}
