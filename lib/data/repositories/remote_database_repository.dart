import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:language_islands_app/core/models/remote_database_config.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/data/repositories/collection_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RemoteSyncResult {
  const RemoteSyncResult({
    required this.success,
    required this.collectionsCount,
    required this.newSentencesCount,
    required this.updatedSentencesCount,
    required this.message,
  });

  final bool success;
  final int collectionsCount;
  final int newSentencesCount;
  final int updatedSentencesCount;
  final String message;
}

class RemoteDatabaseRepository {
  RemoteDatabaseRepository({
    http.Client? client,
    RemoteDatabaseConfig? initialConfig,
    this.configFileProvider,
    this.documentsDirectoryProvider,
  })  : _client = client ?? http.Client(),
        _cachedConfig = initialConfig;

  final http.Client _client;
  final Future<File> Function()? configFileProvider;
  final Future<Directory> Function()? documentsDirectoryProvider;
  RemoteDatabaseConfig? _cachedConfig;

  Future<RemoteDatabaseConfig> loadConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;

    try {
      final file = await _configFile();
      if (!await file.exists()) {
        _cachedConfig = const RemoteDatabaseConfig();
        return _cachedConfig!;
      }

      final raw = await file.readAsString();
      _cachedConfig = RemoteDatabaseConfig.fromJsonString(raw);
    } catch (_) {
      _cachedConfig = const RemoteDatabaseConfig();
    }
    return _cachedConfig!;
  }

  Future<void> saveConfig(RemoteDatabaseConfig config) async {
    _cachedConfig = config;
    try {
      final file = await _configFile();
      await file.parent.create(recursive: true);

      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(config.toJsonString(), flush: true);
      if (await file.exists()) {
        await file.delete();
      }
      await tmp.rename(file.path);
    } catch (_) {
      // Allows in-memory fallback when file storage is unavailable
    }
  }

  Future<List<SentenceCollection>> fetchCollectionsFromUrl(
    String url, {
    String? apiKey,
  }) async {
    var targetUrl = url.trim();
    final configHelper = RemoteDatabaseConfig(url: targetUrl);
    if (configHelper.isGitHubGist &&
        !targetUrl.contains('gist.githubusercontent.com') &&
        !targetUrl.contains('api.github.com')) {
      targetUrl = 'https://api.github.com/gists/${configHelper.gistId}';
    }

    final uri = Uri.parse(targetUrl);
    final headers = <String, String>{
      'Accept': 'application/json, application/vnd.github+json',
      'User-Agent': 'LanguageIslandsApp/1.0',
    };

    final effectiveKey = apiKey?.trim();
    if (effectiveKey != null && effectiveKey.isNotEmpty) {
      headers['apikey'] = effectiveKey;
      headers['Authorization'] = 'Bearer $effectiveKey';
    }

    final response = await _client.get(uri, headers: headers).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw HttpException('Przekroczono limit czasu połączenia (20s). Sprawdź URL bazy.');
      },
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'Błąd pobierania bazy (HTTP ${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }

    final decodedStr = utf8.decode(response.bodyBytes);
    final dynamic decodedJson = jsonDecode(decodedStr);
    final parsed = parseCollectionsFromJson(decodedJson, fallbackSourceUrl: url);
    return await materializeBase64Recordings(parsed);
  }

  List<SentenceCollection> parseCollectionsFromJson(
    dynamic json, {
    String? fallbackSourceUrl,
  }) {
    if (json == null) return [];

    // 1. JSON Array
    if (json is List) {
      final collections = <SentenceCollection>[];
      final orphanSentencesByCollectionId = <String, List<Map<String, dynamic>>>{};

      for (final item in json) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        // A) Array of collection objects
        if (map.containsKey('title') && map.containsKey('sentences')) {
          try {
            var col = SentenceCollection.fromMap(map);
            if (col.remoteSourceUrl == null && fallbackSourceUrl != null) {
              col = col.copyWith(remoteSourceUrl: fallbackSourceUrl);
            }
            collections.add(col);
          } catch (e) {
            debugPrint('Błąd parsowania kolekcji ze zdalnej bazy: $e');
          }
        } else if (map.containsKey('targetText') || map.containsKey('target_text')) {
          // B) Flat table of sentences (e.g. Supabase table 'sentences')
          final colId = (map['collection_id'] ?? map['collectionId'] ?? 'remote_default').toString();
          orphanSentencesByCollectionId.putIfAbsent(colId, () => []).add(map);
        }
      }

      if (collections.isNotEmpty) {
        return collections;
      }

      // If flat sentences were grouped
      if (orphanSentencesByCollectionId.isNotEmpty) {
        for (final entry in orphanSentencesByCollectionId.entries) {
          final colId = entry.key;
          final rawList = entry.value;
          final sentences = <Sentence>[];

          for (final raw in rawList) {
            final target = (raw['targetText'] ?? raw['target_text'] ?? '').toString().trim();
            final source = (raw['sourceText'] ?? raw['source_text'] ?? '').toString().trim();
            final id = (raw['id'] ?? 's_${sentences.length + 1}').toString();
            if (target.isEmpty) continue;

            sentences.add(
              Sentence(
                id: id,
                targetText: target,
                sourceText: source,
                phoneticReading: raw['phoneticReading'] ?? raw['phonetic_reading'],
                katakana: raw['katakana'],
                targetAudioBase64: raw['targetAudioBase64'] ?? raw['target_audio_base64'],
                translationAudioBase64: raw['translationAudioBase64'] ??
                    raw['translation_audio_base64'] ??
                    raw['sourceAudioBase64'],
                notes: raw['notes'] ?? raw['grammar_notes'],
              ),
            );
          }

          collections.add(
            SentenceCollection(
              id: colId,
              title: colId == 'remote_default' ? 'Zdalna kolekcja' : 'Kolekcja $colId',
              cefrLevel: 'A1',
              tags: ['zdalna_baza'],
              isCustomIsland: true,
              targetLanguage: 'pl',
              translationLanguage: 'ja',
              remoteSourceUrl: fallbackSourceUrl,
              sentences: sentences,
            ),
          );
        }
        return collections;
      }
    }

    // 2. JSON Object (Map)
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);

      // GitHub Gist response format: { "files": { "sentences.json": { "content": "..." } } }
      if (map['files'] is Map) {
        final filesMap = map['files'] as Map;
        for (final fileEntry in filesMap.values) {
          if (fileEntry is Map && fileEntry['content'] is String) {
            try {
              final inner = jsonDecode(fileEntry['content'] as String);
              final parsed = parseCollectionsFromJson(inner, fallbackSourceUrl: fallbackSourceUrl);
              if (parsed.isNotEmpty) return parsed;
            } catch (_) {}
          }
        }
      }

      // Wrapper like { "collections": [...] } or { "data": [...] }
      if (map['collections'] is List) {
        return parseCollectionsFromJson(map['collections'], fallbackSourceUrl: fallbackSourceUrl);
      }
      if (map['data'] is List) {
        return parseCollectionsFromJson(map['data'], fallbackSourceUrl: fallbackSourceUrl);
      }

      // Single collection object { "id": "...", "title": "...", "sentences": [...] }
      if (map.containsKey('title') && map.containsKey('sentences')) {
        var col = SentenceCollection.fromMap(map);
        if (col.remoteSourceUrl == null && fallbackSourceUrl != null) {
          col = col.copyWith(remoteSourceUrl: fallbackSourceUrl);
        }
        return [col];
      }
    }

    throw const FormatException(
      'Niepoprawny format danych w zdalnej bazie. '
      'Wymagana jest kolekcja z polami "title" i "sentences" lub tablica takich kolekcji.',
    );
  }

  Future<RemoteSyncResult> syncAll({
    required CollectionRepository collectionRepo,
    String? overrideUrl,
    String? overrideApiKey,
  }) async {
    final config = await loadConfig();
    final targetUrl = (overrideUrl ?? config.url).trim();
    final targetKey = (overrideApiKey ?? config.apiKey).trim();

    if (targetUrl.isEmpty) {
      return const RemoteSyncResult(
        success: false,
        collectionsCount: 0,
        newSentencesCount: 0,
        updatedSentencesCount: 0,
        message: 'Brak skonfigurowanego adresu URL zdalnej bazy.',
      );
    }

    try {
      final incomingCollections = await fetchCollectionsFromUrl(
        targetUrl,
        apiKey: targetKey.isNotEmpty ? targetKey : null,
      );

      var newSentencesTotal = 0;
      var updatedSentencesTotal = 0;
      var collectionsUpdated = 0;

      for (final incoming in incomingCollections) {
        final existing = await collectionRepo.getById(incoming.id);

        if (existing != null) {
          // Merge sentences, preserving user ratings and progress
          final existingSentenceMap = {for (final s in existing.sentences) s.id: s};
          final mergedSentences = <Sentence>[];
          final processedIds = <String>{};

          for (final incomingSentence in incoming.sentences) {
            processedIds.add(incomingSentence.id);
            final local = existingSentenceMap[incomingSentence.id];

            if (local != null) {
              // Preserve ratings, repetitions, audio paths and custom user notes if set
              // Prioritize human voice recording if present on either side
              final targetAudio = local.hasCustomTargetAudio
                  ? local.targetAudioPath
                  : (incomingSentence.targetAudioPath ?? local.targetAudioPath);
              final targetAudioB64 = local.hasCustomTargetAudio
                  ? (local.targetAudioBase64 ?? incomingSentence.targetAudioBase64)
                  : (incomingSentence.targetAudioBase64 ?? local.targetAudioBase64);

              final transAudio = local.hasCustomTranslationAudio
                  ? local.translationAudioPath
                  : (incomingSentence.translationAudioPath ?? local.translationAudioPath);
              final transAudioB64 = local.hasCustomTranslationAudio
                  ? (local.translationAudioBase64 ?? incomingSentence.translationAudioBase64)
                  : (incomingSentence.translationAudioBase64 ?? local.translationAudioBase64);

              final updated = incomingSentence.copyWith(
                comprehensionScore: local.comprehensionScore,
                speakingScore: local.speakingScore,
                totalReps: local.totalReps,
                targetAudioPath: targetAudio,
                targetAudioBase64: targetAudioB64,
                translationAudioPath: transAudio,
                translationAudioBase64: transAudioB64,
                notes: (local.notes != null && local.notes!.trim().isNotEmpty)
                    ? local.notes
                    : incomingSentence.notes,
              );
              mergedSentences.add(updated);
              if (updated != incomingSentence) {
                updatedSentencesTotal++;
              }
            } else {
              mergedSentences.add(incomingSentence);
              newSentencesTotal++;
            }
          }

          // Keep any purely local sentences user may have created
          for (final local in existing.sentences) {
            if (!processedIds.contains(local.id)) {
              mergedSentences.add(local);
            }
          }

          final mergedCollection = existing.copyWith(
            title: incoming.title.isNotEmpty ? incoming.title : existing.title,
            cefrLevel: incoming.cefrLevel,
            tags: incoming.tags.isNotEmpty ? incoming.tags : existing.tags,
            targetLanguage: incoming.targetLanguage ?? existing.targetLanguage,
            translationLanguage: incoming.translationLanguage ?? existing.translationLanguage,
            remoteSourceUrl: targetUrl,
            lastSyncedAt: DateTime.now(),
            sentences: mergedSentences,
          );

          await collectionRepo.updateCollection(mergedCollection);
          collectionsUpdated++;
        } else {
          // New collection imported from remote DB
          final newCollection = incoming.copyWith(
            remoteSourceUrl: targetUrl,
            lastSyncedAt: DateTime.now(),
          );
          await collectionRepo.updateCollection(newCollection);
          newSentencesTotal += newCollection.sentences.length;
          collectionsUpdated++;
        }
      }

      // Also sync any specific collections with their own remoteSourceUrl
      final allLocal = await collectionRepo.loadAll();
      for (final col in allLocal) {
        final colUrl = col.remoteSourceUrl?.trim();
        if (colUrl != null && colUrl.isNotEmpty && colUrl != targetUrl) {
          try {
            final colIncoming = await fetchCollectionsFromUrl(colUrl);
            for (final incoming in colIncoming) {
              if (incoming.id == col.id || colIncoming.length == 1) {
                // Merge this specific collection
                final existingSentenceMap = {for (final s in col.sentences) s.id: s};
                final mergedSentences = <Sentence>[];
                final processedIds = <String>{};

                for (final incomingSentence in incoming.sentences) {
                  processedIds.add(incomingSentence.id);
                  final local = existingSentenceMap[incomingSentence.id];
                  if (local != null) {
                    final targetAudio = local.hasCustomTargetAudio
                        ? local.targetAudioPath
                        : (incomingSentence.targetAudioPath ?? local.targetAudioPath);
                    final targetAudioB64 = local.hasCustomTargetAudio
                        ? (local.targetAudioBase64 ?? incomingSentence.targetAudioBase64)
                        : (incomingSentence.targetAudioBase64 ?? local.targetAudioBase64);

                    final transAudio = local.hasCustomTranslationAudio
                        ? local.translationAudioPath
                        : (incomingSentence.translationAudioPath ?? local.translationAudioPath);
                    final transAudioB64 = local.hasCustomTranslationAudio
                        ? (local.translationAudioBase64 ?? incomingSentence.translationAudioBase64)
                        : (incomingSentence.translationAudioBase64 ?? local.translationAudioBase64);

                    final updated = incomingSentence.copyWith(
                      comprehensionScore: local.comprehensionScore,
                      speakingScore: local.speakingScore,
                      totalReps: local.totalReps,
                      targetAudioPath: targetAudio,
                      targetAudioBase64: targetAudioB64,
                      translationAudioPath: transAudio,
                      translationAudioBase64: transAudioB64,
                      notes: (local.notes != null && local.notes!.trim().isNotEmpty)
                          ? local.notes
                          : incomingSentence.notes,
                    );
                    mergedSentences.add(updated);
                    updatedSentencesTotal++;
                  } else {
                    mergedSentences.add(incomingSentence);
                    newSentencesTotal++;
                  }
                }

                for (final local in col.sentences) {
                  if (!processedIds.contains(local.id)) {
                    mergedSentences.add(local);
                  }
                }

                final mergedCollection = col.copyWith(
                  title: incoming.title.isNotEmpty ? incoming.title : col.title,
                  targetLanguage: incoming.targetLanguage ?? col.targetLanguage,
                  translationLanguage: incoming.translationLanguage ?? col.translationLanguage,
                  lastSyncedAt: DateTime.now(),
                  sentences: mergedSentences,
                );
                await collectionRepo.updateCollection(mergedCollection);
                collectionsUpdated++;
                break;
              }
            }
          } catch (e) {
            debugPrint('Błąd synchronizacji dedykowanej kolekcji "${col.id}": $e');
          }
        }
      }

      final successMessage =
          'Pomyślnie zsynchronizowano $collectionsUpdated kolekcji (nowe zdania: $newSentencesTotal, zaktualizowane: $updatedSentencesTotal).';

      await saveConfig(
        config.copyWith(
          url: targetUrl,
          apiKey: targetKey,
          lastSyncedAt: DateTime.now(),
          lastSyncStatus: successMessage,
        ),
      );

      return RemoteSyncResult(
        success: true,
        collectionsCount: collectionsUpdated,
        newSentencesCount: newSentencesTotal,
        updatedSentencesCount: updatedSentencesTotal,
        message: successMessage,
      );
    } catch (e) {
      final errMsg = 'Błąd synchronizacji ze zdalną bazą: $e';
      await saveConfig(
        config.copyWith(
          lastSyncStatus: errMsg,
        ),
      );
      return RemoteSyncResult(
        success: false,
        collectionsCount: 0,
        newSentencesCount: 0,
        updatedSentencesCount: 0,
        message: errMsg,
      );
    }
  }

  Future<RemoteSyncResult> pushCollectionsToRemote({
    required List<SentenceCollection> collections,
    String? overrideUrl,
    String? overrideApiKey,
    String? filename,
  }) async {
    final config = await loadConfig();
    final targetUrl = (overrideUrl ?? config.url).trim();
    final targetKey = (overrideApiKey ?? config.apiKey).trim();

    if (targetUrl.isEmpty) {
      return const RemoteSyncResult(
        success: false,
        collectionsCount: 0,
        newSentencesCount: 0,
        updatedSentencesCount: 0,
        message: 'Brak skonfigurowanego adresu URL zdalnej bazy.',
      );
    }

    final configHelper = RemoteDatabaseConfig(url: targetUrl);
    final isGist = configHelper.isGitHubGist;

    try {
      final preparedCollections = await _prepareCollectionsForPush(collections);

      if (isGist) {
        final gistId = configHelper.gistId!;
        if (targetKey.isEmpty) {
          return const RemoteSyncResult(
            success: false,
            collectionsCount: 0,
            newSentencesCount: 0,
            updatedSentencesCount: 0,
            message: 'Do zapisu na GitHub Gist wymagany jest Personal Access Token (PAT) z uprawnieniem "gist".',
          );
        }

        final uri = Uri.parse('https://api.github.com/gists/$gistId');
        final headers = <String, String>{
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'LanguageIslandsApp/1.0',
          'X-GitHub-Api-Version': '2022-11-28',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $targetKey',
        };

        final jsonContent = const JsonEncoder.withIndent('  ').convert(
          preparedCollections.map((c) => c.toMap()).toList(),
        );

        final actualFilename = filename ?? 'sentences.json';
        final body = jsonEncode({
          'description': 'Language Islands Shared Sentences',
          'files': {
            actualFilename: {
              'content': jsonContent,
            },
          },
        });

        final response = await _client.patch(uri, headers: headers, body: body).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw HttpException('Przekroczono limit czasu połączenia (20s) z GitHubem.'),
        );

        if (response.statusCode != 200) {
          if (response.statusCode == 401 || response.statusCode == 403) {
            throw HttpException(
              'Błąd autoryzacji GitHuba (${response.statusCode}). Sprawdź swój token (wymagany zakres: "gist").',
              uri: uri,
            );
          }
          if (response.statusCode == 404) {
            throw HttpException(
              'Nie znaleziono Gista o ID "$gistId" na GitHubie (HTTP 404). Sprawdź ID i uprawnienia tokena.',
              uri: uri,
            );
          }
          throw HttpException(
            'Błąd aktualizacji GitHuba (HTTP ${response.statusCode}): ${response.body}',
            uri: uri,
          );
        }
      } else {
        // Generic REST PUT
        final uri = Uri.parse(targetUrl);
        final headers = <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'LanguageIslandsApp/1.0',
        };
        if (targetKey.isNotEmpty) {
          headers['apikey'] = targetKey;
          headers['Authorization'] = 'Bearer $targetKey';
        }

        final body = jsonEncode(preparedCollections.map((c) => c.toMap()).toList());
        final response = await _client.put(uri, headers: headers, body: body).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw HttpException('Przekroczono limit czasu połączenia (20s).'),
        );

        if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
          throw HttpException(
            'Błąd wysyłania do zdalnej bazy (HTTP ${response.statusCode}): ${response.body}',
            uri: uri,
          );
        }
      }

      final successMsg = isGist
          ? 'Pomyślnie wysłano i zaktualizowano GitHub Gist!'
          : 'Pomyślnie wysłano dane do zdalnej bazy.';

      await saveConfig(
        config.copyWith(
          url: targetUrl,
          apiKey: targetKey,
          lastSyncedAt: DateTime.now(),
          lastSyncStatus: successMsg,
        ),
      );

      return RemoteSyncResult(
        success: true,
        collectionsCount: collections.length,
        newSentencesCount: 0,
        updatedSentencesCount: 0,
        message: successMsg,
      );
    } catch (e) {
      return RemoteSyncResult(
        success: false,
        collectionsCount: 0,
        newSentencesCount: 0,
        updatedSentencesCount: 0,
        message: 'Błąd wysyłania: $e',
      );
    }
  }

  Future<RemoteSyncResult> addSentenceAndSync({
    required Sentence sentence,
    required String collectionId,
    String? collectionTitle,
    required CollectionRepository collectionRepo,
    String? overrideUrl,
    String? overrideApiKey,
  }) async {
    final config = await loadConfig();
    final targetUrl = (overrideUrl ?? config.url).trim();
    final targetKey = (overrideApiKey ?? config.apiKey).trim();

    // 1. If remote URL is not configured, save locally
    if (targetUrl.isEmpty) {
      final existingCol = await collectionRepo.getById(collectionId);
      final col = existingCol ??
          SentenceCollection(
            id: collectionId,
            title: collectionTitle ?? 'Wspólna lista zdań',
            cefrLevel: 'A1',
            tags: const ['wspólne'],
            isCustomIsland: true,
            sentences: const [],
            targetLanguage: sentence.katakana != null ? 'ja' : 'pl',
            translationLanguage: sentence.katakana != null ? 'pl' : 'ja',
          );

      final sentences = List<Sentence>.from(col.sentences);
      final index = sentences.indexWhere(
        (s) => s.id == sentence.id || s.targetText.trim() == sentence.targetText.trim(),
      );
      if (index >= 0) {
        sentences[index] = sentence;
      } else {
        sentences.add(sentence);
      }

      final updatedCol = col.copyWith(sentences: sentences);
      await collectionRepo.updateCollection(updatedCol);

      return const RemoteSyncResult(
        success: true,
        collectionsCount: 1,
        newSentencesCount: 1,
        updatedSentencesCount: 0,
        message: 'Zwrot zapisano w aplikacji lokalnie. Skonfiguruj GitHub Gist, aby wysyłać zdania do przyjaciela.',
      );
    }

    // 2. Remote is configured: Safe bidirectional merge & push
    try {
      List<SentenceCollection> remoteCollections = [];
      try {
        remoteCollections = await fetchCollectionsFromUrl(targetUrl, apiKey: targetKey);
      } catch (fetchErr) {
        debugPrint('Nie udało się pobrać istniejących zdalnych kolekcji: $fetchErr. Używam lokalnych.');
        remoteCollections = await collectionRepo.loadAll();
      }

      final collectionMap = <String, SentenceCollection>{
        for (final col in remoteCollections) col.id: col,
      };

      SentenceCollection targetCol;
      if (collectionMap.containsKey(collectionId)) {
        targetCol = collectionMap[collectionId]!;
      } else {
        final localCol = await collectionRepo.getById(collectionId);
        targetCol = localCol ??
            SentenceCollection(
              id: collectionId,
              title: collectionTitle ?? 'Wspólna lista zdań',
              cefrLevel: 'A1',
              tags: const ['wspólne', 'zdalna_baza'],
              isCustomIsland: true,
              sentences: const [],
              targetLanguage: sentence.katakana != null ? 'ja' : 'pl',
              translationLanguage: sentence.katakana != null ? 'pl' : 'ja',
              remoteSourceUrl: targetUrl,
            );
      }

      // Merge sentence into targetCol
      final sentences = List<Sentence>.from(targetCol.sentences);
      final existingIndex = sentences.indexWhere(
        (s) => s.id == sentence.id || s.targetText.trim() == sentence.targetText.trim(),
      );

      var isNew = false;
      if (existingIndex >= 0) {
        // Keep progress if local exists
        final existing = sentences[existingIndex];
        sentences[existingIndex] = sentence.copyWith(
          comprehensionScore: existing.comprehensionScore,
          speakingScore: existing.speakingScore,
          totalReps: existing.totalReps,
          targetAudioPath: existing.targetAudioPath,
          translationAudioPath: existing.translationAudioPath,
          notes: (existing.notes != null && existing.notes!.trim().isNotEmpty)
              ? existing.notes
              : sentence.notes,
        );
      } else {
        sentences.add(sentence);
        isNew = true;
      }

      final updatedTargetCol = targetCol.copyWith(
        sentences: sentences,
        lastSyncedAt: DateTime.now(),
        remoteSourceUrl: targetUrl,
      );
      collectionMap[collectionId] = updatedTargetCol;

      // Push to remote
      final pushResult = await pushCollectionsToRemote(
        collections: collectionMap.values.toList(),
        overrideUrl: targetUrl,
        overrideApiKey: targetKey,
      );

      if (!pushResult.success) {
        return pushResult;
      }

      // Also save locally
      await collectionRepo.updateCollection(updatedTargetCol);

      // Refresh local collections through syncAll
      await syncAll(
        collectionRepo: collectionRepo,
        overrideUrl: targetUrl,
        overrideApiKey: targetKey,
      );

      return RemoteSyncResult(
        success: true,
        collectionsCount: 1,
        newSentencesCount: isNew ? 1 : 0,
        updatedSentencesCount: isNew ? 0 : 1,
        message: 'Zwrot został pomyślnie wysłany i zsynchronizowany z GitHubem!',
      );
    } catch (e) {
      return RemoteSyncResult(
        success: false,
        collectionsCount: 0,
        newSentencesCount: 0,
        updatedSentencesCount: 0,
        message: 'Błąd podczas wysyłania do GitHuba: $e',
      );
    }
  }

  Future<Directory> _getDocumentsDir() async {
    final provider = documentsDirectoryProvider;
    if (provider != null) {
      return provider();
    }
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  Future<File> _configFile() async {
    final provider = configFileProvider;
    if (provider != null) {
      return provider();
    }
    final docs = await _getDocumentsDir();
    return File(p.join(docs.path, 'settings', 'remote_database_config.json'));
  }

  /// Decodes any Base64 audio strings in incoming collections into local .m4a files in user_recordings/
  /// and points targetAudioPath / translationAudioPath to the newly saved local files.
  Future<List<SentenceCollection>> materializeBase64Recordings(
    List<SentenceCollection> collections,
  ) async {
    final docs = await _getDocumentsDir();
    final recordingsDir = Directory(p.join(docs.path, 'user_recordings'));

    final materialized = <SentenceCollection>[];
    for (final col in collections) {
      final sentences = <Sentence>[];
      for (final s in col.sentences) {
        var updated = s;
        // Materialize target audio Base64
        if (s.targetAudioBase64 != null && s.targetAudioBase64!.trim().isNotEmpty) {
          try {
            if (!await recordingsDir.exists()) {
              await recordingsDir.create(recursive: true);
            }
            final safeId = s.id.replaceAll(RegExp(r'[^\w\-]'), '_');
            final file = File(p.join(recordingsDir.path, 'rec_${safeId}_target.m4a'));
            final bytes = base64Decode(s.targetAudioBase64!.trim());
            await file.writeAsBytes(bytes, flush: true);
            updated = updated.copyWith(targetAudioPath: file.path);
          } catch (e) {
            debugPrint('Failed to materialize target audio for sentence ${s.id}: $e');
          }
        }

        // Materialize translation audio Base64
        if (s.translationAudioBase64 != null && s.translationAudioBase64!.trim().isNotEmpty) {
          try {
            if (!await recordingsDir.exists()) {
              await recordingsDir.create(recursive: true);
            }
            final safeId = s.id.replaceAll(RegExp(r'[^\w\-]'), '_');
            final file = File(p.join(recordingsDir.path, 'rec_${safeId}_trans.m4a'));
            final bytes = base64Decode(s.translationAudioBase64!.trim());
            await file.writeAsBytes(bytes, flush: true);
            updated = updated.copyWith(translationAudioPath: file.path);
          } catch (e) {
            debugPrint('Failed to materialize translation audio for sentence ${s.id}: $e');
          }
        }
        sentences.add(updated);
      }
      materialized.add(col.copyWith(sentences: sentences));
    }
    return materialized;
  }

  /// Encodes local audio recording files to Base64 before pushing to remote/Gist.
  /// Note: Only user-recorded audio (in user_recordings/ or marked with custom audio)
  /// is serialized to Base64. Synthesized Edge TTS audio files (in audio_cache/)
  /// are strictly excluded to avoid bloating Gist and misclassifying TTS as human voices.
  Future<List<SentenceCollection>> _prepareCollectionsForPush(
    List<SentenceCollection> collections,
  ) async {
    final prepared = <SentenceCollection>[];
    for (final col in collections) {
      final sentences = <Sentence>[];
      for (final s in col.sentences) {
        var updated = s;
        // Target audio file -> base64 (ONLY for user recordings, not TTS cache)
        final isTargetUserRec = updated.hasCustomTargetAudio ||
            (updated.targetAudioPath != null &&
                (updated.targetAudioPath!.contains('user_recordings') ||
                    p.basename(updated.targetAudioPath!).startsWith('rec_')));
        if (isTargetUserRec &&
            (updated.targetAudioBase64 == null || updated.targetAudioBase64!.trim().isEmpty) &&
            updated.targetAudioPath != null &&
            updated.targetAudioPath!.isNotEmpty) {
          try {
            final f = File(updated.targetAudioPath!);
            if (await f.exists()) {
              final bytes = await f.readAsBytes();
              updated = updated.copyWith(targetAudioBase64: base64Encode(bytes));
            }
          } catch (e) {
            debugPrint('Error encoding targetAudioPath for ${s.id}: $e');
          }
        }
        // Translation audio file -> base64 (ONLY for user recordings, not TTS cache)
        final isTransUserRec = updated.hasCustomTranslationAudio ||
            (updated.translationAudioPath != null &&
                (updated.translationAudioPath!.contains('user_recordings') ||
                    p.basename(updated.translationAudioPath!).startsWith('rec_')));
        if (isTransUserRec &&
            (updated.translationAudioBase64 == null || updated.translationAudioBase64!.trim().isEmpty) &&
            updated.translationAudioPath != null &&
            updated.translationAudioPath!.isNotEmpty) {
          try {
            final f = File(updated.translationAudioPath!);
            if (await f.exists()) {
              final bytes = await f.readAsBytes();
              updated = updated.copyWith(translationAudioBase64: base64Encode(bytes));
            }
          } catch (e) {
            debugPrint('Error encoding translationAudioPath for ${s.id}: $e');
          }
        }
        sentences.add(updated);
      }
      prepared.add(col.copyWith(sentences: sentences));
    }
    return prepared;
  }

  void dispose() {
    _client.close();
  }
}
