import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';
import 'package:language_islands_app/features/practice/recall_thinking_duration.dart';

class RecallThinkingDurationButton extends ConsumerWidget {
  const RecallThinkingDurationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = ref.watch(
      practiceSessionProvider.select(
        (s) =>
            s?.recallThinkingDuration ??
            const Duration(milliseconds: 2500),
      ),
    );

    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => ref
            .read(practiceSessionProvider.notifier)
            .cycleRecallThinkingDuration(),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Text(
            RecallThinkingDuration.formatLabel(duration),
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
