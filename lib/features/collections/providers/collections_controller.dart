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

  Future<void> importFromJson(String jsonStr) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(collectionRepositoryProvider);
      await repo.importFromJsonString(jsonStr);
      return repo.loadAll();
    });
  }

  Future<void> deleteCollection(String id) async {
    final repo = ref.read(collectionRepositoryProvider);
    await repo.deleteCollection(id);
    ref.invalidateSelf();
  }
}
