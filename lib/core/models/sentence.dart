class Sentence {
  const Sentence({
    required this.id,
    required this.targetText,
    this.phoneticReading,
    required this.sourceText,
    this.targetAudioPath,
    this.comprehensionScore = 0,
    this.speakingScore = 0,
    this.totalReps = 0,
  });

  final String id;
  final String targetText;
  final String? phoneticReading;
  final String sourceText;
  final String? targetAudioPath;
  final int comprehensionScore;
  final int speakingScore;
  final int totalReps;

  Sentence copyWith({
    String? id,
    String? targetText,
    String? phoneticReading,
    bool clearPhoneticReading = false,
    String? sourceText,
    String? targetAudioPath,
    bool clearTargetAudioPath = false,
    int? comprehensionScore,
    int? speakingScore,
    int? totalReps,
  }) {
    return Sentence(
      id: id ?? this.id,
      targetText: targetText ?? this.targetText,
      phoneticReading:
          clearPhoneticReading ? null : (phoneticReading ?? this.phoneticReading),
      sourceText: sourceText ?? this.sourceText,
      targetAudioPath: clearTargetAudioPath
          ? null
          : (targetAudioPath ?? this.targetAudioPath),
      comprehensionScore: comprehensionScore ?? this.comprehensionScore,
      speakingScore: speakingScore ?? this.speakingScore,
      totalReps: totalReps ?? this.totalReps,
    );
  }

  factory Sentence.fromMap(Map<String, dynamic> map) {
    final id = map['id'];
    final targetText = map['targetText'];
    final sourceText = map['sourceText'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Sentence.id must be a non-empty string.');
    }
    if (targetText is! String || targetText.isEmpty) {
      throw FormatException('Sentence "$id" is missing targetText.');
    }
    if (sourceText is! String) {
      throw FormatException('Sentence "$id" is missing sourceText.');
    }

    return Sentence(
      id: id,
      targetText: targetText,
      phoneticReading: _optionalString(map['phoneticReading']),
      sourceText: sourceText,
      targetAudioPath: _optionalString(map['targetAudioPath']),
      comprehensionScore: _score(map['comprehensionScore']),
      speakingScore: _score(map['speakingScore']),
      totalReps: _nonNegativeInt(map['totalReps']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'targetText': targetText,
      'phoneticReading': phoneticReading,
      'sourceText': sourceText,
      'targetAudioPath': targetAudioPath,
      'comprehensionScore': comprehensionScore,
      'speakingScore': speakingScore,
      'totalReps': totalReps,
    };
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _score(Object? value) {
    final parsed = _nonNegativeInt(value);
    if (parsed > 5) return 5;
    return parsed;
  }

  static int _nonNegativeInt(Object? value) {
    if (value == null) return 0;
    if (value is int) return value < 0 ? 0 : value;
    if (value is num) {
      final asInt = value.toInt();
      return asInt < 0 ? 0 : asInt;
    }
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sentence &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          targetText == other.targetText &&
          phoneticReading == other.phoneticReading &&
          sourceText == other.sourceText &&
          targetAudioPath == other.targetAudioPath &&
          comprehensionScore == other.comprehensionScore &&
          speakingScore == other.speakingScore &&
          totalReps == other.totalReps;

  @override
  int get hashCode => Object.hash(
        id,
        targetText,
        phoneticReading,
        sourceText,
        targetAudioPath,
        comprehensionScore,
        speakingScore,
        totalReps,
      );
}
