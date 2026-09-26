import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/features/practice/pip_style.dart';

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
    this.pipWindowSize = PipWindowSize.medium,
    this.pipFontSize = PipFontSize.standard,
    this.pipTranslationSize = PipTranslationSize.small,
    this.pipTranslationUnderPhonetics = true,
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

  final Set<String> sessionPracticedSentenceIds;
  final int sessionRepsCount;
  final Set<String> sessionMasteredSentenceIds;

  final Duration recallThinkingDuration;
  final bool filterOnlyWeakSentences;

  final bool isPipActive;
  final PipWindowSize pipWindowSize;
  final PipFontSize pipFontSize;
  final PipTranslationSize pipTranslationSize;
  final bool pipTranslationUnderPhonetics;

  int scoreForActiveMode(Sentence sentence) {
    return switch (mode) {
      PracticeMode.shadowing => sentence.comprehensionScore,
      PracticeMode.recall => sentence.speakingScore,
    };
  }

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
    PipWindowSize? pipWindowSize,
    PipFontSize? pipFontSize,
    PipTranslationSize? pipTranslationSize,
    bool? pipTranslationUnderPhonetics,
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
      pipWindowSize: pipWindowSize ?? this.pipWindowSize,
      pipFontSize: pipFontSize ?? this.pipFontSize,
      pipTranslationSize: pipTranslationSize ?? this.pipTranslationSize,
      pipTranslationUnderPhonetics:
          pipTranslationUnderPhonetics ?? this.pipTranslationUnderPhonetics,
    );
  }
}