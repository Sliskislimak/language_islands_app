import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/data/datasets/cyrillic_data.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/cyrillic/presentation/screens/cyrillic_screen.dart';
import 'package:language_islands_app/features/kanji/providers/kanji_controller.dart';
import 'package:language_islands_app/features/main/presentation/main_navigation_screen.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/audio_settings_sheet.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

class _FakeCollectionsController extends CollectionsController {
  @override
  Future<List<SentenceCollection>> build() async => [];
}

class _FakeKanjiController extends KanjiController {
  @override
  Future<List<KanjiEntry>> build() async => [];
}

class _WidgetRefFake implements WidgetRef {
  _WidgetRefFake(this.container);
  final ProviderContainer container;

  @override
  BuildContext get context => throw UnimplementedError();

  @override
  bool exists(ProviderBase<Object?> provider) => container.exists(provider);

  @override
  void invalidate(ProviderOrFamily provider) => container.invalidate(provider);

  @override
  void listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    container.listen(provider, listener, onError: onError);
  }

  @override
  ProviderSubscription<T> listenManual<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool fireImmediately = false,
  }) {
    return container.listen(
      provider,
      listener,
      onError: onError,
      fireImmediately: fireImmediately,
    );
  }

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  T refresh<T>(Refreshable<T> provider) => container.refresh(provider);

  @override
  T watch<T>(ProviderListenable<T> provider) => container.read(provider);
}

void main() {
  group('Russian AppLanguage Support', () {
    test('AppLanguage includes Russian with Neural TTS voice and unlocked default', () {
      final russian = AppLanguage.fromCode('ru');
      expect(russian, isNotNull);
      expect(russian, equals(AppLanguage.russian));
      expect(russian!.code, equals('ru'));
      expect(russian.name, equals('Rosyjski'));
      expect(russian.nativeName, equals('Русский'));
      expect(russian.flagEmoji, equals('🇷🇺'));
      expect(russian.voiceName, equals('ru-RU-SvetlanaNeural'));
      expect(russian.locale, equals('ru-RU'));
      expect(russian.voiceDisplayName, equals('Svetlana'));
      expect(AppLanguage.defaultUnlockedCodes, contains('ru'));
    });

    testWidgets('AudioSettingsSheet allows selecting Rosyjski as target language',
        (tester) async {
      const collection = SentenceCollection(
        id: 'ru_col',
        title: 'Rosyjski Podstawy',
        cefrLevel: 'A1',
        tags: ['ru'],
        isCustomIsland: false,
        targetLanguage: 'ja',
        translationLanguage: 'pl',
        sentences: [
          Sentence(
            id: 's_ru_1',
            targetText: 'Привет, как дела?',
            sourceText: 'Cześć, jak się masz?',
          ),
        ],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(practiceSessionProvider.notifier).startSession(collection);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.japaneseDarkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      showAudioSettingsSheet(context, _WidgetRefFake(container)),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Rosyjski'), 200);
      await tester.tap(find.text('Rosyjski'));
      await tester.pumpAndSettle();

      expect(container.read(practiceSessionProvider)!.targetLanguage, equals('ru'));
    });
  });

  group('CyrillicData & CyrillicScreen', () {
    test('CyrillicData contains all 33 Russian letters without duplicates', () {
      expect(CyrillicData.allLetters.length, equals(33));
      expect(CyrillicData.vowels.length, equals(10));
      expect(CyrillicData.consonants.length, equals(21));
      expect(CyrillicData.signs.length, equals(2));

      final uppercaseSet =
          CyrillicData.allLetters.map((item) => item.uppercase).toSet();
      expect(uppercaseSet.length, equals(33));
    });

    testWidgets('MainNavigationScreen navigates to Cyrylica tab and shows details sheet',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionsControllerProvider
                .overrideWith(_FakeCollectionsController.new),
            kanjiControllerProvider.overrideWith(_FakeKanjiController.new),
          ],
          child: MaterialApp(
            theme: AppTheme.japaneseDarkTheme,
            home: const MainNavigationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cyrylica'), findsOneWidget);

      await tester.tap(find.text('Cyrylica'));
      await tester.pumpAndSettle();

      expect(find.byType(CyrillicScreen), findsOneWidget);
      expect(find.text('Cyrylica · Азбука'), findsOneWidget);
      expect(find.text('Alfabet (33)'), findsOneWidget);
      expect(find.text('Samogłoski (10)'), findsOneWidget);
      expect(find.text('Spółgłoski (21)'), findsOneWidget);
      expect(find.text('Znaki (2)'), findsOneWidget);

      // Tap first letter tile (А а)
      await tester.tap(find.text('А а'));
      await tester.pumpAndSettle();

      expect(find.text('Wymowa: /a/ · Samogłoska'), findsOneWidget);
      expect(find.text('арбуз (arbuz) · arbuz'), findsOneWidget);
      expect(find.text('Odsłuchaj literę'), findsOneWidget);
      expect(find.text('Przykład'), findsOneWidget);

      // Dismiss bottom sheet and switch to Znaki (2) tab
      Navigator.of(tester.element(find.text('Odsłuchaj literę'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Znaki (2)'));
      await tester.pumpAndSettle();

      expect(find.text('Ъ ъ'), findsOneWidget);
      expect(find.text('Ь ь'), findsOneWidget);
    });
  });
}
