import 'dart:convert';
import 'dart:io';

import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persists user-imported [SentenceCollection] JSON on disk.
/// No bundled or mock sentence data is ever injected here.
class CollectionRepository {
  CollectionRepository();

  List<SentenceCollection>? _cache;

  Future<List<SentenceCollection>> loadAll() async {
    _cache ??= await _readAllFromDisk();
    return List.unmodifiable(_cache!);
  }

  Future<SentenceCollection?> getById(String id) async {
    final all = await loadAll();
    for (final collection in all) {
      if (collection.id == id) return collection;
    }
    return null;
  }

  Future<SentenceCollection> importFromJsonString(
    String jsonStr, {
    String? title,
  }) async {
    var imported = SentenceCollection.fromJsonString(jsonStr);
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isNotEmpty) {
      imported = imported.copyWith(title: trimmedTitle);
    }

    final existingIds = {
      for (final collection in await loadAll()) collection.id,
    };
    final id = independentCollectionId(
      baseId: imported.id,
      idExists: existingIds.contains,
    );
    if (id != imported.id) {
      imported = imported.copyWith(id: id);
    }

    await _writeCollection(imported);
    _cache = null;
    return imported;
  }

  Future<void> updateSentence(String collectionId, Sentence sentence) async {
    final all = await loadAll();
    final index = all.indexWhere((c) => c.id == collectionId);
    if (index < 0) {
      throw StateError('Collection "$collectionId" not found.');
    }

    final collection = all[index];
    final sentenceIndex = collection.sentences.indexWhere(
      (s) => s.id == sentence.id,
    );
    if (sentenceIndex < 0) {
      throw StateError(
        'Sentence "${sentence.id}" not found in "$collectionId".',
      );
    }

    final updatedSentences = List<Sentence>.from(collection.sentences);
    updatedSentences[sentenceIndex] = sentence;
    final updatedCollection = collection.copyWith(sentences: updatedSentences);
    await _writeCollection(updatedCollection);

    final next = List<SentenceCollection>.from(all);
    next[index] = updatedCollection;
    _cache = next;
  }

  Future<void> deleteCollection(String id) async {
    final file = await _collectionFile(id);
    if (await file.exists()) {
      await file.delete();
    }
    _cache = null;
  }

  Future<List<SentenceCollection>> _readAllFromDisk() async {
    final dir = await _collectionsDirectory();
    if (!await dir.exists()) {
      return [];
    }

    final collections = <SentenceCollection>[];
    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final jsonStr = await entity.readAsString();
        collections.add(SentenceCollection.fromJsonString(jsonStr));
      } on FormatException {
        // Skip corrupted files; user can re-import.
      }
    }

    collections.sort((a, b) => a.title.compareTo(b.title));
    return collections;
  }

  Future<void> _writeCollection(SentenceCollection collection) async {
    final dir = await _collectionsDirectory();
    await dir.create(recursive: true);
    final file = await _collectionFile(collection.id);
    final encoded = jsonEncode(collection.toMap());
    await file.writeAsString(encoded, flush: true);
  }

  Future<Directory> _collectionsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'collections'));
  }

  Future<File> _collectionFile(String collectionId) async {
    final dir = await _collectionsDirectory();
    final safeId = collectionId.replaceAll(RegExp(r'[^\w\-.]'), '_');
    return File(p.join(dir.path, '$safeId.json'));
  }
}

/// Returns [baseId] when it is free, otherwise the first `baseId_N` that is not.
String independentCollectionId({
  required String baseId,
  required bool Function(String id) idExists,
}) {
  if (!idExists(baseId)) return baseId;
  for (var n = 2; n < 10000; n++) {
    final candidate = '${baseId}_$n';
    if (!idExists(candidate)) return candidate;
  }
  return '${baseId}_${DateTime.now().microsecondsSinceEpoch}';
}
