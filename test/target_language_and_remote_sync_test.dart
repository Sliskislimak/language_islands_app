import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/audio_translation_mode.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/remote_database_config.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/data/repositories/collection_repository.dart';
import 'package:language_islands_app/data/repositories/remote_database_repository.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/features/collections/presentation/add_sentence_for_friend_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/collections_screen.dart';
import 'package:language_islands_app/features/collections/presentation/remote_sync_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/select_target_language_dialog.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/sentence_card_widget.dart';

class _FakeCollectionRepository extends CollectionRepository {
  final Map<String, SentenceCollection> _collections = {};

  Future<List<SentenceCollection>> getAll() async => _collections.values.toList();

  @override
  Future<List<SentenceCollection>> loadAll() async => getAll();

  @override
  Future<SentenceCollection?> getById(String id) async => _collections[id];

  Future<void> save(SentenceCollection collection) async {
    _collections[collection.id] = collection;
  }

  @override
  Future<void> updateCollection(SentenceCollection collection) async {
    _collections[collection.id] = collection;
  }

  @override
  Future<void> updateSentence(String collectionId, Sentence sentence) async {
    final col = _collections[collectionId];
    if (col == null) return;
    final updated = col.sentences.map((s) => s.id == sentence.id ? sentence : s).toList();
    _collections[collectionId] = col.copyWith(sentences: updated);
  }

  Future<void> delete(String id) async {
    _collections.remove(id);
  }

  @override
  Future<void> deleteCollection(String id) async {
    _collections.remove(id);
  }

  Future<void> clearAll() async {
    _collections.clear();
  }
}

void main() {
  group('Target Language (Polish & Japanese) Core Tests', () {
    test('AppLanguage contains Polish and Japanese with correct neural voices', () {
      final polish = AppLanguage.polish;
      expect(polish.code, equals('pl'));
      expect(polish.name, equals('Polski'));
      expect(polish.flagEmoji, equals('🇵🇱'));
      expect(polish.voiceName, equals('pl-PL-MarekNeural'));
      expect(polish.locale, equals('pl-PL'));
      expect(polish.voiceDisplayName, equals('Marek'));

      final japanese = AppLanguage.japanese;
      expect(japanese.code, equals('ja'));
      expect(japanese.name, equals('Japoński'));
      expect(japanese.flagEmoji, equals('🇯🇵'));
      expect(japanese.voiceName, equals('ja-JP-NanamiNeural'));

      expect(AppLanguage.defaultUnlockedCodes, contains('pl'));
      expect(AppLanguage.defaultUnlockedCodes, contains('ja'));
      expect(AppLanguage.defaultUnlockedCodes, contains('en'));

      expect(AppLanguage.find('pl'), equals(polish));
      expect(AppLanguage.find('ja'), equals(japanese));
    });

    test('SentenceCollection handles targetLanguage, remoteSourceUrl, and effectiveTargetLanguage', () {
      const defaultCol = SentenceCollection(
        id: 'c1',
        title: 'Lekcja 1',
        cefrLevel: 'A1',
        tags: [],
        isCustomIsland: false,
        sentences: [],
      );
      expect(defaultCol.effectiveTargetLanguage, equals('ja'));
      expect(defaultCol.effectiveTranslationLanguage, equals('en'));

      final polishCol = defaultCol.copyWith(
        targetLanguage: 'pl',
        translationLanguage: 'ja',
        remoteSourceUrl: 'https://api.example.com/sentences.json',
      );
      expect(polishCol.targetLanguage, equals('pl'));
      expect(polishCol.effectiveTargetLanguage, equals('pl'));
      expect(polishCol.translationLanguage, equals('ja'));
      expect(polishCol.effectiveTranslationLanguage, equals('ja'));
      expect(polishCol.remoteSourceUrl, equals('https://api.example.com/sentences.json'));

      final map = polishCol.toMap();
      expect(map['targetLanguage'], equals('pl'));
      expect(map['translationLanguage'], equals('ja'));
      expect(map['remoteSourceUrl'], equals('https://api.example.com/sentences.json'));

      final deserialized = SentenceCollection.fromMap(map);
      expect(deserialized.targetLanguage, equals('pl'));
      expect(deserialized.translationLanguage, equals('ja'));
      expect(deserialized.remoteSourceUrl, equals('https://api.example.com/sentences.json'));
    });

    testWidgets('SentenceCardWidget displays dynamic target language audio label', (tester) async {
      const polishSentence = Sentence(
        id: 's_pl',
        targetText: 'Dzień dobry, jak się masz?',
        sourceText: 'おはようございます、お元気ですか？',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceCardWidget(
              sentence: polishSentence,
              displayIndex: 1,
              isActive: true,
              isRevealed: true,
              currentMode: PracticeMode.shadowing,
              targetLanguageCode: 'pl',
              activeAudioChannel: ActiveAudioChannel.target,
              onPlayAudio: () {},
              onToggleReveal: () {},
              onRate: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Polski (Audio docelowe)'), findsOneWidget);
      expect(find.text('Dzień dobry, jak się masz?'), findsOneWidget);
    });
  });

  group('Remote Database Repository & Sync Tests', () {
    test('parseCollectionsFromJson parses array of collections', () {
      final repo = RemoteDatabaseRepository();
      final json = [
        {
          'id': 'col_pl_1',
          'title': 'Polski A1 Podstawy',
          'cefrLevel': 'A1',
          'targetLanguage': 'pl',
          'translationLanguage': 'ja',
          'sentences': [
            {
              'id': 's1',
              'targetText': 'Dzień dobry!',
              'sourceText': 'おはようございます！',
            },
            {
              'id': 's2',
              'targetText': 'Dziękuję bardzo.',
              'sourceText': 'どうもありがとうございます。',
            }
          ]
        }
      ];

      final parsed = repo.parseCollectionsFromJson(json, fallbackSourceUrl: 'https://example.com');
      expect(parsed.length, equals(1));
      expect(parsed.first.id, equals('col_pl_1'));
      expect(parsed.first.title, equals('Polski A1 Podstawy'));
      expect(parsed.first.targetLanguage, equals('pl'));
      expect(parsed.first.translationLanguage, equals('ja'));
      expect(parsed.first.sentences.length, equals(2));
      expect(parsed.first.sentences.first.targetText, equals('Dzień dobry!'));
    });

    test('parseCollectionsFromJson parses flat table of sentences (e.g. Supabase table)', () {
      final repo = RemoteDatabaseRepository();
      final flatJson = [
        {
          'id': 's1',
          'collection_id': 'remote_island_food',
          'target_text': 'Poproszę kawę bez mleka.',
          'source_text': 'ミルクなしのコーヒーをください。',
        },
        {
          'id': 's2',
          'collection_id': 'remote_island_food',
          'target_text': 'Ile to kosztuje?',
          'source_text': 'これはいくらですか？',
        }
      ];

      final parsed = repo.parseCollectionsFromJson(flatJson);
      expect(parsed.length, equals(1));
      expect(parsed.first.id, equals('remote_island_food'));
      expect(parsed.first.sentences.length, equals(2));
      expect(parsed.first.sentences.first.targetText, equals('Poproszę kawę bez mleka.'));
    });

    test('syncAll merges incoming remote sentences while strictly preserving local user progress', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'https://my-db.com/sentences.json') {
          final payload = [
            {
              'id': 'c_travel',
              'title': 'Podróże i Rozmówki',
              'cefrLevel': 'A1',
              'targetLanguage': 'pl',
              'translationLanguage': 'ja',
              'sentences': [
                {
                  'id': 's_train',
                  'targetText': 'Gdzie jest dworzec kolejowy?',
                  'sourceText': '駅はどこですか？',
                },
                {
                  'id': 's_ticket',
                  'targetText': 'Jeden bilet do Krakowa, proszę.',
                  'sourceText': 'クラクフまでの切符を1枚お願いします。',
                }
              ]
            }
          ];
          return http.Response(jsonEncode(payload), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final localRepo = _FakeCollectionRepository();
      // Setup existing collection with user stars and reps on s_train
      const initialLocalSentence = Sentence(
        id: 's_train',
        targetText: 'Gdzie jest dworzec?', // older phrasing
        sourceText: '駅はどこですか？',
        comprehensionScore: 5,
        speakingScore: 4,
        totalReps: 15,
        targetAudioPath: '/local/cache/target_s_train.mp3',
        notes: 'Ważne pytanie w podróży!',
      );
      await localRepo.save(
        const SentenceCollection(
          id: 'c_travel',
          title: 'Podróże',
          cefrLevel: 'A1',
          tags: [],
          isCustomIsland: false,
          sentences: [initialLocalSentence],
        ),
      );

      final remoteRepo = RemoteDatabaseRepository(client: mockClient);
      final result = await remoteRepo.syncAll(
        collectionRepo: localRepo,
        overrideUrl: 'https://my-db.com/sentences.json',
      );

      expect(result.success, isTrue);
      expect(result.collectionsCount, equals(1));
      expect(result.newSentencesCount, equals(1)); // s_ticket was added
      expect(result.updatedSentencesCount, equals(1)); // s_train was updated

      final syncedCollection = await localRepo.getById('c_travel');
      expect(syncedCollection, isNotNull);
      expect(syncedCollection!.sentences.length, equals(2));

      final trainSentence = syncedCollection.sentences.firstWhere((s) => s.id == 's_train');
      // Incoming updated text was merged
      expect(trainSentence.targetText, equals('Gdzie jest dworzec kolejowy?'));
      // Local ratings & reps were strictly preserved!
      expect(trainSentence.comprehensionScore, equals(5));
      expect(trainSentence.speakingScore, equals(4));
      expect(trainSentence.totalReps, equals(15));
      expect(trainSentence.targetAudioPath, equals('/local/cache/target_s_train.mp3'));
      expect(trainSentence.notes, equals('Ważne pytanie w podróży!'));

      // New sentence was added
      final ticketSentence = syncedCollection.sentences.firstWhere((s) => s.id == 's_ticket');
      expect(ticketSentence.targetText, equals('Jeden bilet do Krakowa, proszę.'));
      expect(ticketSentence.totalReps, equals(0));
    });

    test('syncAll returns error message on network failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final localRepo = _FakeCollectionRepository();
      final remoteRepo = RemoteDatabaseRepository(client: mockClient);

      final result = await remoteRepo.syncAll(
        collectionRepo: localRepo,
        overrideUrl: 'https://bad-url.com/api',
      );

      expect(result.success, isFalse);
      expect(result.message, contains('Błąd synchronizacji'));
    });

    test('pushCollectionsToRemote sends PATCH request to GitHub Gist with correct headers and payload', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH' && request.url.toString() == 'https://api.github.com/gists/gist_test_123') {
          capturedRequest = request;
          return http.Response(jsonEncode({'id': 'gist_test_123'}), 200, headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final remoteRepo = RemoteDatabaseRepository(client: mockClient);
      const testCol = SentenceCollection(
        id: 'shared_col',
        title: 'Wspólna lista',
        cefrLevel: 'A1',
        tags: ['shared'],
        isCustomIsland: true,
        sentences: [
          Sentence(
            id: 's_001',
            targetText: 'Jak się masz?',
            katakana: 'ヤク シェ マシュ？',
            sourceText: 'お元気ですか？',
          ),
        ],
      );

      final result = await remoteRepo.pushCollectionsToRemote(
        collections: [testCol],
        overrideUrl: 'https://gist.github.com/jakub/gist_test_123',
        overrideApiKey: 'ghp_secret_token_123',
      );

      expect(result.success, isTrue);
      expect(result.message, contains('GitHub Gist'));
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.headers['authorization'], equals('Bearer ghp_secret_token_123'));
      expect(capturedRequest!.headers['accept'], contains('application/vnd.github+json'));

      final decodedBody = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(decodedBody.containsKey('files'), isTrue);
      final files = decodedBody['files'] as Map<String, dynamic>;
      expect(files.containsKey('sentences.json'), isTrue);
      final contentStr = files['sentences.json']['content'] as String;
      expect(contentStr, contains('Jak się masz?'));
    });

    test('addSentenceAndSync fetches existing remote, merges new bilingual phrase, and pushes to GitHub Gist', () async {
      var patchCalled = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.toString() == 'https://api.github.com/gists/gist_test_456') {
          final existing = [
            {
              'id': 'shared_col',
              'title': 'Wspólna lista',
              'cefrLevel': 'A1',
              'sentences': [
                {
                  'id': 's_old',
                  'targetText': 'Dzień dobry!',
                  'sourceText': 'こんにちは！',
                }
              ]
            }
          ];
          final gistJson = {
            'id': 'gist_test_456',
            'files': {
              'sentences.json': {
                'filename': 'sentences.json',
                'content': jsonEncode(existing),
              }
            }
          };
          return http.Response(jsonEncode(gistJson), 200, headers: {'content-type': 'application/json'});
        }

        if (request.method == 'PATCH' && request.url.toString() == 'https://api.github.com/gists/gist_test_456') {
          patchCalled = true;
          return http.Response(jsonEncode({'id': 'gist_test_456'}), 200, headers: {'content-type': 'application/json'});
        }

        return http.Response('Not Found', 404);
      });

      final localRepo = _FakeCollectionRepository();
      final remoteRepo = RemoteDatabaseRepository(client: mockClient);

      const newSentence = Sentence(
        id: 's_new',
        targetText: 'Dziękuję bardzo!',
        katakana: 'ジンクイェ バルドゾ！',
        phoneticReading: 'Dzyen-koo-yeh bard-zoh',
        sourceText: 'どうもありがとうございます！',
        notes: 'Uprzejme podziękowanie.',
      );

      final result = await remoteRepo.addSentenceAndSync(
        sentence: newSentence,
        collectionId: 'shared_col',
        collectionRepo: localRepo,
        overrideUrl: 'https://api.github.com/gists/gist_test_456',
        overrideApiKey: 'ghp_secret_token_456',
      );

      expect(result.success, isTrue);
      expect(patchCalled, isTrue);
      final savedCol = await localRepo.getById('shared_col');
      expect(savedCol, isNotNull);
      expect(savedCol!.sentences.length, equals(2));
      expect(savedCol.sentences.any((s) => s.id == 's_new'), isTrue);
    });
  });

  group('UI Dialogs for Target Language & Remote Database', () {
    testWidgets('SelectTargetLanguageDialog allows switching target language to Polish', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showSelectTargetLanguageDialog(context),
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Język nauki (docelowy)'), findsOneWidget);
      expect(find.textContaining('Japoński'), findsWidgets);
      expect(find.textContaining('Polski'), findsWidgets);

      await tester.tap(find.textContaining('Polski').first);
      await tester.pumpAndSettle();
    });

    testWidgets('RemoteSyncDialog displays database instructions and test button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showRemoteSyncDialog(context),
                  child: const Text('Open Sync'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sync'));
      await tester.pumpAndSettle();

      expect(find.text('Zdalna Baza Zdań'), findsOneWidget);
      expect(find.text('Adres URL bazy danych / JSON'), findsOneWidget);
      expect(find.text('Klucz API / Token autoryzacji (opcjonalny)'), findsOneWidget);
      expect(find.text('Zapisz i pobierz zdania teraz'), findsOneWidget);
      expect(find.text('Jak zdalnie dodawać zdania dla Koharu?'), findsOneWidget);
    });

    testWidgets('AddSentenceForFriendDialog displays bilingual form fields and switches between Japanese and Polish mode', (tester) async {
      final fakeRepo = _FakeCollectionRepository();
      final fakeRemoteRepo = RemoteDatabaseRepository(
        initialConfig: const RemoteDatabaseConfig(),
      );
      await fakeRepo.save(
        const SentenceCollection(
          id: 'shared_friend_island',
          title: 'Wspólna lista (Shared Island)',
          cefrLevel: 'A1',
          tags: ['shared'],
          isCustomIsland: true,
          sentences: [],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionRepositoryProvider.overrideWithValue(fakeRepo),
            remoteDatabaseRepositoryProvider.overrideWithValue(fakeRemoteRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAddSentenceForFriendDialog(context),
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Check Header & Default Japanese Mode
      expect(find.text('Dla Jakuba / Jakubへフレーズを送る'), findsOneWidget);
      expect(find.text('Japoński (Dla Jakuba)'), findsOneWidget);
      expect(find.text('Polski (Dla Koharu)'), findsOneWidget);
      expect(find.text('1. 日本語（漢字・ひらがな）'), findsOneWidget);
      expect(find.text('2. カタカナ読み (Wymowa w katakanie)'), findsOneWidget);
      expect(find.text('3. ローマ字 (Rōmaji)'), findsOneWidget);
      expect(find.text('4. 英語・ポーランド語訳 (Znaczenie)'), findsOneWidget);
      expect(find.text('5. メモ・使い方 (Wskazówki & Kontekst)'), findsOneWidget);

      // Switch to Polish mode
      await tester.tap(find.text('Polski (Dla Koharu)'));
      await tester.pumpAndSettle();

      expect(find.text('Dla Koharu / こはるちゃんへポーランド語作成'), findsOneWidget);
      expect(find.text('1. Zdanie po polsku (Polski)'), findsOneWidget);
      expect(find.text('2. カタカナ発音 (Katakana dla Japończyka)'), findsOneWidget);
      expect(find.text('3. Transkrypcja fonetyczna / Rōmaji'), findsOneWidget);
      expect(find.text('4. 日本語・英語訳 (Tłumaczenie dla niej)'), findsOneWidget);

      // Fill in fields and submit
      await tester.enterText(find.byKey(const ValueKey('add_sentence_target_input')), 'Smacznego!');
      await tester.enterText(find.byKey(const ValueKey('add_sentence_katakana_input')), 'スマチネゴ！');
      await tester.enterText(find.byKey(const ValueKey('add_sentence_romaji_input')), 'Smach-neh-go!');
      await tester.enterText(find.byKey(const ValueKey('add_sentence_source_input')), 'いただきます！・美味しく召し上がれ！');
      await tester.enterText(find.byKey(const ValueKey('add_sentence_notes_input')), 'Mówimy przed posiłkiem.');

      await tester.tap(find.text('Wyślij do GitHuba i Zapisz'));
      await tester.pumpAndSettle();

      // Dialog should close and sentence should be stored locally in fakeRepo
      final col = await fakeRepo.getById('shared_friend_island');
      expect(col, isNotNull);
      expect(col!.sentences.length, equals(1));
      expect(col.sentences.first.targetText, equals('Smacznego!'));
      expect(col.sentences.first.katakana, equals('スマチネゴ！'));
      expect(col.sentences.first.sourceText, equals('いただきます！・美味しく召し上がれ！'));
    });

    testWidgets('CollectionsScreen displays FloatingActionButton for friend and opens dialog', (tester) async {
      final fakeRepo = _FakeCollectionRepository();
      final fakeRemoteRepo = RemoteDatabaseRepository(
        initialConfig: const RemoteDatabaseConfig(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionRepositoryProvider.overrideWithValue(fakeRepo),
            remoteDatabaseRepositoryProvider.overrideWithValue(fakeRemoteRepo),
          ],
          child: const MaterialApp(
            home: CollectionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fab = find.byKey(const ValueKey('fab_add_sentence_for_friend'));
      expect(fab, findsOneWidget);
      expect(find.text('Dla Koharu / Wyślij'), findsWidgets);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Dla Jakuba / Jakubへフレーズを送る'), findsOneWidget);
    });
  });
}
