import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/models/user_metrics.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/metrics/domain/level_calculator.dart';

final metricsControllerProvider =
    AsyncNotifierProvider<MetricsController, GlobalMetricsState>(
  MetricsController.new,
);

class GlobalMetricsState {
  const GlobalMetricsState({
    required this.totalReps,
    required this.practicedSentencesCount,
    required this.masteredComprehensionCount,
    required this.masteredSpeakingCount,
    required this.activeWordsCount,
    required this.todayReps,
    required this.todaySeconds,
    required this.todayPracticedCount,
    required this.todayMasteredSpeakingCount,
    required this.comprehensionProgress,
    required this.speakingProgress,
  });

  final int totalReps;
  final int practicedSentencesCount;
  final int masteredComprehensionCount;
  final int masteredSpeakingCount;
  final int activeWordsCount;
  final int todayReps;
  final int todaySeconds;
  final int todayPracticedCount;
  final int todayMasteredSpeakingCount;
  final LevelProgress comprehensionProgress;
  final LevelProgress speakingProgress;

  factory GlobalMetricsState.aggregate({
    required List<SentenceCollection> collections,
    required UserMetrics metrics,
  }) {
    var totalReps = 0;
    var practicedSentencesCount = 0;
    var masteredComprehensionCount = 0;
    var masteredSpeakingCount = 0;
    final masteredForWords = <Sentence>[];

    for (final collection in collections) {
      for (final sentence in collection.sentences) {
        totalReps += sentence.totalReps;
        if (sentence.totalReps >= 1) {
          practicedSentencesCount++;
        }
        if (sentence.comprehensionScore >= 5) {
          masteredComprehensionCount++;
        }
        if (sentence.speakingScore >= 5) {
          masteredSpeakingCount++;
        }
        if (sentence.comprehensionScore >= 5 || sentence.speakingScore >= 5) {
          masteredForWords.add(sentence);
        }
      }
    }

    final today = UserMetrics.todayKey();
    return GlobalMetricsState(
      totalReps: totalReps,
      practicedSentencesCount: practicedSentencesCount,
      masteredComprehensionCount: masteredComprehensionCount,
      masteredSpeakingCount: masteredSpeakingCount,
      activeWordsCount: _countActiveWords(masteredForWords),
      todayReps: metrics.repsOn(today),
      todaySeconds: metrics.secondsOn(today),
      todayPracticedCount: metrics.practicedCountOn(today),
      todayMasteredSpeakingCount: metrics.masteredSpeakingCountOn(today),
      comprehensionProgress: LevelCalculator.calculateComprehension(
        masteredComprehensionCount,
      ),
      speakingProgress: LevelCalculator.calculateSpeaking(
        masteredSpeakingCount,
      ),
    );
  }
}

class MetricsController extends AsyncNotifier<GlobalMetricsState> {
  @override
  Future<GlobalMetricsState> build() async {
    final collections = await ref.watch(collectionsControllerProvider.future);
    final metrics =
        await ref.read(userMetricsRepositoryProvider).loadMetrics();
    return GlobalMetricsState.aggregate(
      collections: collections,
      metrics: metrics,
    );
  }
}

final _tokenPattern = RegExp(
  r'[\u4E00-\u9FFF]+|[\u3040-\u309F]+|[\u30A0-\u30FF]+|[A-Za-z0-9]+',
);

int _countActiveWords(Iterable<Sentence> sentences) {
  final tokens = <String>{};
  for (final sentence in sentences) {
    for (final match in _tokenPattern.allMatches(sentence.targetText)) {
      final token = match.group(0);
      if (token == null || token.isEmpty) continue;
      tokens.add(token);
    }
  }
  return tokens.length;
}
