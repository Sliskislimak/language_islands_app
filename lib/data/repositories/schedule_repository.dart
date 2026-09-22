import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:language_islands_app/core/models/daily_schedule_slot.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Persists the configurable daily protocol under settings/daily_schedule.json.
class ScheduleRepository {
  ScheduleRepository();

  List<DailyScheduleSlot>? _cache;
  Future<void> _queue = Future.value();

  Future<List<DailyScheduleSlot>> loadSchedule() {
    return _enqueue(() async {
      _cache ??= await _readFromDisk();
      return List.unmodifiable(_cache!);
    });
  }

  Future<void> updateSlotTime(String slotId, String newTimeWindow) {
    return _enqueue(() async {
      final current = _cache ?? await _readFromDisk();
      final index = current.indexWhere((s) => s.id == slotId);
      if (index < 0) {
        throw StateError('Slot "$slotId" not found.');
      }
      final updated = List<DailyScheduleSlot>.from(current);
      updated[index] =
          updated[index].copyWith(timeWindow: newTimeWindow.trim());
      await _persist(updated);
    });
  }

  Future<void> addCustomSlot(DailyScheduleSlot slot) {
    if (slot.isCore) {
      throw ArgumentError('Cannot add a slot marked as core.');
    }
    return _enqueue(() async {
      final current = _cache ?? await _readFromDisk();
      if (current.any((s) => s.id == slot.id)) {
        throw StateError('Slot "${slot.id}" already exists.');
      }
      final updated = [...current, slot];
      await _persist(updated);
    });
  }

  Future<void> removeCustomSlot(String slotId) {
    return _enqueue(() async {
      final current = _cache ?? await _readFromDisk();
      DailyScheduleSlot? slot;
      for (final candidate in current) {
        if (candidate.id == slotId) {
          slot = candidate;
          break;
        }
      }
      if (slot == null) return;
      if (slot.isCore) {
        throw StateError('Core slots cannot be removed.');
      }
      final updated = current.where((s) => s.id != slotId).toList();
      await _persist(updated);
    });
  }

  Future<void> resetToDefaults() {
    return _enqueue(() async {
      await _persist(
        List<DailyScheduleSlot>.from(DailyScheduleSlot.defaultCoreSlots),
      );
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

  Future<List<DailyScheduleSlot>> _readFromDisk() async {
    final file = await _scheduleFile();
    if (!await file.exists()) {
      final defaults =
          List<DailyScheduleSlot>.from(DailyScheduleSlot.defaultCoreSlots);
      await file.parent.create(recursive: true);
      await _atomicWrite(file, _encode(defaults));
      _cache = defaults;
      return defaults;
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return await _writeDefaults(file);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return await _writeDefaults(file);
      }
      final slotsRaw = decoded['slots'];
      if (slotsRaw is! List) {
        return await _writeDefaults(file);
      }
      final slots = slotsRaw
          .whereType<Map<String, dynamic>>()
          .map(DailyScheduleSlot.fromMap)
          .where((s) => s.id.isNotEmpty)
          .toList();
      if (slots.isEmpty) {
        return await _writeDefaults(file);
      }
      final sorted = DailyScheduleSlot.sortedByTime(slots);
      _cache = sorted;
      return sorted;
    } on FormatException {
      return await _writeDefaults(file);
    }
  }

  Future<List<DailyScheduleSlot>> _writeDefaults(File file) async {
    final defaults =
        List<DailyScheduleSlot>.from(DailyScheduleSlot.defaultCoreSlots);
    await _atomicWrite(file, _encode(defaults));
    _cache = defaults;
    return defaults;
  }

  Future<void> _persist(List<DailyScheduleSlot> slots) async {
    final sorted = DailyScheduleSlot.sortedByTime(slots);
    final file = await _scheduleFile();
    await file.parent.create(recursive: true);
    await _atomicWrite(file, _encode(sorted));
    _cache = sorted;
  }

  String _encode(List<DailyScheduleSlot> slots) {
    return const JsonEncoder.withIndent('  ').convert({
      'slots': slots.map((s) => s.toMap()).toList(),
    });
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

  Future<File> _scheduleFile() async {
    final docs = await getApplicationDocumentsDirectory();
    return File(p.join(docs.path, 'settings', 'daily_schedule.json'));
  }
}
