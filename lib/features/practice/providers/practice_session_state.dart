import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';

class PracticeSessionState {
  const PracticeSessionState({
    required this.collection,
    required this.mode,
    this.activeSentenceId,
    this.revealedSentenceIds = const {},
    this.audioError,
    this.isPlayingContinuous = false,
    this.repsPerSentence = 1,
    this.currentRep = 0,
    this.pauseBetweenReps = const Duration(milliseconds: 1500),
    this.playbackSpeed = 1.0,
    this.isSingleSentenceLoop = false,
    this.sessionPracticedSentenceIds = const {},
    this.sessionRepsCount = 0,
    this.sessionMasteredSentenceIds = const {},
    this.recallThinkingDuration = const Duration(milliseconds: 2500),
    this.filterOnlyWeakSentences = false,
    this.isPipActive = false,
  });

  final SentenceCollection collection;
  final PracticeMode mode;
  final String? activeSentenceId;
  final Set<String> revealedSentenceIds;
  final String? audioError;

  final bool isPlayingContinuous;
  final int repsPerSentence;
  final int currentRep;
  final Duration pauseBetweenReps;
  final double playbackSpeed;
  final bool isSingleSentenceLoop;

  /// Sentences touched during this session (reps or ratings) — used for Today metrics.
  final Set<String> sessionPracticedSentenceIds;
  final int sessionRepsCount;

  /// Sentence ids rated 5★ in the active mode during this session.
  final Set<String> sessionMasteredSentenceIds;

  /// Time to formulate a spoken answer before the Japanese sentence is revealed.
  final Duration recallThinkingDuration;

  /// When true, only sentences rated below 4★ in the active mode are shown.
  final bool filterOnlyWeakSentences;

  /// When true, the native floating Picture-in-Picture bar is open (iOS only).
  final bool isPipActive;

  int scoreForActiveMode(Sentence sentence) {
    return switch (mode) {
      PracticeMode.shadowing => sentence.comprehensionScore,
      PracticeMode.recall => sentence.speakingScore,
    };
  }

  /// Sentences already rated in the active mode, but not yet mastered (5★).
  int get dueCount {
    return collection.sentences.where((sentence) {
      final score = scoreForActiveMode(sentence);
      return score > 0 && score < 5;
    }).length;
  }

  int get newCount {
    return collection.sentences.where((sentence) => sentence.totalReps == 0).length;
  }

  List<Sentence> get visibleSentences {
    if (!filterOnlyWeakSentences) return collection.sentences;
    return collection.sentences
        .where((sentence) => scoreForActiveMode(sentence) < 4)
        .toList();
  }

  PracticeSessionState copyWith({
    SentenceCollection? collection,
    PracticeMode? mode,
    String? activeSentenceId,
    bool clearActiveSentenceId = false,
    Set<String>? revealedSentenceIds,
    String? audioError,
    bool clearAudioError = false,
    bool? isPlayingContinuous,
    int? repsPerSentence,
    int? currentRep,
    Duration? pauseBetweenReps,
    double? playbackSpeed,
    bool? isSingleSentenceLoop,
    Set<String>? sessionPracticedSentenceIds,
    int? sessionRepsCount,
    Set<String>? sessionMasteredSentenceIds,
    Duration? recallThinkingDuration,
    bool? filterOnlyWeakSentences,
    bool? isPipActive,
  }) {
    return PracticeSessionState(
      collection: collection ?? this.collection,
      mode: mode ?? this.mode,
      activeSentenceId: clearActiveSentenceId
          ? null
          : (activeSentenceId ?? this.activeSentenceId),
      revealedSentenceIds: revealedSentenceIds ?? this.revealedSentenceIds,
      audioError:
          clearAudioError ? null : (audioError ?? this.audioError),
      isPlayingContinuous: isPlayingContinuous ?? this.isPlayingContinuous,
      repsPerSentence: repsPerSentence ?? this.repsPerSentence,
      currentRep: currentRep ?? this.currentRep,
      pauseBetweenReps: pauseBetweenReps ?? this.pauseBetweenReps,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isSingleSentenceLoop:
          isSingleSentenceLoop ?? this.isSingleSentenceLoop,
      sessionPracticedSentenceIds:
          sessionPracticedSentenceIds ?? this.sessionPracticedSentenceIds,
      sessionRepsCount: sessionRepsCount ?? this.sessionRepsCount,
      sessionMasteredSentenceIds:
          sessionMasteredSentenceIds ?? this.sessionMasteredSentenceIds,
      recallThinkingDuration:
          recallThinkingDuration ?? this.recallThinkingDuration,
      filterOnlyWeakSentences:
          filterOnlyWeakSentences ?? this.filterOnlyWeakSentences,
      isPipActive: isPipActive ?? this.isPipActive,
    );
  }
}
