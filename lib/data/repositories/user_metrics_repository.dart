import 'dart:async';
import 'dart:io';

import 'package:language_islands_app/core/models/daily_sentence_entry.dart';
import 'package:language_islands_app/core/models/user_metrics.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local JSON persistence for [UserMetrics].
///
/// Writes go through a temp file + backup rename so a crash cannot leave
/// a half-written `user_metrics.json`.
class UserMetricsRepository {
  UserMetricsRepository({this.metricsFileOverride});

  final File? metricsFileOverride;
  UserMetrics? _cache;
  Future<void> _queue = Future.value();

  Future<UserMetrics> loadMetrics() {
    return _enqueue(() async {
      _cache ??= await _readFromDisk();
      return _cache!;
    });
  }

  Future<void> logRepetition({
    required int count,
    String? sentenceId,
    String? targetText,
    String? sourceText,
    String? mode,
    DateTime? now,
  }) {
    if (count <= 0) return Future.value();
    return _enqueue(() async {
      final current = _cache ?? await _readFromDisk();
      final effectiveDate = now ?? DateTime.now();
      final today = UserMetrics.dateKey(effectiveDate);

      final nextReps = Map<String, int>.from(current.dailyRepsHistory);
      nextReps[today] = (nextReps[today] ?? 0) + count;

      final nextPracticed =
          _copyIdMap(current.dailyPracticedSentenceIds);
      final id = sentenceId?.trim();
      if (id != null && id.isNotEmpty) {
        _addId(nextPracticed, today, id);
      }

      final nextSentenceEntries =
          _copySentenceEntriesMap(current.dailySentenceEntries);
      if (id != null && id.isNotEmpty && (targetText != null || sourceText != null)) {
        final entries = List<DailySentenceEntry>.from(
          nextSentenceEntries[today] ?? const [],
        );
        final matchIndex = entries.indexWhere(
          (e) => e.sentenceId == id && (mode == null || e.mode == mode),
        );
        if (matchIndex >= 0) {
          final existing = entries[matchIndex];
          entries[matchIndex] = existing.copyWith(
            reps: existing.reps + count,
            targetText: targetText ?? existing.targetText,
            sourceText: sourceText ?? existing.sourceText,
            mode: mode ?? existing.mode,
            timestamp: effectiveDate,
          );
        } else {
          entries.add(
            DailySentenceEntry(
              sentenceId: id,
              targetText: targetText ?? '',
              sourceText: sourceText ?? '',
              stars: 0,
              mode: mode,
              reps: count,
              timestamp: effectiveDate,
            ),
          );
        }
        nextSentenceEntries[today] = entries;
      }

      final updated = current.copyWith(
        totalReps: current.totalReps + count,
        dailyRepsHistory: nextReps,
        dailyPracticedSentenceIds: nextPracticed,
        dailySentenceEntries: nextSentenceEntries,
      );
      await _writeToDisk(updated);
      _cache = updated;
    });
  }

  Future<void> logSentenceRating({
    required String sentenceId,
    required String targetText,
    required String sourceText,
    required int stars,
    String? mode,
    DateTime? now,
  }) {
    final id = sentenceId.trim();
    if (id.isEmpty) return Future.value();
    final clamped = stars.clamp(0, 5);
    return _enqueue(() async {
      final current = _cache ?? await _readFromDisk();
      final effectiveDate = now ?? DateTime.now();
      final today = UserMetrics.dateKey(effectiveDate);

      final nextPracticed =
          _copyIdMap(current.dailyPracticedSentenceIds);
      _addId(nextPracticed, today, id);

      final nextSentenceEntries =
          _copySentenceEntriesMap(current.dailySentenceEntries);
      final entries = List<DailySentenceEntry>.from(
        nextSentenceEntries[today] ?? const [],
      );

      final matchIndex = entries.indexWhere(
        (e) => e.sentenceId == id && (mode == null || e.mode == mode),
      );
      if (matchIndex >= 0) {
        final existing = entries[matchIndex];
        entries[matchIndex] = existing.copyWith(
          targetText: targetText.isNotEmpty ? targetText : existing.targetText,
          sourceText: sourceText.isNotEmpty ? sourceText : existing.sourceText,
          stars: clamped,
          mode: mode ?? existing.mode,
          timestamp: effectiveDate,
        );
      } else {
        entries.add(
          DailySentenceEntry(
            sentenceId: id,
            targetText: targetText,
            sourceText: sourceText,
            stars: clamped,
            mode: mode,
            reps: 0,
            timestamp: effectiveDate,
          ),
        );
      }
      nextSentenceEntries[today] = entries;

      final updated = current.copyWith(
        dailyPracticedSentenceIds: nextPracticed,
        dailySentenceEntries: nextSentenceEntries,
      );
      await _writeToDisk(updated);
      _cache = updated;
    });
  }

  Future<void> saveDayRating({
    required String dateKey,
    required int stars,
  }) {
    return _enqueue(() async {
      final current = _cache ?? await _readFromDisk();
      final nextRatings = Map<String, int>.from(current.dailyDayRatings);
      nextRatings[dateKey] = stars.clamp(0, 5);

      final updated = current.copyWith(dailyDayRatings: nextRatings);
      await _writeToDisk(updated);
      _cache = updated;
    });
  }

  Future<void> saveDailyNote({
    required String dateKey,
    required String note,
  }) {
    return _enqueue(() async {
      final current = _cache ?? await _readFromDisk();
      final nextNotes = Map<String, String>.from(current.dailyNotes);
      nextNotes[dateKey] = note;

      final updated = current.copyWith(dailyNotes: nextNotes);
      await _writeToDisk(updated);
      _cache = updated;
    });
  }

  Future<void> logListeningTime({required int seconds}) {
    if (seconds <= 0) return Future.value();
    return _enqueue(() async {
      final current = _cache ?? await _readFromDisk();
      final today = UserMetrics.todayKey();

      final nextSeconds = Map<String, int>.from(current.dailySecondsHistory);
      nextSeconds[today] = (nextSeconds[today] ?? 0) + seconds;

      final updated = current.copyWith(
        totalListeningSeconds: current.totalListeningSeconds + seconds,
        dailySecondsHistory: nextSeconds,
      );
      await _writeToDisk(updated);
      _cache = updated;
    });
  }

  /// Records a Recall self-rating for the Today MASTERED tile.
  Future<void> logSpeakingRating({
    required String sentenceId,
    required int stars,
  }) {
    final id = sentenceId.trim();
    if (id.isEmpty) return Future.value();
    return _enqueue(() async {
      final current = _cache ?? await _readFromDisk();
      final today = UserMetrics.todayKey();
      final nextMastered = _copyIdMap(current.dailyMasteredSpeakingIds);
      if (stars >= 5) {
        _addId(nextMastered, today, id);
      } else {
        _removeId(nextMastered, today, id);
      }
      final updated = current.copyWith(
        dailyMasteredSpeakingIds: nextMastered,
      );
      await _writeToDisk(updated);
      _cache = updated;
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<UserMetrics> _readFromDisk() async {
    final file = await _metricsFile();
    final raw = await _readWithBackup(file);
    if (raw == null || raw.trim().isEmpty) {
      return const UserMetrics();
    }
    try {
      return UserMetrics.fromJsonString(raw);
    } on FormatException {
      return const UserMetrics();
    }
  }

  Future<void> _writeToDisk(UserMetrics metrics) async {
    final file = await _metricsFile();
    await file.parent.create(recursive: true);
    await _atomicWrite(file, metrics.toJsonString());
  }

  Future<String?> _readWithBackup(File file) async {
    if (await file.exists()) {
      try {
        return await file.readAsString();
      } on FileSystemException {
        // Fall through to the backup copy.
      }
    }
    final backup = File('${file.path}.bak');
    if (await backup.exists()) {
      try {
        return await backup.readAsString();
      } on FileSystemException {
        return null;
      }
    }
    return null;
  }

  Future<void> _atomicWrite(File target, String contents) async {
    final tmp = File('${target.path}.tmp');
    final backup = File('${target.path}.bak');

    await tmp.writeAsString(contents, flush: true);

    if (await target.exists()) {
      if (await backup.exists()) {
        await backup.delete();
      }
      await target.rename(backup.path);
    }

    await tmp.rename(target.path);

    if (await backup.exists()) {
      await backup.delete();
    }
  }

  Future<File> _metricsFile() async {
    if (metricsFileOverride != null) return metricsFileOverride!;
    final docs = await getApplicationDocumentsDirectory();
    return File(p.join(docs.path, 'metrics', 'user_metrics.json'));
  }

  static Map<String, List<String>> _copyIdMap(
    Map<String, List<String>> source,
  ) {
    return {
      for (final entry in source.entries)
        entry.key: List<String>.from(entry.value),
    };
  }

  static Map<String, List<DailySentenceEntry>> _copySentenceEntriesMap(
    Map<String, List<DailySentenceEntry>> source,
  ) {
    return {
      for (final entry in source.entries)
        entry.key: List<DailySentenceEntry>.from(entry.value),
    };
  }

  static void _addId(
    Map<String, List<String>> map,
    String dateKey,
    String id,
  ) {
    final ids = List<String>.from(map[dateKey] ?? const []);
    if (!ids.contains(id)) {
      ids.add(id);
    }
    map[dateKey] = ids;
  }

  static void _removeId(
    Map<String, List<String>> map,
    String dateKey,
    String id,
  ) {
    final ids = List<String>.from(map[dateKey] ?? const []);
    ids.remove(id);
    map[dateKey] = ids;
  }
}
