import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:language_islands_app/core/models/remote_database_config.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/data/repositories/collection_repository.dart';
import 'package:language_islands_app/data/repositories/remote_database_repository.dart';
import 'package:path/path.dart' as p;

class _FakeCollectionRepo extends CollectionRepository {
  final Map<String, SentenceCollection> storage = {};

  @override
  Future<List<SentenceCollection>> loadAll() async => storage.values.toList();

  @override
  Future<SentenceCollection?> getById(String id) async => storage[id];

  @override
  Future<void> updateCollection(SentenceCollection collection) async {
    storage[collection.id] = collection;
  }



  @override
  Future<void> addSentence(String collectionId, Sentence sentence) async {
    final col = storage[collectionId];
    if (col != null) {
      final updated = List<Sentence>.from(col.sentences)..add(sentence);
      storage[collectionId] = col.copyWith(sentences: updated);
    }
  }

  @override
  Future<void> updateSentence(String collectionId, Sentence sentence) async {
    final col = storage[collectionId];
    if (col != null) {
      final idx = col.sentences.indexWhere((s) => s.id == sentence.id);
      if (idx != -1) {
        final updated = List<Sentence>.from(col.sentences)..[idx] = sentence;
        storage[collectionId] = col.copyWith(sentences: updated);
      }
    }
  }

  @override
  Future<void> deleteSentence(String collectionId, String sentenceId) async {
    final col = storage[collectionId];
    if (col != null) {
      final updated = col.sentences.where((s) => s.id != sentenceId).toList();
      storage[collectionId] = col.copyWith(sentences: updated);
    }
  }

  @override
  Future<void> deleteCollection(String id) async {
    storage.remove(id);
  }
}

void main() {
  late Directory tempDir;
  late File configFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('remote_sync_audio_test_');
    configFile = File(p.join(tempDir.path, 'config.json'));
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Remote Database Repository Audio Recording Tests', () {
    test('materializeBase64Recordings decodes Base64 audio into local files', () async {
      final repo = RemoteDatabaseRepository(
        documentsDirectoryProvider: () async => tempDir,
        configFileProvider: () async => configFile,
      );

      final dummyAudioBytes = utf8.encode('AUDIO_SAMPLE_DATA_KOHARU');
      final dummyB64 = base64Encode(dummyAudioBytes);

      final col = SentenceCollection(
        id: 'c_sync_1',
        title: 'Japońskie zwroty',
        cefrLevel: 'A1',
        tags: const ['rozmówki'],
        isCustomIsland: true,
        sentences: [
          Sentence(
            id: 's_101',
            targetText: 'こんにちは',
            sourceText: 'Dzień dobry',
            targetAudioBase64: dummyB64,
            translationAudioBase64: dummyB64,
          ),
        ],
      );

      final materialized = await repo.materializeBase64Recordings([col]);
      expect(materialized.length, 1);
      final s = materialized.first.sentences.first;

      expect(s.targetAudioPath, isNotNull);
      expect(s.translationAudioPath, isNotNull);
      expect(s.hasCustomTargetAudio, isTrue);
      expect(s.hasCustomTranslationAudio, isTrue);

      final targetFile = File(s.targetAudioPath!);
      expect(await targetFile.exists(), isTrue);
      expect(await targetFile.readAsBytes(), dummyAudioBytes);

      final transFile = File(s.translationAudioPath!);
      expect(await transFile.exists(), isTrue);
      expect(await transFile.readAsBytes(), dummyAudioBytes);
    });

    test('pushCollectionsToRemote encodes local audio files to Base64 in Gist payload', () async {
      final recordingsDir = Directory(p.join(tempDir.path, 'user_recordings'));
      await recordingsDir.create(recursive: true);

      final audioFile = File(p.join(recordingsDir.path, 'test_voice.m4a'));
      await audioFile.writeAsBytes(utf8.encode('RAW_AUDIO_STREAM_48KBPS'));

      final col = SentenceCollection(
        id: 'col_push',
        title: 'Wspólna lista',
        cefrLevel: 'A1',
        tags: const ['test'],
        isCustomIsland: true,
        sentences: [
          Sentence(
            id: 's_push_1',
            targetText: '乾杯',
            sourceText: 'Na zdrowie',
            targetAudioPath: audioFile.path,
          ),
        ],
      );

      String? capturedRequestBody;
      final mockClient = MockClient((request) async {
        if (request.method == 'PATCH' && request.url.path.contains('/gists/1234567890abcdef1234567890abcdef')) {
          capturedRequestBody = request.body;
          return http.Response(
            jsonEncode({
              'id': '1234567890abcdef1234567890abcdef',
              'files': {
                'sentences.json': {'content': '{}'},
              },
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final repo = RemoteDatabaseRepository(
        client: mockClient,
        documentsDirectoryProvider: () async => tempDir,
        configFileProvider: () async => configFile,
        initialConfig: const RemoteDatabaseConfig(
          url: 'https://gist.github.com/user/1234567890abcdef1234567890abcdef',
          apiKey: 'ghp_mock_token_123',
        ),
      );

      final result = await repo.pushCollectionsToRemote(collections: [col]);
      expect(result.success, isTrue);
      expect(capturedRequestBody, isNotNull);

      final decodedGistBody = jsonDecode(capturedRequestBody!) as Map<String, dynamic>;
      final files = decodedGistBody['files'] as Map<String, dynamic>;
      final sentencesJsonStr = files['sentences.json']['content'] as String;
      final list = jsonDecode(sentencesJsonStr) as List<dynamic>;

      expect(list.length, 1);
      final sMap = list.first['sentences'][0] as Map<String, dynamic>;
      expect(sMap['targetAudioBase64'], isNotNull);
      final decodedBytes = base64Decode(sMap['targetAudioBase64'] as String);
      expect(utf8.decode(decodedBytes), 'RAW_AUDIO_STREAM_48KBPS');
    });

    test('syncAll preserves local voice recordings during remote merge', () async {
      final colRepo = _FakeCollectionRepo();

      final localB64 = base64Encode(utf8.encode('LOCAL_KOHARU_VOICE'));
      final remoteB64 = base64Encode(utf8.encode('REMOTE_JAKUB_VOICE'));

      // Local sentence has Koharu voice recording
      final localSentence = Sentence(
        id: 's_shared',
        targetText: '猫',
        sourceText: 'Kot',
        targetAudioPath: '/local/user_recordings/rec_s_shared_target.m4a',
        targetAudioBase64: localB64,
        comprehensionScore: 4,
        speakingScore: 5,
        totalReps: 10,
      );

      await colRepo.updateCollection(
        SentenceCollection(
          id: 'c_merge',
          title: 'Zwierzęta',
          cefrLevel: 'A1',
          tags: const ['fauna'],
          isCustomIsland: true,
          sentences: [localSentence],
        ),
      );

      // Incoming remote sentence has no target audio, but has translation audio
      final remoteSentence = Sentence(
        id: 's_shared',
        targetText: '猫 (aktualizacja)',
        sourceText: 'Kot domowy',
        translationAudioBase64: remoteB64,
      );

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 'c_merge',
              'title': 'Zwierzęta',
              'cefrLevel': 'A1',
              'tags': ['fauna'],
              'isCustomIsland': true,
              'sentences': [remoteSentence.toMap()],
            }
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final repo = RemoteDatabaseRepository(
        client: mockClient,
        documentsDirectoryProvider: () async => tempDir,
        configFileProvider: () async => configFile,
        initialConfig: const RemoteDatabaseConfig(
          url: 'https://gist.githubusercontent.com/raw/test/sentences.json',
        ),
      );

      final syncResult = await repo.syncAll(collectionRepo: colRepo);
      expect(syncResult.success, isTrue, reason: syncResult.message);

      final updatedCol = await colRepo.getById('c_merge');
      expect(updatedCol, isNotNull);
      final merged = updatedCol!.sentences.first;

      // Local target audio recording must be preserved!
      expect(merged.targetAudioPath, '/local/user_recordings/rec_s_shared_target.m4a');
      expect(merged.targetAudioBase64, localB64);
      expect(merged.hasCustomTargetAudio, isTrue);

      // Incoming translation audio from Jakub must be merged!
      expect(merged.translationAudioBase64, remoteB64);
      expect(merged.hasCustomTranslationAudio, isTrue);

      // Comprehension scores preserved
      expect(merged.comprehensionScore, 4);
      expect(merged.speakingScore, 5);
      expect(merged.totalReps, 10);
    });
  });
}
