import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/daily_sentence_entry.dart';
import 'package:language_islands_app/core/models/user_metrics.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/metrics/providers/metrics_controller.dart';

class DailyHistoryState {
  const DailyHistoryState({
    required this.selectedDate,
    required this.metrics,
    required this.sentenceEntries,
    required this.dayRating,
    required this.dayNote,
    required this.totalRepsOnDay,
    required this.totalSecondsOnDay,
    required this.allDatesWithData,
  });

  final DateTime selectedDate;
  final UserMetrics metrics;
  final List<DailySentenceEntry> sentenceEntries;
  final int dayRating; // 0..5 stars
  final String dayNote;
  final int totalRepsOnDay;
  final int totalSecondsOnDay;
  final List<String> allDatesWithData;

  String get selectedDateKey => UserMetrics.dateKey(selectedDate);

  bool get isToday =>
      selectedDateKey == UserMetrics.todayKey();

  double get averageSentenceStars {
    final rated = sentenceEntries.where((e) => e.stars > 0).toList();
    if (rated.isEmpty) return 0.0;
    final sum = rated.fold<int>(0, (prev, e) => prev + e.stars);
    return sum / rated.length;
  }

  int get ratedSentencesCount =>
      sentenceEntries.where((e) => e.stars > 0).length;

  DailyHistoryState copyWith({
    DateTime? selectedDate,
    UserMetrics? metrics,
    List<DailySentenceEntry>? sentenceEntries,
    int? dayRating,
    String? dayNote,
    int? totalRepsOnDay,
    int? totalSecondsOnDay,
    List<String>? allDatesWithData,
  }) {
    return DailyHistoryState(
      selectedDate: selectedDate ?? this.selectedDate,
      metrics: metrics ?? this.metrics,
      sentenceEntries: sentenceEntries ?? this.sentenceEntries,
      dayRating: dayRating ?? this.dayRating,
      dayNote: dayNote ?? this.dayNote,
      totalRepsOnDay: totalRepsOnDay ?? this.totalRepsOnDay,
      totalSecondsOnDay: totalSecondsOnDay ?? this.totalSecondsOnDay,
      allDatesWithData: allDatesWithData ?? this.allDatesWithData,
    );
  }
}

final dailyHistoryControllerProvider =
    AsyncNotifierProvider<DailyHistoryController, DailyHistoryState>(
  DailyHistoryController.new,
);

class DailyHistoryController extends AsyncNotifier<DailyHistoryState> {
  DateTime _currentSelectedDate = DateTime.now();

  @override
  Future<DailyHistoryState> build() async {
    final metricsRepo = ref.watch(userMetricsRepositoryProvider);
    final metrics = await metricsRepo.loadMetrics();
    return _buildStateForDate(_currentSelectedDate, metrics);
  }

  Future<DailyHistoryState> _buildStateForDate(
    DateTime date,
    UserMetrics metrics,
  ) async {
    final dateKey = UserMetrics.dateKey(date);
    var entries = List<DailySentenceEntry>.from(
      metrics.sentenceEntriesOn(dateKey),
    );

    // Fallback: If no explicit daily entries exist for this date, but sentence IDs were practiced,
    // look them up from collections to reconstruct entries.
    if (entries.isEmpty) {
      final practicedIds = metrics.dailyPracticedSentenceIds[dateKey] ?? const [];
      if (practicedIds.isNotEmpty) {
        final collections =
            await ref.watch(collectionsControllerProvider.future);
        final map = <String, DailySentenceEntry>{};
        for (final col in collections) {
          for (final s in col.sentences) {
            if (practicedIds.contains(s.id)) {
              map[s.id] = DailySentenceEntry(
                sentenceId: s.id,
                targetText: s.targetText,
                sourceText: s.sourceText,
                stars: s.speakingScore > 0 ? s.speakingScore : s.comprehensionScore,
                mode: s.speakingScore > 0 ? 'Active Recall' : 'Shadowing',
                reps: s.totalReps,
                timestamp: date,
              );
            }
          }
        }
        entries = map.values.toList();
      }
    }

    // Sort entries by timestamp descending
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final datesWithData = metrics.allRecordedDates;
    final todayKey = UserMetrics.todayKey();
    if (!datesWithData.contains(todayKey)) {
      datesWithData.insert(0, todayKey);
    }

    return DailyHistoryState(
      selectedDate: date,
      metrics: metrics,
      sentenceEntries: entries,
      dayRating: metrics.dayRatingOn(dateKey),
      dayNote: metrics.noteOn(dateKey),
      totalRepsOnDay: metrics.repsOn(dateKey),
      totalSecondsOnDay: metrics.secondsOn(dateKey),
      allDatesWithData: datesWithData,
    );
  }

  Future<void> selectDate(DateTime date) async {
    _currentSelectedDate = DateTime(date.year, date.month, date.day);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final metrics =
          await ref.read(userMetricsRepositoryProvider).loadMetrics();
      return _buildStateForDate(_currentSelectedDate, metrics);
    });
  }

  Future<void> previousDay() async {
    final prev = _currentSelectedDate.subtract(const Duration(days: 1));
    await selectDate(prev);
  }

  Future<void> nextDay() async {
    final next = _currentSelectedDate.add(const Duration(days: 1));
    await selectDate(next);
  }

  Future<void> setDayRating(int stars) async {
    final current = state.value;
    if (current == null) return;

    final dateKey = current.selectedDateKey;
    final targetStars = current.dayRating == stars ? 0 : stars.clamp(0, 5);
    final repo = ref.read(userMetricsRepositoryProvider);
    await repo.saveDayRating(dateKey: dateKey, stars: targetStars);

    final refreshedMetrics = await repo.loadMetrics();
    state = AsyncValue.data(
      await _buildStateForDate(current.selectedDate, refreshedMetrics),
    );
    ref.invalidate(metricsControllerProvider);
  }

  Future<void> saveDailyNote(String note) async {
    final current = state.value;
    if (current == null) return;

    final dateKey = current.selectedDateKey;
    final repo = ref.read(userMetricsRepositoryProvider);
    await repo.saveDailyNote(dateKey: dateKey, note: note.trim());

    final refreshedMetrics = await repo.loadMetrics();
    state = AsyncValue.data(
      await _buildStateForDate(current.selectedDate, refreshedMetrics),
    );
    ref.invalidate(metricsControllerProvider);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final metrics =
          await ref.read(userMetricsRepositoryProvider).loadMetrics();
      return _buildStateForDate(_currentSelectedDate, metrics);
    });
  }
}
