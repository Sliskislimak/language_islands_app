import 'dart:convert';

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
  });

  final int totalListeningSeconds;
  final int totalReps;
  final Map<String, int> dailyRepsHistory;
  final Map<String, int> dailySecondsHistory;
  final Map<String, List<String>> dailyPracticedSentenceIds;
  final Map<String, List<String>> dailyMasteredSpeakingIds;

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

  UserMetrics copyWith({
    int? totalListeningSeconds,
    int? totalReps,
    Map<String, int>? dailyRepsHistory,
    Map<String, int>? dailySecondsHistory,
    Map<String, List<String>>? dailyPracticedSentenceIds,
    Map<String, List<String>>? dailyMasteredSpeakingIds,
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
}
