import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/sentence_card_widget.dart';

void main() {
  group('Sentence Model with Notes & Emojis', () {
    test('serializes and deserializes notes and emojis in JSON correctly', () {
      final jsonMap = {
        'id': 's_101',
        'targetText': 'El gato está en el hospital.',
        'phoneticReading': 'El gato esta en el hospital.',
        'sourceText': 'Kot jest w szpitalu.',
        'notes': 'Reguła: estar + en oznacza przebywanie w danym miejscu.',
        'emojis': ['🐱', '🏥'],
        'comprehensionScore': 4,
        'speakingScore': 5,
        'totalReps': 12,
      };

      final sentence = Sentence.fromMap(jsonMap);

      expect(sentence.id, 's_101');
      expect(sentence.notes, 'Reguła: estar + en oznacza przebywanie w danym miejscu.');
      expect(sentence.hasNotes, isTrue);
      expect(sentence.emojis, equals(['🐱', '🏥']));
      expect(sentence.visualEmojis, equals(['🐱', '🏥']));

      final exportedMap = sentence.toMap();
      expect(exportedMap['notes'], 'Reguła: estar + en oznacza przebywanie w danym miejscu.');
      expect(exportedMap['emojis'], equals(['🐱', '🏥']));
    });

    test('supports aliases for notes field (backNotes, grammarNotes, theory)', () {
      final s1 = Sentence.fromMap({
        'id': '1',
        'targetText': 'A',
        'sourceText': 'B',
        'backNotes': 'Notatka z tyłu',
      });
      expect(s1.notes, 'Notatka z tyłu');

      final s2 = Sentence.fromMap({
        'id': '2',
        'targetText': 'A',
        'sourceText': 'B',
        'grammarNotes': 'Teoria gramatyczna',
      });
      expect(s2.notes, 'Teoria gramatyczna');

      final s3 = Sentence.fromMap({
        'id': '3',
        'targetText': 'A',
        'sourceText': 'B',
        'theory': 'Teoria',
      });
      expect(s3.notes, 'Teoria');
    });

    test('SentenceCollection toJsonString outputs notes and emojis in exported JSON', () {
      final collection = SentenceCollection(
        id: 'test_col',
        title: 'Testowa Kolekcja',
        cefrLevel: 'A1',
        tags: const ['test'],
        isCustomIsland: true,
        sentences: [
          const Sentence(
            id: 's_1',
            targetText: '毎朝コーヒーを飲みます。',
            phoneticReading: 'Maiasa kōhī o nomimasu.',
            sourceText: 'Piję kawę każdego ranka.',
            notes: 'を biernik, 飲みます forma grzeczna',
            emojis: ['☕'],
          ),
        ],
      );

      final jsonStr = collection.toJsonString(pretty: true);
      expect(jsonStr, contains('"notes": "を biernik, 飲みます forma grzeczna"'));
      expect(jsonStr, contains('"emojis"'));
      expect(jsonStr, contains('☕'));

      final parsed = SentenceCollection.fromJsonString(jsonStr);
      expect(parsed.sentences.first.notes, 'を biernik, 飲みます forma grzeczna');
      expect(parsed.sentences.first.emojis, equals(['☕']));
    });

    test('visualEmojis automatically detects cues when emojis list is empty', () {
      const sentence = Sentence(
        id: 's_cat',
        targetText: '猫は病院にいます。',
        phoneticReading: 'bioni ni ikimasu',
        sourceText: 'Kot jest w szpitalu.',
      );

      expect(sentence.emojis, isEmpty);
      expect(sentence.visualEmojis, containsAll(['🐱', '🏥']));
    });

    test('Sentence copyWith can update or clear notes', () {
      const sentence = Sentence(
        id: '1',
        targetText: 'T',
        sourceText: 'S',
        notes: 'Poprzednia notatka',
      );

      final updated = sentence.copyWith(notes: 'Nowa notatka');
      expect(updated.notes, 'Nowa notatka');

      final cleared = sentence.copyWith(clearNotes: true);
      expect(cleared.notes, isNull);
      expect(cleared.hasNotes, isFalse);
    });
  });

  group('SentenceCardWidget UI & Interactions', () {
    testWidgets('displays flip button and auto-detected emojis in bottom-right', (tester) async {
      const sentence = Sentence(
        id: '1',
        targetText: 'El gato duerme.',
        sourceText: 'Kot śpi.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceCardWidget(
              sentence: sentence,
              displayIndex: 1,
              isActive: false,
              isRevealed: false,
              currentMode: PracticeMode.shadowing,
              onPlayAudio: () {},
              onToggleReveal: () {},
              onRate: (_) {},
            ),
          ),
        ),
      );

      // Verify flip arrow icon in top right
      expect(find.byIcon(Icons.turn_right_rounded), findsOneWidget);

      // Verify cat emoji is displayed (detected from gato/kot)
      expect(find.text('🐱'), findsOneWidget);

      // Flip card to back by tapping the flip arrow
      await tester.tap(find.byIcon(Icons.turn_right_rounded));
      await tester.pumpAndSettle();

      // Card is now flipped to the back:
      // Verify lock icon button and copy icon button are present
      expect(find.byTooltip('Kopiuj zawartość odwrotu'), findsOneWidget);
      expect(find.textContaining('Notatki'), findsOneWidget);

      // Verify return to front flip icon is present
      expect(find.byIcon(Icons.turn_left_rounded), findsOneWidget);

      // Tap return arrow to flip back
      await tester.tap(find.byIcon(Icons.turn_left_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.turn_right_rounded), findsOneWidget);
    });

    testWidgets('allows editing notes and saves on lock/flip', (tester) async {
      String? savedNotes;
      const sentence = Sentence(
        id: '1',
        targetText: 'Test',
        sourceText: 'Test',
        notes: 'Wstępna teoria',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentenceCardWidget(
              sentence: sentence,
              displayIndex: 1,
              isActive: false,
              isRevealed: false,
              currentMode: PracticeMode.shadowing,
              onPlayAudio: () {},
              onToggleReveal: () {},
              onRate: (_) {},
              onSaveNotes: (notes) => savedNotes = notes,
            ),
          ),
        ),
      );

      // Flip to back
      await tester.tap(find.byIcon(Icons.turn_right_rounded));
      await tester.pumpAndSettle();

      // Since notes existed, card starts in locked mode
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('Wstępna teoria'), findsOneWidget);

      // Tap lock button in top-left to unlock for editing
      await tester.tap(find.byIcon(Icons.lock_outline_rounded));
      await tester.pumpAndSettle();

      // Now unlocked
      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Enter new notes
      await tester.enterText(find.byType(TextField), 'Zaktualizowana reguła gramatyczna.');
      await tester.pump();

      // Lock again to save
      await tester.tap(find.byIcon(Icons.lock_open_rounded));
      await tester.pumpAndSettle();

      expect(savedNotes, 'Zaktualizowana reguła gramatyczna.');
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });
  });
}
