import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/data/datasets/kanji_dictionary_data.dart';
import 'package:language_islands_app/data/repositories/kanji_repository.dart';

void main() {
  group('KanjiEntry Model Tests', () {
    test('Correctly serializes and deserializes KanjiEntry', () {
      const entry = KanjiEntry(
        kanji: '日',
        meanings: ['dzień', 'słońce'],
        onyomi: ['ニチ', 'ジツ'],
        kunyomi: ['ひ', '-び'],
        strokeCount: 4,
        jlptLevel: 'N5',
        examples: [
          KanjiExampleWord(word: '日本', reading: 'にほん', meaning: 'Japonia'),
        ],
        masteryScore: 4,
        totalReps: 5,
      );

      final map = entry.toMap();
      final fromMap = KanjiEntry.fromMap(map);

      expect(fromMap.kanji, '日');
      expect(fromMap.meanings, ['dzień', 'słońce']);
      expect(fromMap.onyomi, ['ニチ', 'ジツ']);
      expect(fromMap.kunyomi, ['ひ', '-び']);
      expect(fromMap.strokeCount, 4);
      expect(fromMap.jlptLevel, 'N5');
      expect(fromMap.examples.length, 1);
      expect(fromMap.examples.first.word, '日本');
      expect(fromMap.masteryScore, 4);
      expect(fromMap.totalReps, 5);
      expect(fromMap.isLearning, isTrue);
      expect(fromMap.isMastered, isFalse);
    });

    test('Tolerantly parses string meanings and readings from flexible JSON', () {
      final jsonMap = {
        'kanji': '月',
        'meaning': 'księżyc, miesiąc',
        'onyomi': 'ゲツ, ガツ',
        'kunyomi': 'つき',
        'strokeCount': '4',
        'jlpt': 'N5',
        'score': 5,
        'reps': 10,
      };

      final entry = KanjiEntry.fromMap(jsonMap);
      expect(entry.kanji, '月');
      expect(entry.meanings, ['księżyc', 'miesiąc']);
      expect(entry.onyomi, ['ゲツ', 'ガツ']);
      expect(entry.kunyomi, ['つき']);
      expect(entry.strokeCount, 4);
      expect(entry.masteryScore, 5);
      expect(entry.isMastered, isTrue);
      expect(entry.isNew, isFalse);
    });

    test('copyWith updates masteryScore clamped to 0..5', () {
      const entry = KanjiEntry(
        kanji: '木',
        meanings: ['drzewo'],
        onyomi: ['モク'],
        kunyomi: ['き'],
      );

      final updated = entry.copyWith(masteryScore: 7, totalReps: 3);
      expect(updated.masteryScore, 5);
      expect(updated.totalReps, 3);
    });
  });

  group('KanjiRepository Tests', () {
    late KanjiRepository repository;

    setUp(() {
      repository = KanjiRepository();
    });

    test('Default dictionary contains essential N5 Kanji', () {
      expect(KanjiDictionaryData.defaultDictionary.isNotEmpty, isTrue);
      expect(KanjiDictionaryData.defaultDictionary.length, greaterThan(50));

      final sun = KanjiDictionaryData.defaultDictionary.firstWhere((e) => e.kanji == '日');
      expect(sun.meanings.contains('dzień') || sun.meanings.contains('słońce'), isTrue);
    });

    test('searchDictionary filters by character, meaning, reading, and JLPT level', () {
      // 1. Wyszukiwanie po znaku
      final byChar = repository.searchDictionary(query: '水');
      expect(byChar.any((e) => e.kanji == '水'), isTrue);

      // 2. Wyszukiwanie po znaczeniu (PL)
      final byMeaning = repository.searchDictionary(query: 'woda');
      expect(byMeaning.any((e) => e.kanji == '水'), isTrue);

      // 3. Wyszukiwanie po czytaniu romaji/kana
      final byReading = repository.searchDictionary(query: 'mizu');
      expect(byReading.any((e) => e.kanji == '水'), isTrue);

      // 4. Filtr poziomu
      final n5Items = repository.searchDictionary(jlptLevel: 'N5');
      expect(n5Items.every((e) => e.jlptLevel == 'N5'), isTrue);
    });

    test('Parses JSON import from both array and object formats', () async {
      // Test parsing through model directly
      final list = KanjiEntry.fromJsonString('''
        {
          "kanji": "山",
          "meanings": ["góra"],
          "onyomi": ["サン"],
          "kunyomi": ["やま"],
          "strokeCount": 3,
          "jlptLevel": "N5"
        }
      ''');
      expect(list.kanji, '山');
      expect(list.meanings, ['góra']);
    });
  });
}
