import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/daily_schedule_slot.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';

final dailyScheduleProvider =
    AsyncNotifierProvider<DailyScheduleNotifier, List<DailyScheduleSlot>>(
  DailyScheduleNotifier.new,
);

class DailyScheduleNotifier extends AsyncNotifier<List<DailyScheduleSlot>> {
  @override
  Future<List<DailyScheduleSlot>> build() async {
    final repo = ref.read(scheduleRepositoryProvider);
    return repo.loadSchedule();
  }

  Future<void> updateSlotTime(String slotId, String newTimeWindow) async {
    final trimmed = newTimeWindow.trim();
    if (trimmed.isEmpty) return;

    final repo = ref.read(scheduleRepositoryProvider);
    await repo.updateSlotTime(slotId, trimmed);
    state = AsyncData(await repo.loadSchedule());
  }

  Future<void> addCustomSlot({
    required String title,
    required String timeWindow,
    required String taskType,
  }) async {
    final name = title.trim();
    final window = timeWindow.trim();
    if (name.isEmpty || window.isEmpty) return;
    if (!DailyScheduleSlot.allowedCustomTaskTypes.contains(taskType)) {
      return;
    }

    final current = state.value ?? await _reload();
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final order = current.length;
    final slot = DailyScheduleSlot.customFromForm(
      id: id,
      title: name,
      timeWindow: window,
      taskType: taskType,
      order: order,
    );

    final repo = ref.read(scheduleRepositoryProvider);
    await repo.addCustomSlot(slot);
    state = AsyncData(await repo.loadSchedule());
  }

  Future<void> removeCustomSlot(String slotId) async {
    final repo = ref.read(scheduleRepositoryProvider);
    await repo.removeCustomSlot(slotId);
    state = AsyncData(await repo.loadSchedule());
  }

  Future<void> resetToDefaults() async {
    final repo = ref.read(scheduleRepositoryProvider);
    await repo.resetToDefaults();
    state = AsyncData(await repo.loadSchedule());
  }

  Future<List<DailyScheduleSlot>> _reload() {
    return ref.read(scheduleRepositoryProvider).loadSchedule();
  }
}
