import 'dart:convert';

import 'package:language_islands_app/core/models/sentence.dart';

class SentenceCollection {
  const SentenceCollection({
    required this.id,
    required this.title,
    required this.cefrLevel,
    required this.tags,
    required this.isCustomIsland,
    required this.sentences,
    this.translationLanguage,
  });

  final String id;
  final String title;
  final String cefrLevel;
  final List<String> tags;
  final bool isCustomIsland;
  final List<Sentence> sentences;
  final String? translationLanguage;

  SentenceCollection copyWith({
    String? id,
    String? title,
    String? cefrLevel,
    List<String>? tags,
    bool? isCustomIsland,
    List<Sentence>? sentences,
    String? translationLanguage,
    bool clearTranslationLanguage = false,
  }) {
    return SentenceCollection(
      id: id ?? this.id,
      title: title ?? this.title,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      tags: tags ?? this.tags,
      isCustomIsland: isCustomIsland ?? this.isCustomIsland,
      sentences: sentences ?? this.sentences,
      translationLanguage: clearTranslationLanguage
          ? null
          : (translationLanguage ?? this.translationLanguage),
    );
  }

  factory SentenceCollection.fromJsonString(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Collection JSON must be an object with id, title and sentences.',
      );
    }
    return SentenceCollection.fromMap(decoded);
  }

  factory SentenceCollection.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final title = map['title'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Collection.id must be a non-empty string.');
    }
    if (title is! String || title.isEmpty) {
      throw FormatException('Collection "$id" is missing title.');
    }

    final rawSentences = map['sentences'];
    if (rawSentences is! List) {
      throw FormatException('Collection "$id" is missing a sentences array.');
    }

    return SentenceCollection(
      id: id,
      title: title,
      cefrLevel: _cefrLevel(map['cefrLevel']),
      tags: _tags(map['tags']),
      isCustomIsland: map['isCustomIsland'] == true,
      translationLanguage: _optionalString(
        map['translationLanguage'] ??
            map['translationLang'] ??
            map['sourceLanguage'] ??
            map['sourceLang'],
      ),
      sentences: [
        for (final item in rawSentences)
          if (item is Map<String, dynamic>)
            Sentence.fromMap(item)
          else if (item is Map)
            Sentence.fromMap(Map<String, dynamic>.from(item))
          else
            throw FormatException(
              'Collection "$id" contains a sentence that is not an object.',
            ),
      ],
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'title': title,
      'cefrLevel': cefrLevel,
      'tags': tags,
      'isCustomIsland': isCustomIsland,
      'sentences': [for (final sentence in sentences) sentence.toMap()],
    };
    if (translationLanguage != null && translationLanguage!.trim().isNotEmpty) {
      map['translationLanguage'] = translationLanguage!.trim();
    }
    return map;
  }

  String toJsonString({bool pretty = true}) {
    final map = toMap();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(map);
    }
    return jsonEncode(map);
  }

  static String? _optionalString(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static String _cefrLevel(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return 'Unassigned';
  }

  static List<String> _tags(Object? value) {
    if (value is! List) return const [];
    return [
      for (final tag in value)
        if (tag is String && tag.trim().isNotEmpty) tag.trim(),
    ];
  }

  /// Per-list counters. Global session metrics stay on the practice screen.
  CollectionListStats get stats {
    var newCount = 0;
    var dueCount = 0;
    var masteredCount = 0;
    var totalReps = 0;

    for (final sentence in sentences) {
      totalReps += sentence.totalReps;
      if (sentence.totalReps == 0) newCount++;
      if (_isDueForReview(sentence)) dueCount++;
      if (sentence.comprehensionScore == 5 && sentence.speakingScore == 5) {
        masteredCount++;
      }
    }

    return CollectionListStats(
      sentenceCount: sentences.length,
      newCount: newCount,
      dueCount: dueCount,
      masteredCount: masteredCount,
      totalReps: totalReps,
    );
  }

  static String? tryParseTitle(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) return null;
      final title = decoded['title'];
      if (title is! String) return null;
      final trimmed = title.trim();
      return trimmed.isEmpty ? null : trimmed;
    } on Object {
      return null;
    }
  }
}

class CollectionListStats {
  const CollectionListStats({
    required this.sentenceCount,
    required this.newCount,
    required this.dueCount,
    required this.masteredCount,
    required this.totalReps,
  });

  final int sentenceCount;
  final int newCount;
  final int dueCount;
  final int masteredCount;
  final int totalReps;
}

bool _isDueForReview(Sentence sentence) {
  bool ratedForReview(int score) => score >= 1 && score <= 4;
  return ratedForReview(sentence.comprehensionScore) ||
      ratedForReview(sentence.speakingScore);
}
