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
  });

  final String id;
  final String title;
  final String cefrLevel;
  final List<String> tags;
  final bool isCustomIsland;
  final List<Sentence> sentences;

  SentenceCollection copyWith({
    String? id,
    String? title,
    String? cefrLevel,
    List<String>? tags,
    bool? isCustomIsland,
    List<Sentence>? sentences,
  }) {
    return SentenceCollection(
      id: id ?? this.id,
      title: title ?? this.title,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      tags: tags ?? this.tags,
      isCustomIsland: isCustomIsland ?? this.isCustomIsland,
      sentences: sentences ?? this.sentences,
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
    return {
      'id': id,
      'title': title,
      'cefrLevel': cefrLevel,
      'tags': tags,
      'isCustomIsland': isCustomIsland,
      'sentences': [for (final sentence in sentences) sentence.toMap()],
    };
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
}
