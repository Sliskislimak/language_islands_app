import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/playback_speed.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

Future<void> showPlaybackSpeedPicker(
  BuildContext context,
  WidgetRef ref, {
  required double currentSpeed,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetContext) {
      return _PlaybackSpeedPickerSheet(
        initialSpeed: currentSpeed,
        onSpeedSelected: (speed) {
          ref.read(practiceSessionProvider.notifier).setPlaybackSpeed(speed);
        },
      );
    },
  );
}

class _PlaybackSpeedPickerSheet extends StatefulWidget {
  const _PlaybackSpeedPickerSheet({
    required this.initialSpeed,
    required this.onSpeedSelected,
  });

  final double initialSpeed;
  final ValueChanged<double> onSpeedSelected;

  @override
  State<_PlaybackSpeedPickerSheet> createState() =>
      _PlaybackSpeedPickerSheetState();
}

class _PlaybackSpeedPickerSheetState extends State<_PlaybackSpeedPickerSheet> {
  late double _speed;

  @override
  void initState() {
    super.initState();
    _speed = PlaybackSpeed.snapToPreset(widget.initialSpeed);
  }

  void _apply(double speed) {
    final snapped = PlaybackSpeed.snapToPreset(speed);
    setState(() => _speed = snapped);
    widget.onSpeedSelected(snapped);
  }

  @override
  Widget build(BuildContext context) {
    final sliderIndex = PlaybackSpeed.presetIndex(_speed).toDouble();
    final maxIndex = (PlaybackSpeed.presets.length - 1).toDouble();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Prędkość odtwarzania',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  PlaybackSpeed.formatLabel(_speed),
                  style: const TextStyle(
                    color: AppTheme.sakuraPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppTheme.sakuraPrimary,
                inactiveTrackColor: AppTheme.surfaceBorder,
                thumbColor: AppTheme.sakuraAccent,
                overlayColor: AppTheme.sakuraMuted.withValues(alpha: 0.2),
                trackHeight: 3,
              ),
              child: Slider(
                value: sliderIndex,
                min: 0,
                max: maxIndex,
                divisions: PlaybackSpeed.presets.length - 1,
                label: PlaybackSpeed.formatLabel(_speed),
                onChanged: (index) {
                  _apply(PlaybackSpeed.presets[index.round()]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    PlaybackSpeed.formatLabel(PlaybackSpeed.min),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    PlaybackSpeed.formatLabel(PlaybackSpeed.max),
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PlaybackSpeed.presets.map((preset) {
                final selected = (_speed - preset).abs() < 0.01;
                return Material(
                  color: selected
                      ? AppTheme.sakuraPrimary
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: () => _apply(preset),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: selected
                              ? AppTheme.sakuraAccent
                              : AppTheme.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        PlaybackSpeed.formatLabel(preset),
                        style: TextStyle(
                          color: selected
                              ? AppTheme.bgDark
                              : AppTheme.textLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
