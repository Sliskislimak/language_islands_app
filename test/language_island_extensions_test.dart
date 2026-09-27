import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/data/repositories/collection_repository.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_state.dart';
import 'package:language_islands_app/features/practice/sentence_display_lines.dart';

void main() {
  test('counts stats for each list on its own', () {
    final collection = SentenceCollection(
      id: 'verbs',
      title: 'Czasowniki',
      cefrLevel: 'A1',
      tags: const ['verbs'],
      isCustomIsland: true,
      sentences: [
        const Sentence(id: '1', targetText: 'あ', sourceText: 'a'),
        const Sentence(
          id: '2',
          targetText: 'い',
          sourceText: 'b',
          totalReps: 2,
          comprehensionScore: 3,
        ),
        const Sentence(
          id: '3',
          targetText: 'う',
          sourceText: 'c',
          totalReps: 4,
          comprehensionScore: 5,
          speakingScore: 5,
        ),
        const Sentence(
          id: '4',
          targetText: 'え',
          sourceText: 'd',
          totalReps: 1,
          speakingScore: 4,
        ),
      ],
    );

    final stats = collection.stats;
    expect(stats.sentenceCount, 4);
    expect(stats.newCount, 1);
    expect(stats.dueCount, 2);
    expect(stats.masteredCount, 1);
    expect(stats.totalReps, 7);
  });

  test('does not reuse an id that already belongs to another list', () {
    expect(
      independentCollectionId(baseId: 'verbs', idExists: (_) => false),
      'verbs',
    );
    const taken = {'verbs', 'verbs_2'};
    expect(
      independentCollectionId(baseId: 'verbs', idExists: taken.contains),
      'verbs_3',
    );
  });

  test('reads a list title from import JSON', () {
    expect(
      SentenceCollection.tryParseTitle('{"title":"  Poranki  ","id":"a"}'),
      'Poranki',
    );
    expect(SentenceCollection.tryParseTitle('not json'), isNull);
  });

  test('keeps katakana and romaji on separate lines', () {
    final lines = SentenceDisplayLines.resolve(
      const Sentence(
        id: '1',
        targetText: '毎朝コーヒーを飲みます。',
        katakana: 'コーヒー',
        phoneticReading: 'Maiasa kōhī o nomimasu.',
        sourceText: 'Piję kawę każdego ranka.',
      ),
    );

    expect(lines.targetText, '毎朝コーヒーを飲みます。');
    expect(lines.katakana, 'コーヒー');
    expect(lines.romaji, 'Maiasa kōhī o nomimasu.');
    expect(lines.katakana!.contains('Maiasa'), isFalse);
    expect(lines.romaji!.contains('コーヒー'), isFalse);
  });

  test(
    'splits a mixed phonetic reading so katakana is not on the romaji line',
    () {
      final lines = SentenceDisplayLines.resolve(
        const Sentence(
          id: '1',
          targetText: 'コーヒーを飲みます。',
          phoneticReading: 'コーヒーをのみます。 Koohii o nomimasu.',
          sourceText: 'Piję kawę.',
        ),
      );

      expect(lines.katakana, 'コーヒーをのみます。');
      expect(lines.romaji, 'Koohii o nomimasu.');
    },
  );

  test('loop mode cycles off, list, then single sentence', () {
    expect(LoopMode.off.next, LoopMode.list);
    expect(LoopMode.list.next, LoopMode.single);
    expect(LoopMode.single.next, LoopMode.off);

    const session = PracticeSessionState(
      collection: SentenceCollection(
        id: 'a',
        title: 'A',
        cefrLevel: 'A1',
        tags: [],
        isCustomIsland: false,
        sentences: [],
      ),
      mode: PracticeMode.shadowing,
      loopMode: LoopMode.list,
    );
    expect(session.isListLoopEnabled, isTrue);
    expect(session.isSingleSentenceLoop, isFalse);
  });
}
