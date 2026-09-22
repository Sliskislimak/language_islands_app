import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_state.dart';

class CollectionSessionMetrics {
  const CollectionSessionMetrics({
    required this.practiced,
    required this.reps,
    required this.mastered,
  });

  final int practiced;
  final int reps;
  final int mastered;
}

CollectionSessionMetrics computeAllTimeMetrics(
  SentenceCollection collection,
  PracticeMode mode,
) {
  final sentences = collection.sentences;
  var reps = 0;
  var practiced = 0;
  var mastered = 0;

  for (final sentence in sentences) {
    reps += sentence.totalReps;
    if (sentence.totalReps >= 1) practiced++;
    if (_scoreForMode(sentence, mode) >= 5) mastered++;
  }

  return CollectionSessionMetrics(
    practiced: practiced,
    reps: reps,
    mastered: mastered,
  );
}

CollectionSessionMetrics computeTodayMetrics(PracticeSessionState session) {
  return CollectionSessionMetrics(
    practiced: session.sessionPracticedSentenceIds.length,
    reps: session.sessionRepsCount,
    mastered: session.sessionMasteredSentenceIds.length,
  );
}

int _scoreForMode(Sentence sentence, PracticeMode mode) {
  return switch (mode) {
    PracticeMode.shadowing => sentence.comprehensionScore,
    PracticeMode.recall => sentence.speakingScore,
  };
}
