import 'package:language_islands_app/core/services/visual_cue_detector.dart';

class Sentence {
  const Sentence({
    required this.id,
    required this.targetText,
    this.katakana,
    this.phoneticReading,
    required this.sourceText,
    this.targetAudioPath,
    this.translationAudioPath,
    this.targetAudioBase64,
    this.translationAudioBase64,
    this.comprehensionScore = 0,
    this.speakingScore = 0,
    this.totalReps = 0,
    this.notes,
    this.emojis = const [],
  });

  final String id;
  final String targetText;
  final String? katakana;
  final String? phoneticReading;
  final String sourceText;
  final String? targetAudioPath;
  final String? translationAudioPath;
  final String? targetAudioBase64;
  final String? translationAudioBase64;
  final int comprehensionScore;
  final int speakingScore;
  final int totalReps;
  final String? notes;
  final List<String> emojis;

  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  bool get hasCustomTargetAudio =>
      (targetAudioBase64 != null && targetAudioBase64!.isNotEmpty) ||
      (targetAudioPath != null && targetAudioPath!.contains('user_recordings'));

  bool get hasCustomTranslationAudio =>
      (translationAudioBase64 != null && translationAudioBase64!.isNotEmpty) ||
      (translationAudioPath != null && translationAudioPath!.contains('user_recordings'));

  bool get hasCustomVoice => hasCustomTargetAudio || hasCustomTranslationAudio;

  /// Returns visual cues. If explicit [emojis] were specified in JSON, uses them.
  /// Otherwise auto-detects based on target/source/phonetic text.
  List<String> get visualEmojis => VisualCueDetector.detectEmojis(
        targetText: targetText,
        sourceText: sourceText,
        phoneticReading: phoneticReading,
        katakana: katakana,
        explicitEmojis: emojis,
      );

  Sentence copyWith({
    String? id,
    String? targetText,
    String? katakana,
    bool clearKatakana = false,
    String? phoneticReading,
    bool clearPhoneticReading = false,
    String? sourceText,
    String? targetAudioPath,
    bool clearTargetAudioPath = false,
    String? translationAudioPath,
    bool clearTranslationAudioPath = false,
    String? targetAudioBase64,
    bool clearTargetAudioBase64 = false,
    String? translationAudioBase64,
    bool clearTranslationAudioBase64 = false,
    int? comprehensionScore,
    int? speakingScore,
    int? totalReps,
    String? notes,
    bool clearNotes = false,
    List<String>? emojis,
    bool clearEmojis = false,
  }) {
    return Sentence(
      id: id ?? this.id,
      targetText: targetText ?? this.targetText,
      katakana: clearKatakana ? null : (katakana ?? this.katakana),
      phoneticReading: clearPhoneticReading
          ? null
          : (phoneticReading ?? this.phoneticReading),
      sourceText: sourceText ?? this.sourceText,
      targetAudioPath: clearTargetAudioPath
          ? null
          : (targetAudioPath ?? this.targetAudioPath),
      translationAudioPath: clearTranslationAudioPath
          ? null
          : (translationAudioPath ?? this.translationAudioPath),
      targetAudioBase64: clearTargetAudioBase64
          ? null
          : (targetAudioBase64 ?? this.targetAudioBase64),
      translationAudioBase64: clearTranslationAudioBase64
          ? null
          : (translationAudioBase64 ?? this.translationAudioBase64),
      comprehensionScore: comprehensionScore ?? this.comprehensionScore,
      speakingScore: speakingScore ?? this.speakingScore,
      totalReps: totalReps ?? this.totalReps,
      notes: clearNotes ? null : (notes ?? this.notes),
      emojis: clearEmojis ? const [] : (emojis ?? this.emojis),
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
      katakana: _optionalString(map['katakana']),
      phoneticReading: _optionalString(map['phoneticReading']),
      sourceText: sourceText,
      targetAudioPath: _optionalString(map['targetAudioPath']),
      translationAudioPath: _optionalString(
        map['translationAudioPath'] ??
            map['translationAudio'] ??
            map['sourceAudioPath'] ??
            map['sourceAudio'],
      ),
      targetAudioBase64: _optionalString(
        map['targetAudioBase64'] ?? map['target_audio_base64'],
      ),
      translationAudioBase64: _optionalString(
        map['translationAudioBase64'] ??
            map['translation_audio_base64'] ??
            map['sourceAudioBase64'] ??
            map['source_audio_base64'],
      ),
      comprehensionScore: _score(map['comprehensionScore']),
      speakingScore: _score(map['speakingScore']),
      totalReps: _nonNegativeInt(map['totalReps']),
      notes: _optionalString(
        map['notes'] ??
            map['backNotes'] ??
            map['grammarNotes'] ??
            map['theory'] ??
            map['grammar'],
      ),
      emojis: _parseEmojis(
        map['emojis'] ?? map['emoji'] ?? map['visualCues'] ?? map['icons'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'targetText': targetText,
      'katakana': katakana,
      'phoneticReading': phoneticReading,
      'sourceText': sourceText,
      'targetAudioPath': targetAudioPath,
      'translationAudioPath': translationAudioPath,
      'comprehensionScore': comprehensionScore,
      'speakingScore': speakingScore,
      'totalReps': totalReps,
    };
    if (targetAudioBase64 != null && targetAudioBase64!.isNotEmpty) {
      map['targetAudioBase64'] = targetAudioBase64;
    }
    if (translationAudioBase64 != null &&
        translationAudioBase64!.isNotEmpty) {
      map['translationAudioBase64'] = translationAudioBase64;
    }
    if (notes != null && notes!.trim().isNotEmpty) {
      map['notes'] = notes!.trim();
    }
    if (emojis.isNotEmpty) {
      map['emojis'] = emojis;
    }
    return map;
  }

  static String? _optionalString(Object? value) {
    if (value == null) return null;
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _parseEmojis(Object? value) {
    if (value == null) return const [];
    if (value is List) {
      return value
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      if (trimmed.contains(',')) {
        return trimmed
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [trimmed];
    }
    return const [];
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
          katakana == other.katakana &&
          phoneticReading == other.phoneticReading &&
          sourceText == other.sourceText &&
          targetAudioPath == other.targetAudioPath &&
          translationAudioPath == other.translationAudioPath &&
          targetAudioBase64 == other.targetAudioBase64 &&
          translationAudioBase64 == other.translationAudioBase64 &&
          comprehensionScore == other.comprehensionScore &&
          speakingScore == other.speakingScore &&
          totalReps == other.totalReps &&
          notes == other.notes &&
          _listEquals(emojis, other.emojis);

  @override
  int get hashCode => Object.hash(
        id,
        targetText,
        katakana,
        phoneticReading,
        sourceText,
        targetAudioPath,
        translationAudioPath,
        targetAudioBase64,
        translationAudioBase64,
        comprehensionScore,
        speakingScore,
        totalReps,
        notes,
        Object.hashAll(emojis),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
