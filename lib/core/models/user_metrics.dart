import 'dart:convert';

import 'package:language_islands_app/core/models/daily_sentence_entry.dart';

/// Offline training telemetry persisted on disk.
///
/// Extra daily id maps exist so the Today tab can reconstruct unique
/// practiced / mastered-speaking counts after a restart.
class UserMetrics {
  const UserMetrics({
    this.totalListeningSeconds = 0,
    this.totalReps = 0,
    this.dailyRepsHistory = const {},
    this.dailySecondsHistory = const {},
    this.dailyPracticedSentenceIds = const {},
    this.dailyMasteredSpeakingIds = const {},
    this.dailyDayRatings = const {},
    this.dailyNotes = const {},
    this.dailySentenceEntries = const {},
  });

  final int totalListeningSeconds;
  final int totalReps;
  final Map<String, int> dailyRepsHistory;
  final Map<String, int> dailySecondsHistory;
  final Map<String, List<String>> dailyPracticedSentenceIds;
  final Map<String, List<String>> dailyMasteredSpeakingIds;
  final Map<String, int> dailyDayRatings;
  final Map<String, String> dailyNotes;
  final Map<String, List<DailySentenceEntry>> dailySentenceEntries;

  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String todayKey([DateTime? now]) => dateKey(now ?? DateTime.now());

  int repsOn(String dateKey) => dailyRepsHistory[dateKey] ?? 0;

  int secondsOn(String dateKey) => dailySecondsHistory[dateKey] ?? 0;

  int practicedCountOn(String dateKey) =>
      dailyPracticedSentenceIds[dateKey]?.length ?? 0;

  int masteredSpeakingCountOn(String dateKey) =>
      dailyMasteredSpeakingIds[dateKey]?.length ?? 0;

  int dayRatingOn(String dateKey) => dailyDayRatings[dateKey] ?? 0;

  String noteOn(String dateKey) => dailyNotes[dateKey] ?? '';

  List<DailySentenceEntry> sentenceEntriesOn(String dateKey) =>
      dailySentenceEntries[dateKey] ?? const [];

  /// All unique date keys that have any telemetry, rating, or note recorded,
  /// ordered descending (newest first).
  List<String> get allRecordedDates {
    final dates = <String>{
      ...dailyRepsHistory.keys,
      ...dailySecondsHistory.keys,
      ...dailyPracticedSentenceIds.keys,
      ...dailyMasteredSpeakingIds.keys,
      ...dailyDayRatings.keys,
      ...dailyNotes.keys,
      ...dailySentenceEntries.keys,
    };
    final list = dates.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  UserMetrics copyWith({
    int? totalListeningSeconds,
    int? totalReps,
    Map<String, int>? dailyRepsHistory,
    Map<String, int>? dailySecondsHistory,
    Map<String, List<String>>? dailyPracticedSentenceIds,
    Map<String, List<String>>? dailyMasteredSpeakingIds,
    Map<String, int>? dailyDayRatings,
    Map<String, String>? dailyNotes,
    Map<String, List<DailySentenceEntry>>? dailySentenceEntries,
  }) {
    return UserMetrics(
      totalListeningSeconds:
          totalListeningSeconds ?? this.totalListeningSeconds,
      totalReps: totalReps ?? this.totalReps,
      dailyRepsHistory: dailyRepsHistory ?? this.dailyRepsHistory,
      dailySecondsHistory: dailySecondsHistory ?? this.dailySecondsHistory,
      dailyPracticedSentenceIds:
          dailyPracticedSentenceIds ?? this.dailyPracticedSentenceIds,
      dailyMasteredSpeakingIds:
          dailyMasteredSpeakingIds ?? this.dailyMasteredSpeakingIds,
      dailyDayRatings: dailyDayRatings ?? this.dailyDayRatings,
      dailyNotes: dailyNotes ?? this.dailyNotes,
      dailySentenceEntries: dailySentenceEntries ?? this.dailySentenceEntries,
    );
  }

  factory UserMetrics.fromMap(Map<String, dynamic> map) {
    return UserMetrics(
      totalListeningSeconds: _nonNegativeInt(map['totalListeningSeconds']),
      totalReps: _nonNegativeInt(map['totalReps']),
      dailyRepsHistory: _intMap(map['dailyRepsHistory']),
      dailySecondsHistory: _intMap(map['dailySecondsHistory']),
      dailyPracticedSentenceIds: _idMap(map['dailyPracticedSentenceIds']),
      dailyMasteredSpeakingIds: _idMap(map['dailyMasteredSpeakingIds']),
      dailyDayRatings: _intMap(map['dailyDayRatings']),
      dailyNotes: _stringMap(map['dailyNotes']),
      dailySentenceEntries: _dailySentenceEntriesMap(map['dailySentenceEntries']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalListeningSeconds': totalListeningSeconds,
      'totalReps': totalReps,
      'dailyRepsHistory': dailyRepsHistory,
      'dailySecondsHistory': dailySecondsHistory,
      'dailyPracticedSentenceIds': dailyPracticedSentenceIds,
      'dailyMasteredSpeakingIds': dailyMasteredSpeakingIds,
      'dailyDayRatings': dailyDayRatings,
      'dailyNotes': dailyNotes,
      'dailySentenceEntries': {
        for (final entry in dailySentenceEntries.entries)
          entry.key: entry.value.map((e) => e.toMap()).toList(),
      },
    };
  }

  String toJsonString() => jsonEncode(toMap());

  factory UserMetrics.fromJsonString(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is Map<String, dynamic>) {
      return UserMetrics.fromMap(decoded);
    }
    if (decoded is Map) {
      return UserMetrics.fromMap(Map<String, dynamic>.from(decoded));
    }
    throw const FormatException('Metrics JSON must be an object.');
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

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) return const {};
    final result = <String, int>{};
    value.forEach((key, raw) {
      if (key is! String || key.isEmpty) return;
      result[key] = _nonNegativeInt(raw);
    });
    return result;
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    final result = <String, String>{};
    value.forEach((key, raw) {
      if (key is! String || key.isEmpty) return;
      if (raw is String) {
        result[key] = raw;
      }
    });
    return result;
  }

  static Map<String, List<String>> _idMap(Object? value) {
    if (value is! Map) return const {};
    final result = <String, List<String>>{};
    value.forEach((key, raw) {
      if (key is! String || key.isEmpty) return;
      if (raw is! List) return;
      final ids = <String>[];
      final seen = <String>{};
      for (final item in raw) {
        if (item is! String) continue;
        final id = item.trim();
        if (id.isEmpty || !seen.add(id)) continue;
        ids.add(id);
      }
      result[key] = ids;
    });
    return result;
  }

  static Map<String, List<DailySentenceEntry>> _dailySentenceEntriesMap(
    Object? value,
  ) {
    if (value is! Map) return const {};
    final result = <String, List<DailySentenceEntry>>{};
    value.forEach((key, raw) {
      if (key is! String || key.isEmpty) return;
      if (raw is! List) return;
      final entries = <DailySentenceEntry>[];
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          entries.add(DailySentenceEntry.fromMap(item));
        } else if (item is Map) {
          entries.add(
            DailySentenceEntry.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
      result[key] = entries;
    });
    return result;
  }
}
