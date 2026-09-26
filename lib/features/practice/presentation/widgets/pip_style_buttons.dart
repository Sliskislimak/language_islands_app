import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

class PipStyleControls extends ConsumerWidget {
  const PipStyleControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supported = ref.watch(pipSupportedProvider).value ?? false;
    if (!supported) return const SizedBox.shrink();

    final session = ref.watch(practiceSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final notifier = ref.read(practiceSessionProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 6),
        _ControlChip(
          label: session.pipWindowSize.label,
          onTap: notifier.cyclePipWindowSize,
        ),
        const SizedBox(width: 6),
        _ControlChip(
          label: session.pipTranslationSize.label,
          onTap: notifier.cyclePipTranslationSize,
        ),
        const SizedBox(width: 6),
        _ControlChip(
          label: session.pipTranslationUnderPhonetics ? 'PL: Prawa' : 'PL: Lewa',
          onTap: notifier.togglePipTranslationAlignment,
        ),
      ],
    );
  }
}

class _ControlChip extends StatelessWidget {
  const _ControlChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
          child: Text(
            label,
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