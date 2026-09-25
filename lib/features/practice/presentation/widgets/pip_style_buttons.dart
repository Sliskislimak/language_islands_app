import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

/// Font size, Polish translation size and alignment chips for the PiP bar.
///
/// Hidden unless PiP is supported and currently open — changing style only
/// matters when the floating window is on screen.
class PipStyleControls extends ConsumerWidget {
  const PipStyleControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supported = ref.watch(pipSupportedProvider).value ?? false;
    final session = ref.watch(practiceSessionProvider);
    if (!supported || session == null || !session.isPipActive) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(practiceSessionProvider.notifier);
    final underPhonetics = session.pipTranslationUnderPhonetics;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 6),
        _PipStyleChip(
          tooltip: 'Wielkość liter w pasku',
          onTap: notifier.cyclePipFontSize,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.format_size_rounded,
                size: 16,
                color: AppTheme.textLight,
              ),
              const SizedBox(width: 4),
              Text(session.pipFontSize.label, style: _labelStyle),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _PipStyleChip(
          tooltip: 'Wielkość polskiego tłumaczenia',
          onTap: notifier.cyclePipTranslationSize,
          child: Text(
            session.pipTranslationSize.chipLabel,
            style: _labelStyle,
          ),
        ),
        const SizedBox(width: 6),
        _PipStyleChip(
          tooltip: underPhonetics
              ? 'Tłumaczenie pod fonetyką (prawa)'
              : 'Tłumaczenie pod tekstem docelowym (lewa)',
          onTap: notifier.togglePipTranslationAlignment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                underPhonetics
                    ? Icons.format_align_right_rounded
                    : Icons.format_align_left_rounded,
                size: 16,
                color: AppTheme.textLight,
              ),
              const SizedBox(width: 4),
              Text(
                underPhonetics ? 'PL: Prawa' : 'PL: Lewa',
                style: _labelStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const TextStyle _labelStyle = TextStyle(
  color: AppTheme.textLight,
  fontSize: 13,
  fontWeight: FontWeight.w600,
);

class _PipStyleChip extends StatelessWidget {
  const _PipStyleChip({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
