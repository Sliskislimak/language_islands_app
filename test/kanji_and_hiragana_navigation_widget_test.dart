import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/kanji/presentation/screens/kanji_dictionary_screen.dart';
import 'package:language_islands_app/features/kanji/presentation/screens/kanji_screen.dart';
import 'package:language_islands_app/features/kanji/presentation/screens/kanji_study_session_screen.dart';
import 'package:language_islands_app/features/kanji/providers/kanji_controller.dart';
import 'package:language_islands_app/features/main/presentation/main_navigation_screen.dart';

class _FakeCollectionsController extends CollectionsController {
  @override
  Future<List<SentenceCollection>> build() async => [];
}

class _FakeKanjiController extends KanjiController {
  List<KanjiEntry> _items = [];

  _FakeKanjiController([List<KanjiEntry>? initial]) {
    if (initial != null) _items = initial;
  }

  @override
  Future<List<KanjiEntry>> build() async => _items;

  @override
  Future<void> addKanji(List<KanjiEntry> entries) async {
    _items = [..._items, ...entries];
    state = AsyncData(_items);
  }

  @override
  Future<void> removeKanji(String kanjiChar) async {
    _items = _items.where((e) => e.kanji != kanjiChar).toList();
    state = AsyncData(_items);
  }

  @override
  Future<void> updateMastery(String kanjiChar, int score) async {
    final idx = _items.indexWhere((e) => e.kanji == kanjiChar);
    if (idx >= 0) {
      _items = List<KanjiEntry>.from(_items);
      _items[idx] = _items[idx].copyWith(
        masteryScore: score,
        totalReps: _items[idx].totalReps + 1,
      );
      state = AsyncData(_items);
    }
  }
}

void main() {
  group('MainNavigationScreen Tab Switching Tests', () {
    testWidgets('Renders 3 tabs: Shadowing, Hiragana, Kanji and switches correctly',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionsControllerProvider.overrideWith(_FakeCollectionsController.new),
            kanjiControllerProvider.overrideWith(_FakeKanjiController.new),
          ],
          child: MaterialApp(
            theme: AppTheme.japaneseDarkTheme,
            home: const MainNavigationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Domyślnie widzimy tab 0 (Shadowing / Language Islands)
      expect(find.text('Language Islands'), findsOneWidget);
      expect(find.text('Shadowing'), findsOneWidget);
      expect(find.text('Hiragana'), findsOneWidget);
      expect(find.text('Kanji'), findsOneWidget);

      // Przełącz na Hiraganę
      await tester.tap(find.text('Hiragana'));
      await tester.pumpAndSettle();

      expect(find.text('Hiragana · ひらがな'), findsOneWidget);
      expect(find.text('Podstawowe (46)'), findsOneWidget);
      expect(find.text('Dźwięczne (25)'), findsOneWidget);
      expect(find.text('Złożone (33)'), findsOneWidget);

      // Przełącz na Kanji
      await tester.tap(find.text('Kanji'));
      await tester.pumpAndSettle();

      expect(find.text('Nauka Kanji · 漢字'), findsOneWidget);
      expect(find.text('Brak znaków do nauki'), findsOneWidget);
      expect(find.text('Przeglądaj Słownik Kanji'), findsOneWidget);
    });
  });

  group('KanjiScreen & Dictionary Tests', () {
    testWidgets('Opens dictionary and adds kanji to study list', (tester) async {
      final fakeKanji = _FakeKanjiController();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kanjiControllerProvider.overrideWith(() => fakeKanji),
          ],
          child: MaterialApp(
            theme: AppTheme.japaneseDarkTheme,
            home: const KanjiScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kliknij "Wybierz Kanji ze słownika"
      await tester.tap(find.text('Wybierz Kanji ze słownika'));
      await tester.pumpAndSettle();

      // Jesteśmy w KanjiDictionaryScreen
      expect(find.text('Słownik Kanji'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Dodaj pojedynczy znak "日" za pomocą ikony add_circle
      final addButtons = find.byIcon(Icons.add_circle_outline_rounded);
      expect(addButtons, findsWidgets);

      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Wracamy do KanjiScreen
      Navigator.of(tester.element(find.byType(KanjiDictionaryScreen))).pop();
      await tester.pumpAndSettle();

      // Teraz znak powinien być widoczny w liście
      expect(find.text('Rozpocznij naukę (1 kart)'), findsOneWidget);
    });
  });

  group('KanjiStudySessionScreen Flashcards Test', () {
    testWidgets('Displays front, flips to back on tap, and rates mastery',
        (tester) async {
      final fakeKanji = _FakeKanjiController([
        const KanjiEntry(
          kanji: '日',
          meanings: ['dzień', 'słońce'],
          onyomi: ['ニチ', 'ジツ'],
          kunyomi: ['ひ', '-び'],
          strokeCount: 4,
          jlptLevel: 'N5',
          examples: [
            KanjiExampleWord(word: '日本', reading: 'にほん', meaning: 'Japonia'),
          ],
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kanjiControllerProvider.overrideWith(() => fakeKanji),
          ],
          child: MaterialApp(
            theme: AppTheme.japaneseDarkTheme,
            home: KanjiStudySessionScreen(
              studyCards: [
                const KanjiEntry(
                  kanji: '日',
                  meanings: ['dzień', 'słońce'],
                  onyomi: ['ニチ', 'ジツ'],
                  kunyomi: ['ひ', '-び'],
                  strokeCount: 4,
                  jlptLevel: 'N5',
                  examples: [
                    KanjiExampleWord(word: '日本', reading: 'にほん', meaning: 'Japonia'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Karta 1 z 1'), findsOneWidget);
      expect(find.text('日'), findsOneWidget);
      expect(find.text('Dotknij karty, aby sprawdzić odpowiedź'), findsOneWidget);

      // Dotknij karty, aby odwrócić
      await tester.tap(find.text('Dotknij karty, aby sprawdzić odpowiedź'));
      await tester.pumpAndSettle();

      // Tył karty powinien pokazywać znaczenia i słówka
      expect(find.text('dzień, słońce'), findsOneWidget);
      expect(find.text('日本'), findsOneWidget);

      // Oceń na 5 gwiazdek (5★)
      await tester.tap(find.text('5★'));
      await tester.pumpAndSettle();

      // Sesja ukończona!
      expect(find.text('Sesja ukończona! 🎉'), findsOneWidget);
    });
  });
}
