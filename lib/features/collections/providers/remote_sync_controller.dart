import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/remote_database_config.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/data/repositories/remote_database_repository.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';

final remoteDatabaseConfigProvider =
    AsyncNotifierProvider<RemoteDatabaseConfigController, RemoteDatabaseConfig>(
  RemoteDatabaseConfigController.new,
);

class RemoteDatabaseConfigController extends AsyncNotifier<RemoteDatabaseConfig> {
  @override
  Future<RemoteDatabaseConfig> build() async {
    final repo = ref.read(remoteDatabaseRepositoryProvider);
    return repo.loadConfig();
  }

  Future<void> updateConfig({
    required String url,
    String? apiKey,
    bool? autoSyncOnStartup,
  }) async {
    final current = state.valueOrNull ?? const RemoteDatabaseConfig();
    final updated = current.copyWith(
      url: url.trim(),
      apiKey: apiKey != null ? apiKey.trim() : current.apiKey,
      autoSyncOnStartup: autoSyncOnStartup ?? current.autoSyncOnStartup,
    );
    final repo = ref.read(remoteDatabaseRepositoryProvider);
    await repo.saveConfig(updated);
    state = AsyncData(updated);
  }

  Future<RemoteSyncResult> syncNow({
    String? overrideUrl,
    String? overrideApiKey,
  }) async {
    final remoteRepo = ref.read(remoteDatabaseRepositoryProvider);
    final collectionRepo = ref.read(collectionRepositoryProvider);

    final result = await remoteRepo.syncAll(
      collectionRepo: collectionRepo,
      overrideUrl: overrideUrl,
      overrideApiKey: overrideApiKey,
    );

    // Refresh config state and collections
    ref.invalidateSelf();
    ref.invalidate(collectionsControllerProvider);

    return result;
  }

  Future<RemoteSyncResult> pushCollections({
    required List<SentenceCollection> collections,
    String? overrideUrl,
    String? overrideApiKey,
    String? filename,
  }) async {
    final remoteRepo = ref.read(remoteDatabaseRepositoryProvider);
    final result = await remoteRepo.pushCollectionsToRemote(
      collections: collections,
      overrideUrl: overrideUrl,
      overrideApiKey: overrideApiKey,
      filename: filename,
    );
    ref.invalidateSelf();
    return result;
  }

  Future<RemoteSyncResult> addSentenceAndPush({
    required Sentence sentence,
    required String collectionId,
    String? collectionTitle,
    String? overrideUrl,
    String? overrideApiKey,
  }) async {
    final remoteRepo = ref.read(remoteDatabaseRepositoryProvider);
    final collectionRepo = ref.read(collectionRepositoryProvider);

    final result = await remoteRepo.addSentenceAndSync(
      sentence: sentence,
      collectionId: collectionId,
      collectionTitle: collectionTitle,
      collectionRepo: collectionRepo,
      overrideUrl: overrideUrl,
      overrideApiKey: overrideApiKey,
    );

    ref.invalidateSelf();
    ref.invalidate(collectionsControllerProvider);

    return result;
  }
}
