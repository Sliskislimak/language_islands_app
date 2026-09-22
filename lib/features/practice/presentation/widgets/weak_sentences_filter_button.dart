import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

class WeakSentencesFilterButton extends ConsumerWidget {
  const WeakSentencesFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(
      practiceSessionProvider.select(
        (s) => s?.filterOnlyWeakSentences ?? false,
      ),
    );

    return Tooltip(
      message: 'Tylko słabe zdania',
      child: Material(
        color: active
            ? AppTheme.yellowPrompt.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => ref
              .read(practiceSessionProvider.notifier)
              .toggleWeakSentencesFilter(),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    active ? AppTheme.yellowPrompt : AppTheme.surfaceBorder,
              ),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 22,
              color: active ? AppTheme.yellowPrompt : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
