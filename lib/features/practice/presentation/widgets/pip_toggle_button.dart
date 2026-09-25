import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

/// Toggles the native floating Picture-in-Picture bar with the current
/// sentence. Hidden entirely on platforms without PiP support.
class PipToggleButton extends ConsumerStatefulWidget {
  const PipToggleButton({super.key});

  @override
  ConsumerState<PipToggleButton> createState() => _PipToggleButtonState();
}

class _PipToggleButtonState extends ConsumerState<PipToggleButton> {
  bool _supported = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final supported = await ref.read(pipServiceProvider).isSupported();
    if (!mounted || supported == _supported) return;
    setState(() => _supported = supported);
  }

  @override
  Widget build(BuildContext context) {
    if (!_supported) return const SizedBox.shrink();

    final active = ref.watch(
      practiceSessionProvider.select((s) => s?.isPipActive ?? false),
    );

    return Tooltip(
      message: active ? 'Zamknij pływający pasek' : 'Pływający pasek',
      child: Material(
        color: active
            ? AppTheme.greenMatcha.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => ref
              .read(practiceSessionProvider.notifier)
              .togglePictureInPicture(),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: active ? AppTheme.greenMatcha : AppTheme.surfaceBorder,
              ),
            ),
            child: Icon(
              Icons.picture_in_picture_alt_rounded,
              size: 22,
              color: active ? AppTheme.greenMatcha : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
