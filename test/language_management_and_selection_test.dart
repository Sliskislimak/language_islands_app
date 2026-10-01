import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/presentation/collections_screen.dart';
import 'package:language_islands_app/features/collections/presentation/select_translation_voice_dialog.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/collections/providers/language_settings_controller.dart';
import 'package:language_islands_app/features/practice/playback_speed.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/audio_settings_sheet.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

class _FakeCollectionsController extends CollectionsController {
  @override
  Future<List<SentenceCollection>> build() async => [
        const SentenceCollection(
          id: 'test_col',
          title: 'Japoński N5',
          cefrLevel: 'A1',
          tags: ['n5'],
          isCustomIsland: false,
          translationLanguage: 'en',
          sentences: [
            Sentence(
              id: 's1',
              targetText: 'こんにちは',
              sourceText: 'Hello',
            ),
          ],
        ),
      ];
}

class _FakeLanguageSettingsController extends LanguageSettingsController {
  Set<String> _codes = {'en', 'pl'};

  @override
  Future<Set<String>> build() async => _codes;

  @override
  Future<bool> toggleLanguage(String code) async {
    final normalized = code.trim().toLowerCase();
    if (_codes.contains(normalized)) {
      if (_codes.length <= 1) return false;
      _codes = Set<String>.from(_codes)..remove(normalized);
      state = AsyncData(_codes);
      return true;
    } else {
      _codes = Set<String>.from(_codes)..add(normalized);
      state = AsyncData(_codes);
      return true;
    }
  }
}

class _FakeDefaultTranslationLanguageController
    extends DefaultTranslationLanguageController {
  String _code = 'en';

  @override
  Future<String> build() async => _code;

  @override
  Future<void> setLanguage(String code) async {
    _code = code;
    state = AsyncData(code);
  }
}

void main() {
  group('AppLanguage and Global Language Unlocking', () {
    test('AppLanguage contains English, Polish, Japanese and other major languages', () {
      expect(AppLanguage.supportedLanguages, isNotEmpty);
      final en = AppLanguage.fromCode('en');
      final pl = AppLanguage.fromCode('pl');

      expect(en, isNotNull);
      expect(en!.voiceName, equals('en-US-JennyNeural'));
      expect(pl, isNotNull);
      expect(pl!.voiceName, equals('pl-PL-MarekNeural'));
    });

    test('PlaybackSpeed presets include 0.7x and snapToPreset preserves 0.7x', () {
      expect(PlaybackSpeed.presets.contains(0.7), isTrue);
      expect(PlaybackSpeed.snapToPreset(0.7), equals(0.7));
      expect(PlaybackSpeed.formatLabel(0.7), equals('0.7x'));
    });
  });

  group('CollectionsScreen Translation Voice Entrypoints', () {
    testWidgets('shows voice button in AppBar and under more-vert (3 dots)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionsControllerProvider.overrideWith(_FakeCollectionsController.new),
            languageSettingsControllerProvider.overrideWith(_FakeLanguageSettingsController.new),
            defaultTranslationLanguageProvider
                .overrideWith(_FakeDefaultTranslationLanguageController.new),
          ],
          child: const MaterialApp(home: CollectionsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Voice button in AppBar
      expect(find.byTooltip('Głos lektora tłumaczenia'), findsWidgets);

      // Open 3-dots popup menu
      await tester.tap(find.byTooltip('Więcej opcji'));
      await tester.pumpAndSettle();

      // Voice option under 3 dots menu
      expect(find.text('Głos lektora tłumaczenia'), findsOneWidget);
      expect(find.text('Import JSON'), findsOneWidget);

      // Tap voice option under 3 dots
      await tester.tap(find.text('Głos lektora tłumaczenia'));
      await tester.pumpAndSettle();

      // Voice dialog opened
      expect(find.byType(SelectTranslationVoiceDialog), findsOneWidget);
      expect(find.text('Wybierz głos do czytania tłumaczeń zdań'), findsOneWidget);
      expect(find.text('Angielski'), findsOneWidget);
      expect(find.text('Polski'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Zamknij'));
      await tester.pumpAndSettle();

      expect(find.byType(SelectTranslationVoiceDialog), findsNothing);
    });

    testWidgets('shows voice button and 3-dots options on collection card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            collectionsControllerProvider.overrideWith(_FakeCollectionsController.new),
            languageSettingsControllerProvider.overrideWith(_FakeLanguageSettingsController.new),
            defaultTranslationLanguageProvider
                .overrideWith(_FakeDefaultTranslationLanguageController.new),
          ],
          child: const MaterialApp(home: CollectionsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Collection card shows language chip
      expect(find.textContaining('Angielski (Jenny)'), findsOneWidget);

      // Card has 3-dots menu
      expect(find.byTooltip('Więcej opcji wyspy'), findsOneWidget);
      await tester.tap(find.byTooltip('Więcej opcji wyspy'));
      await tester.pumpAndSettle();

      expect(find.text('Głos lektora tłumaczenia'), findsOneWidget);
      expect(find.text('Edytuj JSON wyspy'), findsOneWidget);
      expect(find.text('Kopiuj JSON wyspy'), findsOneWidget);
    });
  });

  group('AudioSettingsSheet Language Selection and 0.7x Button Pink Highlighting', () {
    testWidgets('selects translation language and highlights 0.7x button in pink', (tester) async {
      final collection = const SentenceCollection(
        id: 'test_col',
        title: 'Japoński N5',
        cefrLevel: 'A1',
        tags: ['n5'],
        isCustomIsland: false,
        translationLanguage: 'en',
        sentences: [
          Sentence(
            id: 's1',
            targetText: 'これは本です',
            sourceText: 'This is a book',
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          languageSettingsControllerProvider.overrideWith(_FakeLanguageSettingsController.new),
          defaultTranslationLanguageProvider
              .overrideWith(_FakeDefaultTranslationLanguageController.new),
        ],
      );
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
                  onPressed: () => showAudioSettingsSheet(context, WidgetRefFake(container)),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify Translation Language section is present
      expect(find.text('JĘZYK LEKTORA TŁUMACZENIA'), findsOneWidget);
      expect(find.text('Angielski (Jenny)'), findsOneWidget);
      expect(find.text('Polski (Marek)'), findsOneWidget);

      // Switch to Polski
      await tester.tap(find.text('Polski (Marek)'));
      await tester.pumpAndSettle();

      expect(container.read(practiceSessionProvider)!.translationLanguage, equals('pl'));

      // Switch back to Angielski
      await tester.tap(find.text('Angielski (Jenny)'));
      await tester.pumpAndSettle();

      expect(container.read(practiceSessionProvider)!.translationLanguage, equals('en'));

      // Scroll to 0.7x button and tap
      await tester.scrollUntilVisible(find.text('0.7x'), 200);
      await tester.tap(find.text('0.7x'));
      await tester.pumpAndSettle();

      // State is now 0.7
      expect(container.read(practiceSessionProvider)!.playbackSpeed, equals(0.7));

      // Verify the 0.7x button is highlighted with pink color (AppTheme.sakuraPrimary)
      final material07 = tester.widget<Material>(
        find.ancestor(
          of: find.text('0.7x'),
          matching: find.byType(Material),
        ).first,
      );
      expect(material07.color, equals(AppTheme.sakuraPrimary));
    });
  });
}

class WidgetRefFake implements WidgetRef {
  WidgetRefFake(this.container);
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
    return container.listen(provider, listener, onError: onError, fireImmediately: fireImmediately);
  }

  @override
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  @override
  T refresh<T>(Refreshable<T> provider) => container.refresh(provider);

  @override
  T watch<T>(ProviderListenable<T> provider) => container.read(provider);
}
