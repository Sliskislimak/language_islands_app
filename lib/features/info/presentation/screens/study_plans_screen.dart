import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/daily_schedule_slot.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/info/providers/schedule_notifier.dart';

class StudyPlansScreen extends ConsumerWidget {
  const StudyPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(dailyScheduleProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text(
          'Plany nauki',
          style: TextStyle(color: AppTheme.textLight, fontSize: 18),
        ),
      ),
      body: scheduleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.sakuraPrimary),
        ),
        error: (error, _) => _ErrorPanel(message: error.toString()),
        data: (slots) => _StudyPlanBody(slots: slots),
      ),
    );
  }
}

class _StudyPlanBody extends ConsumerWidget {
  const _StudyPlanBody({required this.slots});

  final List<DailyScheduleSlot> slots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        const _PlanTitleHeader(
          title: '90 Dni do Płynności',
          subtitle:
              'Stały szkielet metody. Harmonogram usuwa decyzje — godziny i przerwy dopasowujesz do życia.',
        ),
        const SizedBox(height: 16),
        const _NinetyDayAssumptionsSection(),
        const SizedBox(height: 24),
        const _SectionLabel('Twój Codzienny Protokół (Zero Myślenia)'),
        const SizedBox(height: 10),
        ...slots.map(
          (slot) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ScheduleSlotCard(slot: slot),
          ),
        ),
        const SizedBox(height: 4),
        _OutlinedActionButton(
          label: '+ Dodaj dodatkową przerwę w ciągu dnia',
          onPressed: () => _showAddCustomSlotDialog(context, ref),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => _confirmResetDefaults(context, ref),
          child: const Text(
            'Przywróć domyślne godziny',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmResetDefaults(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text(
          'Przywrócić domyślne godziny?',
          style: TextStyle(color: AppTheme.textLight, fontSize: 16),
        ),
        content: const Text(
          'Przywrócone zostaną domyślne godziny czterech filarów. '
          'Własne przerwy zostaną usunięte.',
          style: TextStyle(color: AppTheme.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Przywróć',
              style: TextStyle(color: AppTheme.sakuraPrimary),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(dailyScheduleProvider.notifier).resetToDefaults();
  }

  Future<void> _showAddCustomSlotDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final titleController = TextEditingController();
    TimeOfDay start = const TimeOfDay(hour: 15, minute: 30);
    TimeOfDay end = const TimeOfDay(hour: 15, minute: 45);
    var taskType = DailyScheduleSlot.customTypeShortShadowing;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceElevated,
              title: const Text(
                'Dodatkowa przerwa',
                style: TextStyle(color: AppTheme.textLight, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: AppTheme.textLight),
                      decoration: const InputDecoration(
                        labelText: 'Nazwa',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        hintText: 'Druga kawa w pracy',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeChip(
                            label: 'Od',
                            time: start,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: start,
                                builder: _timePickerTheme,
                              );
                              if (picked != null) {
                                setState(() => start = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TimeChip(
                            label: 'Do',
                            time: end,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: end,
                                builder: _timePickerTheme,
                              );
                              if (picked != null) {
                                setState(() => end = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(taskType),
                      initialValue: taskType,
                      dropdownColor: AppTheme.surface,
                      decoration: const InputDecoration(
                        labelText: 'Typ zadania',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                      ),
                      items: DailyScheduleSlot.allowedCustomTaskTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(
                                  color: AppTheme.textLight,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => taskType = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                TextButton(
                  onPressed: () async {
                    final window =
                        '${_formatTime(start)} - ${_formatTime(end)}';
                    await ref.read(dailyScheduleProvider.notifier).addCustomSlot(
                          title: titleController.text,
                          timeWindow: window,
                          taskType: taskType,
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text(
                    'Dodaj',
                    style: TextStyle(color: AppTheme.sakuraPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
  }
}

class _NinetyDayAssumptionsSection extends StatelessWidget {
  const _NinetyDayAssumptionsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ZAŁOŻENIA PLANU 90 DNI',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          SizedBox(height: 12),
          _AssumptionRow(
            month: 'Miesiąc 1',
            body:
                'Fundamenty (1000 zdań bazy + 1000 zdań z Wysp Językowych).',
          ),
          SizedBox(height: 10),
          _AssumptionRow(
            month: 'Miesiąc 2',
            body: 'Mówienie do telefonu i korekta z AI.',
          ),
          SizedBox(height: 10),
          _AssumptionRow(
            month: 'Miesiąc 3',
            body: 'Złożone zdania i płynność.',
          ),
        ],
      ),
    );
  }
}

class _AssumptionRow extends StatelessWidget {
  const _AssumptionRow({
    required this.month,
    required this.body,
  });

  final String month;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            month,
            style: const TextStyle(
              color: AppTheme.sakuraMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            body,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleSlotCard extends ConsumerWidget {
  const _ScheduleSlotCard({required this.slot});

  final DailyScheduleSlot slot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecall = slot.modeLabel.toLowerCase().contains('recall') ||
        slot.presetConfig.toLowerCase().startsWith('recall');
    final modeColor = isRecall ? AppTheme.yellowPrompt : AppTheme.sakuraPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  slot.timeWindow,
                  style: const TextStyle(
                    color: AppTheme.sakuraPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edytuj godziny',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => _editTimeWindow(context, ref),
                icon: const Icon(
                  Icons.schedule_outlined,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ),
              if (!slot.isCore)
                IconButton(
                  tooltip: 'Usuń przerwę',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () {
                    ref
                        .read(dailyScheduleProvider.notifier)
                        .removeCustomSlot(slot.id);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            slot.title,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Text(
              slot.modeLabel,
              style: TextStyle(
                color: modeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slot.actionSummary,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slot.presetConfig,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTimeWindow(BuildContext context, WidgetRef ref) async {
    final parsed = _parseTimeWindow(slot.timeWindow);
    var start = parsed.$1;
    var end = parsed.$2;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceElevated,
              title: Text(
                'Godziny: ${slot.title}',
                style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
              ),
              content: Row(
                children: [
                  Expanded(
                    child: _TimeChip(
                      label: 'Od',
                      time: start,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: start,
                          builder: _timePickerTheme,
                        );
                        if (picked != null) {
                          setState(() => start = picked);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TimeChip(
                      label: 'Do',
                      time: end,
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: end,
                          builder: _timePickerTheme,
                        );
                        if (picked != null) {
                          setState(() => end = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Anuluj'),
                ),
                TextButton(
                  onPressed: () async {
                    final window =
                        '${_formatTime(start)} - ${_formatTime(end)}';
                    await ref
                        .read(dailyScheduleProvider.notifier)
                        .updateSlotTime(slot.id, window);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text(
                    'Zapisz',
                    style: TextStyle(color: AppTheme.sakuraPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textLight,
        side: const BorderSide(color: AppTheme.surfaceBorder),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(time),
            style: const TextStyle(
              color: AppTheme.sakuraPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textLight,
        side: const BorderSide(color: AppTheme.surfaceBorder),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PlanTitleHeader extends StatelessWidget {
  const _PlanTitleHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Błąd wczytywania harmonogramu',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

(TimeOfDay, TimeOfDay) _parseTimeWindow(String timeWindow) {
  final parts = timeWindow.split('-');
  if (parts.length >= 2) {
    return (_parseClock(parts[0]), _parseClock(parts[1]));
  }
  return (
    const TimeOfDay(hour: 7, minute: 0),
    const TimeOfDay(hour: 7, minute: 30),
  );
}

TimeOfDay _parseClock(String raw) {
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(raw.trim());
  if (match == null) return const TimeOfDay(hour: 0, minute: 0);
  final hour = int.tryParse(match.group(1) ?? '') ?? 0;
  final minute = int.tryParse(match.group(2) ?? '') ?? 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Widget _timePickerTheme(BuildContext context, Widget? child) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppTheme.sakuraPrimary,
        onPrimary: AppTheme.bgDark,
        surface: AppTheme.surfaceElevated,
        onSurface: AppTheme.textLight,
      ),
    ),
    child: child ?? const SizedBox.shrink(),
  );
}
