import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';

final collectionsControllerProvider =
    AsyncNotifierProvider<CollectionsController, List<SentenceCollection>>(
      CollectionsController.new,
    );

class CollectionsController extends AsyncNotifier<List<SentenceCollection>> {
  @override
  Future<List<SentenceCollection>> build() async {
    final repo = ref.read(collectionRepositoryProvider);
    return repo.loadAll();
  }

  Future<void> importFromJson(String jsonStr, {String? title}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(collectionRepositoryProvider);
      await repo.importFromJsonString(jsonStr, title: title);
      return repo.loadAll();
    });
  }

  Future<void> updateCollectionFromJson(
    String collectionId,
    String jsonStr,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(collectionRepositoryProvider);
      await repo.updateCollectionFromJson(collectionId, jsonStr);
      return repo.loadAll();
    });
  }

  Future<void> addSentence(String collectionId, Sentence sentence) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.addSentence(collectionId, sentence);
    ref.invalidateSelf();
  }

  Future<void> updateSentence(String collectionId, Sentence sentence) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.updateSentence(collectionId, sentence);
    ref.invalidateSelf();
  }

  Future<void> deleteSentence(String collectionId, String sentenceId) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.deleteSentence(collectionId, sentenceId);
    ref.invalidateSelf();
  }

  Future<void> reorderSentences(
    String collectionId,
    int oldIndex,
    int newIndex,
  ) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.reorderSentences(collectionId, oldIndex, newIndex);
    ref.invalidateSelf();
  }

  Future<void> updateCollectionTitle(String collectionId, String newTitle) async {
    final repo = ref.read(collectionRepositoryProvider);
    final collection = await repo.getById(collectionId);
    if (collection != null) {
      final updated = collection.copyWith(title: newTitle.trim());
      await repo.updateCollection(updated);
      ref.invalidateSelf();
    }
  }

  Future<void> deleteCollection(String id) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.deleteCollection(id);
    ref.invalidateSelf();
  }

  Future<void> setTranslationLanguageForCollection(
    String collectionId,
    String langCode,
  ) async {
    final repo = ref.read(collectionRepositoryProvider);
    final collection = await repo.getById(collectionId);
    if (collection != null) {
      final updated = collection.copyWith(translationLanguage: langCode);
      await repo.updateCollection(updated);
      ref.invalidateSelf();
    }
  }

  Future<void> setTranslationLanguageForAllCollections(String langCode) async {
    final repo = ref.read(collectionRepositoryProvider);
    final collections = await repo.loadAll();
    for (final col in collections) {
      final updated = col.copyWith(translationLanguage: langCode);
      await repo.updateCollection(updated);
    }
    ref.invalidateSelf();
  }

  Future<void> setTargetLanguageForCollection(
    String collectionId,
    String langCode,
  ) async {
    final repo = ref.read(collectionRepositoryProvider);
    final collection = await repo.getById(collectionId);
    if (collection != null) {
      final updated = collection.copyWith(targetLanguage: langCode);
      await repo.updateCollection(updated);
      ref.invalidateSelf();
    }
  }

  Future<void> setTargetLanguageForAllCollections(String langCode) async {
    final repo = ref.read(collectionRepositoryProvider);
    final collections = await repo.loadAll();
    for (final col in collections) {
      final updated = col.copyWith(targetLanguage: langCode);
      await repo.updateCollection(updated);
    }
    ref.invalidateSelf();
  }

  Future<void> setRemoteUrlForCollection(
    String collectionId,
    String? url,
  ) async {
    final repo = ref.read(collectionRepositoryProvider);
    final collection = await repo.getById(collectionId);
    if (collection != null) {
      final updated = collection.copyWith(
        remoteSourceUrl: url,
        clearRemoteSourceUrl: url == null || url.trim().isEmpty,
      );
      await repo.updateCollection(updated);
      ref.invalidateSelf();
    }
  }

  Future<void> importFromUrl(
    String url, {
    String? title,
    String? apiKey,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final remoteRepo = ref.read(remoteDatabaseRepositoryProvider);
      final collectionRepo = ref.read(collectionRepositoryProvider);

      final collections = await remoteRepo.fetchCollectionsFromUrl(url, apiKey: apiKey);
      if (collections.isEmpty) {
        throw StateError('Nie znaleziono żadnych kolekcji pod podanym adresem URL.');
      }

      for (var col in collections) {
        if (title != null && title.trim().isNotEmpty && collections.length == 1) {
          col = col.copyWith(title: title.trim());
        }
        await collectionRepo.updateCollection(
          col.copyWith(
            remoteSourceUrl: url,
            lastSyncedAt: DateTime.now(),
          ),
        );
      }
      return collectionRepo.loadAll();
    });
  }
}
