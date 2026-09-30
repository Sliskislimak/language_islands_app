class DailySentenceEntry {
  const DailySentenceEntry({
    required this.sentenceId,
    required this.targetText,
    required this.sourceText,
    this.stars = 0,
    this.mode,
    this.reps = 0,
    required this.timestamp,
  });

  final String sentenceId;
  final String targetText;
  final String sourceText;
  final int stars;
  final String? mode;
  final int reps;
  final DateTime timestamp;

  DailySentenceEntry copyWith({
    String? sentenceId,
    String? targetText,
    String? sourceText,
    int? stars,
    String? mode,
    int? reps,
    DateTime? timestamp,
  }) {
    return DailySentenceEntry(
      sentenceId: sentenceId ?? this.sentenceId,
      targetText: targetText ?? this.targetText,
      sourceText: sourceText ?? this.sourceText,
      stars: stars ?? this.stars,
      mode: mode ?? this.mode,
      reps: reps ?? this.reps,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sentenceId': sentenceId,
      'targetText': targetText,
      'sourceText': sourceText,
      'stars': stars,
      if (mode != null) 'mode': mode,
      'reps': reps,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DailySentenceEntry.fromMap(Map<String, dynamic> map) {
    return DailySentenceEntry(
      sentenceId: map['sentenceId'] as String? ?? '',
      targetText: map['targetText'] as String? ?? '',
      sourceText: map['sourceText'] as String? ?? '',
      stars: (map['stars'] as num?)?.toInt() ?? 0,
      mode: map['mode'] as String?,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      timestamp: map['timestamp'] != null
          ? (DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
