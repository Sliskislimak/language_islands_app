import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/data/repositories/collection_repository.dart';
import 'package:language_islands_app/features/collections/presentation/manage_collection_screen.dart';
import 'package:language_islands_app/features/collections/presentation/sentence_edit_dialog.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/sentence_card_widget.dart';

class _FakeCollectionRepo extends CollectionRepository {
  final Map<String, SentenceCollection> storage = {};

  @override
  Future<List<SentenceCollection>> loadAll() async {
    final list = storage.values.toList();
    list.sort((a, b) => a.title.compareTo(b.title));
    return list;
  }

  @override
  Future<SentenceCollection?> getById(String id) async => storage[id];

  @override
  Future<void> addSentence(String collectionId, Sentence sentence) async {
    final col = storage[collectionId]!;
    final list = List<Sentence>.from(col.sentences)..add(sentence);
    storage[collectionId] = col.copyWith(sentences: list);
  }

  @override
  Future<void> updateSentence(String collectionId, Sentence sentence) async {
    final col = storage[collectionId]!;
    final list = List<Sentence>.from(col.sentences);
    final idx = list.indexWhere((s) => s.id == sentence.id);
    if (idx >= 0) {
      list[idx] = sentence;
      storage[collectionId] = col.copyWith(sentences: list);
    }
  }

  @override
  Future<void> deleteSentence(String collectionId, String sentenceId) async {
    final col = storage[collectionId]!;
    final list = col.sentences.where((s) => s.id != sentenceId).toList();
    storage[collectionId] = col.copyWith(sentences: list);
  }

  @override
  Future<void> reorderSentences(
    String collectionId,
    int oldIndex,
    int newIndex,
  ) async {
    final col = storage[collectionId]!;
    final list = List<Sentence>.from(col.sentences);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    storage[collectionId] = col.copyWith(sentences: list);
  }

  @override
  Future<void> updateCollection(SentenceCollection collection) async {
    storage[collection.id] = collection;
  }
}

void main() {
  group('Single Sentence Operations on Repository & Controller', () {
    late _FakeCollectionRepo repo;
    late ProviderContainer container;

    setUp(() {
      repo = _FakeCollectionRepo();
      const col = SentenceCollection(
        id: 'test_island',
        title: 'Podstawowe zwroty',
        cefrLevel: 'A1',
        tags: ['basics'],
        isCustomIsland: true,
        sentences: [
          Sentence(id: 's1', targetText: 'おはよう', sourceText: 'Dzień dobry'),
          Sentence(id: 's2', targetText: 'ありがとう', sourceText: 'Dziękuję'),
        ],
      );
      repo.storage[col.id] = col;

      container = ProviderContainer(
        overrides: [
          collectionRepositoryProvider.overrideWithValue(repo),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('addSentence adds a single new sentence to collection', () async {
      final controller =
          container.read(collectionsControllerProvider.notifier);

      const newSentence = Sentence(
        id: 's3',
        targetText: 'さようなら',
        sourceText: 'Do widzenia',
        phoneticReading: 'Sayounara',
      );

      await controller.addSentence('test_island', newSentence);

      final updated = await repo.getById('test_island');
      expect(updated!.sentences.length, 3);
      expect(updated.sentences.last.targetText, 'さようなら');
      expect(updated.sentences.last.sourceText, 'Do widzenia');
      expect(updated.sentences.last.phoneticReading, 'Sayounara');
    });

    test('updateSentence edits targetText and sourceText of existing sentence',
        () async {
      final controller =
          container.read(collectionsControllerProvider.notifier);

      const modified = Sentence(
        id: 's1',
        targetText: 'おはようございます',
        sourceText: 'Dzień dobry (uprzejmie)',
      );

      await controller.updateSentence('test_island', modified);

      final updated = await repo.getById('test_island');
      expect(updated!.sentences.first.targetText, 'おはようございます');
      expect(updated.sentences.first.sourceText, 'Dzień dobry (uprzejmie)');
    });

    test('deleteSentence removes specific sentence from collection', () async {
      final controller =
          container.read(collectionsControllerProvider.notifier);

      await controller.deleteSentence('test_island', 's1');

      final updated = await repo.getById('test_island');
      expect(updated!.sentences.length, 1);
      expect(updated.sentences.first.id, 's2');
    });

    test('reorderSentences reorders sentences inside collection', () async {
      final controller =
          container.read(collectionsControllerProvider.notifier);

      await controller.reorderSentences('test_island', 0, 2);

      final updated = await repo.getById('test_island');
      expect(updated!.sentences.first.id, 's2');
      expect(updated.sentences.last.id, 's1');
    });
  });

  group('SentenceEditDialog UI Tests', () {
    testWidgets('Renders create dialog and submits valid sentence',
        (tester) async {
      Sentence? savedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showSentenceEditDialog(
                    context,
                    collectionId: 'col_1',
                    targetLanguageCode: 'ja',
                    onSave: (s) async {
                      savedResult = s;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Dodaj nową fiszkę'), findsOneWidget);
      expect(find.text('Dodaj fiszkę'), findsOneWidget);

      // Enter targetText and sourceText
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '乾杯');
      await tester.enterText(textFields.at(1), 'Na zdrowie');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dodaj fiszkę'));
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.targetText, '乾杯');
      expect(savedResult!.sourceText, 'Na zdrowie');
    });

    testWidgets('Renders edit dialog with pre-populated values and updates',
        (tester) async {
      Sentence? savedResult;
      const initial = Sentence(
        id: 's_edit',
        targetText: '猫',
        sourceText: 'Kot',
        phoneticReading: 'Neko',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showSentenceEditDialog(
                    context,
                    collectionId: 'col_1',
                    sentence: initial,
                    targetLanguageCode: 'ja',
                    onSave: (s) async {
                      savedResult = s;
                    },
                  );
                },
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edytuj fiszkę'), findsOneWidget);
      expect(find.text('Zapisz zmiany'), findsOneWidget);
      expect(find.text('猫'), findsOneWidget);
      expect(find.text('Kot'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(1), 'Kotek / Kot');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zapisz zmiany'));
      await tester.pumpAndSettle();

      expect(savedResult, isNotNull);
      expect(savedResult!.id, 's_edit');
      expect(savedResult!.targetText, '猫');
      expect(savedResult!.sourceText, 'Kotek / Kot');
    });
  });

  group('ManageCollectionScreen UI Tests', () {
    testWidgets('Displays sentences in collection and allows search filtering',
        (tester) async {
      final repo = _FakeCollectionRepo();
      const col = SentenceCollection(
        id: 'my_island',
        title: 'Jedzenie i Restauracja',
        cefrLevel: 'A2',
        tags: ['food'],
        isCustomIsland: true,
        sentences: [
          Sentence(id: 's1', targetText: '水をお願いします', sourceText: 'Poproszę wodę'),
          Sentence(id: 's2', targetText: 'お会計をお願いします', sourceText: 'Rachunek poproszę'),
        ],
      );
      repo.storage[col.id] = col;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: ManageCollectionScreen(
              collectionId: 'my_island',
              initialCollection: col,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jedzenie i Restauracja'), findsOneWidget);
      expect(find.text('水をお願いします'), findsOneWidget);
      expect(find.text('お会計をお願いします'), findsOneWidget);
      expect(find.text('Dodaj fiszkę'), findsOneWidget);

      // Search filter
      await tester.enterText(find.byType(TextField).first, 'wodę');
      await tester.pumpAndSettle();

      expect(find.text('水をお願いします'), findsOneWidget);
      expect(find.text('お会計をお願いします'), findsNothing);
    });
  });

  group('SentenceCardWidget Edit Button Test', () {
    testWidgets('SentenceCardWidget displays edit button and triggers callback',
        (tester) async {
      bool editTapped = false;
      const sentence = Sentence(
        id: 's_card',
        targetText: '本を読む',
        sourceText: 'Czytać książkę',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceCardWidget(
              sentence: sentence,
              displayIndex: 1,
              isActive: true,
              isRevealed: true,
              currentMode: PracticeMode.shadowing,
              onPlayAudio: () {},
              onToggleReveal: () {},
              onRate: (_) {},
              onEdit: () {
                editTapped = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editButton =
          find.byKey(const ValueKey('sentence_card_edit_button'));
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(editTapped, isTrue);
    });
  });
}
