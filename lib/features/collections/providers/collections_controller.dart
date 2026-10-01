import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}
