import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/data/repositories/collection_repository.dart';
import 'package:language_islands_app/features/collections/presentation/collections_screen.dart';

class _FakeCollectionRepository extends CollectionRepository {
  final Map<String, SentenceCollection> storage = {};

  @override
  Future<List<SentenceCollection>> loadAll() async {
    final list = storage.values.toList();
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  @override
  Future<SentenceCollection?> getById(String id) async {
    return storage[id];
  }

  @override
  Future<SentenceCollection> updateCollectionFromJson(
    String collectionId,
    String jsonStr,
  ) async {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map) {
      throw const FormatException('JSON must be an object.');
    }
    final map = Map<String, dynamic>.from(decoded);
    final rawId = map['id'];
    if (rawId == null || (rawId is String && rawId.trim().isEmpty)) {
      map['id'] = collectionId;
    }
    final updated = SentenceCollection.fromMap(map);
    if (updated.id != collectionId) {
      storage.remove(collectionId);
    }
    storage[updated.id] = updated;
    return updated;
  }

  @override
  Future<void> deleteCollection(String id) async {
    storage.remove(id);
  }
}

void main() {
  group('Collection JSON Updating (Repository logic)', () {
    test('updateCollectionFromJson updates title and sentences', () async {
      final repo = _FakeCollectionRepository();
      const initial = SentenceCollection(
        id: 'verbs_a1',
        title: 'Czasowniki A1',
        cefrLevel: 'A1',
        tags: ['verbs'],
        isCustomIsland: false,
        sentences: [
          Sentence(id: '1', targetText: '飲む', sourceText: 'pić'),
        ],
      );
      repo.storage[initial.id] = initial;

      const newJson = '''
{
  "id": "verbs_a1",
  "title": "Czasowniki A1 - Wersja 2",
  "cefrLevel": "A1",
  "tags": ["verbs", "updated"],
  "isCustomIsland": true,
  "sentences": [
    {
      "id": "1",
      "targetText": "飲む",
      "sourceText": "pić",
      "notes": "czasownik godan"
    },
    {
      "id": "2",
      "targetText": "食べる",
      "sourceText": "jeść",
      "emojis": ["🍽️"]
    }
  ]
}
''';

      final updated = await repo.updateCollectionFromJson('verbs_a1', newJson);
      expect(updated.title, 'Czasowniki A1 - Wersja 2');
      expect(updated.sentences.length, 2);
      expect(updated.sentences[0].notes, 'czasownik godan');
      expect(updated.sentences[1].emojis, equals(['🍽️']));
    });

    test('updateCollectionFromJson preserves collectionId when id omitted in JSON', () async {
      final repo = _FakeCollectionRepository();
      const initial = SentenceCollection(
        id: 'island_10',
        title: 'Moja Wyspa',
        cefrLevel: 'A2',
        tags: [],
        isCustomIsland: true,
        sentences: [],
      );
      repo.storage[initial.id] = initial;

      const newJsonWithoutId = '''
{
  "title": "Zaktualizowana Wyspa Bez ID",
  "sentences": [
    {
      "id": "s1",
      "targetText": "猫",
      "sourceText": "kot"
    }
  ]
}
''';

      final updated = await repo.updateCollectionFromJson('island_10', newJsonWithoutId);
      expect(updated.id, 'island_10');
      expect(updated.title, 'Zaktualizowana Wyspa Bez ID');
      expect(updated.sentences.length, 1);
    });
  });

  group('CollectionsScreen Tile Buttons & Edit JSON Dialog UI', () {
    testWidgets('shows copy and edit JSON buttons in top-right of island tile', (tester) async {
      final fakeRepo = _FakeCollectionRepository();
      const initial = SentenceCollection(
        id: 'island_1',
        title: 'Wyspa Restauracja',
        cefrLevel: 'A1',
        tags: ['jedzenie'],
        isCustomIsland: false,
        sentences: [
          Sentence(id: 's1', targetText: '注文します', sourceText: 'Zamawiam'),
        ],
      );
      fakeRepo.storage[initial.id] = initial;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: CollectionsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify collection tile is rendered
      expect(find.text('Wyspa Restauracja'), findsOneWidget);

      // Verify copy JSON button in top right
      expect(find.byTooltip('Kopiuj JSON wyspy'), findsOneWidget);

      // Verify edit JSON button in top right
      expect(find.byTooltip('Edytuj JSON wyspy (wklej nowy)'), findsOneWidget);

      // Tap copy JSON button
      await tester.tap(find.byTooltip('Kopiuj JSON wyspy'));
      await tester.pump();
      expect(find.textContaining('Skopiowano JSON wyspy "Wyspa Restauracja"'), findsOneWidget);

      // Tap edit JSON button to open dialog
      await tester.tap(find.byTooltip('Edytuj JSON wyspy (wklej nowy)'));
      await tester.pumpAndSettle();

      // Verify EditCollectionJsonDialog is open
      expect(find.text('Edycja JSON wyspy'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Wklej ze schowka'), findsOneWidget);
      expect(find.text('Formatuj'), findsOneWidget);
      expect(find.text('Zapisz i zaktualizuj wyspę'), findsOneWidget);

      // Paste new JSON into text field and save
      const updatedJson = '''
{
  "id": "island_1",
  "title": "Wyspa Restauracja - Zaktualizowana",
  "sentences": [
    {
      "id": "s1",
      "targetText": "水をください",
      "sourceText": "Poproszę wodę",
      "notes": "zwrot grzecznościowy"
    }
  ]
}
''';
      await tester.enterText(find.byType(TextField), updatedJson);
      await tester.pump();

      // Click save
      await tester.tap(find.text('Zapisz i zaktualizuj wyspę'));
      await tester.pumpAndSettle();

      // Dialog should close, and collection list should show updated title
      expect(find.text('Edycja JSON wyspy'), findsNothing);
      expect(find.text('Wyspa Restauracja - Zaktualizowana'), findsOneWidget);
    });
  });
}
