import 'dart:convert';

/// Reprezentuje przykładowe słowo złożone ze znaku kanji.
class KanjiExampleWord {
  const KanjiExampleWord({
    required this.word,
    required this.reading,
    required this.meaning,
  });

  final String word;
  final String reading;
  final String meaning;

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'reading': reading,
      'meaning': meaning,
    };
  }

  factory KanjiExampleWord.fromMap(Map<String, dynamic> map) {
    return KanjiExampleWord(
      word: (map['word'] ?? '').toString().trim(),
      reading: (map['reading'] ?? map['kana'] ?? '').toString().trim(),
      meaning: (map['meaning'] ?? map['translation'] ?? '').toString().trim(),
    );
  }
}

/// Model pojedynczego znaku Kanji w słowniku oraz w osobistej kolekcji nauki.
class KanjiEntry {
  const KanjiEntry({
    required this.kanji,
    required this.meanings,
    required this.onyomi,
    required this.kunyomi,
    this.strokeCount,
    this.jlptLevel = 'N5',
    this.examples = const [],
    this.masteryScore = 0,
    this.totalReps = 0,
    this.notes,
    this.addedAt,
    this.lastStudiedAt,
  });

  /// Znak Kanji (np. "日")
  final String kanji;

  /// Lista znaczeń (np. ["dzień", "słońce"])
  final List<String> meanings;

  /// Czytania On'yomi (Katakana, np. ["ニチ", "ジツ"])
  final List<String> onyomi;

  /// Czytania Kun'yomi (Hiragana, np. ["ひ", "-び", "-か"])
  final List<String> kunyomi;

  /// Liczba kresek (np. 4)
  final int? strokeCount;

  /// Poziom JLPT (np. "N5", "N4", "N3", "N2", "N1")
  final String jlptLevel;

  /// Przykładowe słówka
  final List<KanjiExampleWord> examples;

  /// Stopień opanowania od 0 do 5 gwiazdek:
  /// 0 = Nowy, 1-4 = W trakcie nauki, 5 = Opanowany (Mastered)
  final int masteryScore;

  /// Liczba ukończonych powtórzeń fiszki
  final int totalReps;

  /// Opcjonalne notatki użytkownika
  final String? notes;

  /// Kiedy dodano do listy nauki
  final DateTime? addedAt;

  /// Ostatnia data powtórki
  final DateTime? lastStudiedAt;

  String get id => kanji;

  bool get isNew => masteryScore == 0;
  bool get isLearning => masteryScore > 0 && masteryScore < 5;
  bool get isMastered => masteryScore >= 5;

  String get meaningsDisplay => meanings.join(', ');
  String get onyomiDisplay => onyomi.isEmpty ? '—' : onyomi.join(', ');
  String get kunyomiDisplay => kunyomi.isEmpty ? '—' : kunyomi.join(', ');

  KanjiEntry copyWith({
    String? kanji,
    List<String>? meanings,
    List<String>? onyomi,
    List<String>? kunyomi,
    int? strokeCount,
    String? jlptLevel,
    List<KanjiExampleWord>? examples,
    int? masteryScore,
    int? totalReps,
    String? notes,
    DateTime? addedAt,
    DateTime? lastStudiedAt,
  }) {
    return KanjiEntry(
      kanji: kanji ?? this.kanji,
      meanings: meanings ?? this.meanings,
      onyomi: onyomi ?? this.onyomi,
      kunyomi: kunyomi ?? this.kunyomi,
      strokeCount: strokeCount ?? this.strokeCount,
      jlptLevel: jlptLevel ?? this.jlptLevel,
      examples: examples ?? this.examples,
      masteryScore: (masteryScore ?? this.masteryScore).clamp(0, 5),
      totalReps: totalReps ?? this.totalReps,
      notes: notes ?? this.notes,
      addedAt: addedAt ?? this.addedAt,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kanji': kanji,
      'meanings': meanings,
      'onyomi': onyomi,
      'kunyomi': kunyomi,
      if (strokeCount != null) 'strokeCount': strokeCount,
      'jlptLevel': jlptLevel,
      'examples': examples.map((e) => e.toMap()).toList(),
      'masteryScore': masteryScore,
      'totalReps': totalReps,
      if (notes != null) 'notes': notes,
      if (addedAt != null) 'addedAt': addedAt!.toIso8601String(),
      if (lastStudiedAt != null) 'lastStudiedAt': lastStudiedAt!.toIso8601String(),
    };
  }

  factory KanjiEntry.fromMap(Map<String, dynamic> map) {
    final rawKanji = (map['kanji'] ?? map['character'] ?? '').toString().trim();

    // Tolerancyjne parsowanie meanings (lista lub przecinkowy string)
    List<String> parseStringList(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) {
        return raw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
      }
      if (raw is String) {
        return raw
            .split(RegExp(r'[,;/]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [raw.toString().trim()];
    }

    final rawExamples = map['examples'];
    final examples = <KanjiExampleWord>[];
    if (rawExamples is List) {
      for (final item in rawExamples) {
        if (item is Map<String, dynamic>) {
          examples.add(KanjiExampleWord.fromMap(item));
        } else if (item is Map) {
          examples.add(KanjiExampleWord.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawMastery = map['masteryScore'] ?? map['comprehensionScore'] ?? map['score'] ?? 0;
    final masteryInt = (rawMastery is num ? rawMastery.toInt() : int.tryParse('$rawMastery') ?? 0).clamp(0, 5);

    final rawReps = map['totalReps'] ?? map['reps'] ?? 0;
    final repsInt = rawReps is num ? rawReps.toInt() : int.tryParse('$rawReps') ?? 0;

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val);
      }
      return null;
    }

    return KanjiEntry(
      kanji: rawKanji,
      meanings: parseStringList(map['meanings'] ?? map['meaning']),
      onyomi: parseStringList(map['onyomi'] ?? map['on']),
      kunyomi: parseStringList(map['kunyomi'] ?? map['kun']),
      strokeCount: map['strokeCount'] is num
          ? (map['strokeCount'] as num).toInt()
          : int.tryParse('${map['strokeCount']}'),
      jlptLevel: (map['jlptLevel'] ?? map['jlpt'] ?? 'N5').toString().toUpperCase().trim(),
      examples: examples,
      masteryScore: masteryInt,
      totalReps: repsInt,
      notes: map['notes']?.toString(),
      addedAt: parseDate(map['addedAt']),
      lastStudiedAt: parseDate(map['lastStudiedAt']),
    );
  }

  String toJsonString({bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toMap());
    }
    return jsonEncode(toMap());
  }

  factory KanjiEntry.fromJsonString(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map) {
      throw const FormatException('Oczekiwano obiektu JSON dla KanjiEntry');
    }
    return KanjiEntry.fromMap(Map<String, dynamic>.from(decoded));
  }
}
