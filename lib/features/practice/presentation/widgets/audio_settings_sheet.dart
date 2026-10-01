import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/audio_translation_mode.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/presentation/language_management_dialog.dart';
import 'package:language_islands_app/features/collections/providers/language_settings_controller.dart';
import 'package:language_islands_app/features/practice/playback_speed.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_state.dart';

Future<void> showAudioSettingsSheet(
  BuildContext context,
  WidgetRef ref,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _AudioSettingsSheetContent(),
  );
}

class _AudioSettingsSheetContent extends ConsumerWidget {
  const _AudioSettingsSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(practiceSessionProvider);
    if (session == null) return const SizedBox();
    final notifier = ref.read(practiceSessionProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
          left: BorderSide(color: AppTheme.surfaceBorder),
          right: BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.translate_rounded,
                  color: AppTheme.sakuraPrimary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Lektor Tłumaczenia & Audio',
                    style: TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Zamknij',
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable Settings Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // 1. Język lektora tłumaczenia
                _SectionTitle(
                  title: 'JĘZYK LEKTORA TŁUMACZENIA',
                  subtitle:
                      'Wybierz język, w jakim lektor czyta tłumaczenie (z odblokowanych globalnie).',
                  icon: Icons.language_rounded,
                  iconColor: AppTheme.sakuraPrimary,
                ),
                const SizedBox(height: 10),
                _TranslationLanguageSelector(
                  currentLanguageCode: session.translationLanguage,
                  onChanged: notifier.setTranslationLanguage,
                  onManageLanguages: () => showLanguageManagementDialog(context),
                ),

                const SizedBox(height: 22),

                // 2. Tryb lektora tłumaczenia
                _SectionTitle(
                  title: 'TRYB LEKTORA TŁUMACZENIA',
                  subtitle:
                      'Wzmacnia kotwicę semantyczną (rozumienie) przed powtórzeniami docelowymi.',
                  icon: Icons.record_voice_over_rounded,
                  iconColor: AppTheme.sakuraPrimary,
                ),
                const SizedBox(height: 10),
                _TranslationModeSelector(
                  currentMode: session.audioTranslationMode,
                  onChanged: notifier.setAudioTranslationMode,
                ),
                const SizedBox(height: 8),
                _ModeExplanationBox(mode: session.audioTranslationMode),

                const SizedBox(height: 22),

                // 3. Liczba powtórzeń zdania (targetReps)
                _SectionTitle(
                  title: 'POWTÓRZENIA ZDANIA DOCELOWEGO (1 – 5)',
                  subtitle:
                      'Ile razy odsłuchać i powtórzyć zdanie w języku docelowym w danej pętli.',
                  icon: Icons.repeat_rounded,
                  iconColor: AppTheme.greenMatcha,
                ),
                const SizedBox(height: 10),
                _TargetRepsSelector(
                  currentReps: session.targetReps,
                  onChanged: notifier.setTargetReps,
                ),

                const SizedBox(height: 22),

                // 4. Pauza między językami (Audio Recall Buffer)
                _SectionTitle(
                  title: 'PAUZA MIĘDZY JĘZYKAMI (ACTIVE RECALL BUFFER)',
                  subtitle:
                      'Okno czasowe na próbę samodzielnego przywołania odpowiedzi w myślach lub na głos.',
                  icon: Icons.timer_outlined,
                  iconColor: AppTheme.yellowPrompt,
                ),
                const SizedBox(height: 6),
                _SliderSettingTile(
                  valueMs: session.pauseBetweenLanguagesMs,
                  minMs: 500,
                  maxMs: 3000,
                  stepMs: 250,
                  accentColor: AppTheme.yellowPrompt,
                  onChanged: (ms) => notifier.setPauseBetweenLanguages(
                    Duration(milliseconds: ms),
                  ),
                ),

                const SizedBox(height: 22),

                // 5. Pauza między powtórzeniami tego samego zdania
                _SectionTitle(
                  title: 'PAUZA MIĘDZY POWTÓRZENIAMI DOCELOWYMI',
                  subtitle:
                      'Czas na własne powtórzenie zdania aparatem mowy (Shadowing).',
                  icon: Icons.hourglass_bottom_rounded,
                  iconColor: AppTheme.textMuted,
                ),
                const SizedBox(height: 6),
                _SliderSettingTile(
                  valueMs: session.pauseBetweenRepsMs,
                  minMs: 500,
                  maxMs: 3000,
                  stepMs: 250,
                  accentColor: AppTheme.sakuraAccent,
                  onChanged: (ms) => notifier.setPauseBetweenReps(
                    Duration(milliseconds: ms),
                  ),
                ),

                const SizedBox(height: 22),

                // 6. Pauza między zdaniami
                _SectionTitle(
                  title: 'PAUZA PRZED NASTĘPNYM ZDANIEM',
                  subtitle:
                      'Czas na przyswojenie i przejście do kolejnej fiszki.',
                  icon: Icons.skip_next_rounded,
                  iconColor: AppTheme.textMuted,
                ),
                const SizedBox(height: 6),
                _SliderSettingTile(
                  valueMs: session.pauseBetweenSentencesMs,
                  minMs: 500,
                  maxMs: 4000,
                  stepMs: 250,
                  accentColor: AppTheme.greenMatcha,
                  onChanged: (ms) => notifier.setPauseBetweenSentences(
                    Duration(milliseconds: ms),
                  ),
                ),

                const SizedBox(height: 22),

                // 7. Prędkość odtwarzania
                _SectionTitle(
                  title: 'PRĘDKOŚĆ ODTWARZANIA',
                  subtitle: 'Mnożnik tempa mowy (0.7x – 1.2x).',
                  icon: Icons.speed_rounded,
                  iconColor: AppTheme.sakuraPrimary,
                ),
                const SizedBox(height: 10),
                _PlaybackSpeedSelector(
                  currentSpeed: session.playbackSpeed,
                  onChanged: notifier.setPlaybackSpeed,
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textMuted.withValues(alpha: 0.8),
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _TranslationModeSelector extends StatelessWidget {
  const _TranslationModeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  final AudioTranslationMode currentMode;
  final ValueChanged<AudioTranslationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: AudioTranslationMode.values.map((mode) {
            final isSelected = currentMode == mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Material(
                  color: isSelected
                      ? AppTheme.sakuraPrimary.withValues(alpha: 0.18)
                      : AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => onChanged(mode),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.sakuraPrimary
                              : AppTheme.surfaceBorder,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            switch (mode) {
                              AudioTranslationMode.disabled =>
                                Icons.volume_off_rounded,
                              AudioTranslationMode.prefix =>
                                Icons.playlist_play_rounded,
                              AudioTranslationMode.alternating =>
                                Icons.sync_alt_rounded,
                            },
                            size: 20,
                            color: isSelected
                                ? AppTheme.sakuraPrimary
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mode.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.textLight
                                  : AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _ModeExplanationBox extends StatelessWidget {
  const _ModeExplanationBox({required this.mode});

  final AudioTranslationMode mode;

  @override
  Widget build(BuildContext context) {
    final info = switch (mode) {
      AudioTranslationMode.disabled => (
          'Tylko język docelowy',
          'Standardowy trening. Odtwarzane jest wyłącznie nagranie w języku obcym, bez lektora ojczystego.',
          Icons.info_outline_rounded,
          AppTheme.textMuted,
        ),
      AudioTranslationMode.prefix => (
          'Scenariusz A: 1x PL → N× JP',
          'Lektor czyta polskie tłumaczenie dokładnie 1 raz na początku, po czym następuje pauza buforowa i seria powtórzeń w języku docelowym.',
          Icons.flag_circle_rounded,
          AppTheme.sakuraPrimary,
        ),
      AudioTranslationMode.alternating => (
          'Scenariusz B: PL ⇄ JP (Naprzemiennie)',
          'Każde powtórzenie parowane: Lektor PL → Pauza na przywołanie (Active Recall) → Lektor JP. Cykl powtarzany N razy.',
          Icons.published_with_changes_rounded,
          AppTheme.greenMatcha,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(info.$3, size: 18, color: info.$4),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.$1,
                  style: TextStyle(
                    color: info.$4,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.$2,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetRepsSelector extends StatelessWidget {
  const _TargetRepsSelector({
    required this.currentReps,
    required this.onChanged,
  });

  final int currentReps;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          // Decrement
          IconButton(
            tooltip: 'Mniej powtórzeń',
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: currentReps > 1 ? AppTheme.sakuraPrimary : AppTheme.surfaceBorder,
            onPressed: currentReps > 1 ? () => onChanged(currentReps - 1) : null,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$currentReps powtórzenia',
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currentReps× język docelowy w pętli',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Increment
          IconButton(
            tooltip: 'Więcej powtórzeń',
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: currentReps < 5 ? AppTheme.sakuraPrimary : AppTheme.surfaceBorder,
            onPressed: currentReps < 5 ? () => onChanged(currentReps + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _SliderSettingTile extends StatelessWidget {
  const _SliderSettingTile({
    required this.valueMs,
    required this.minMs,
    required this.maxMs,
    required this.stepMs,
    required this.accentColor,
    required this.onChanged,
  });

  final int valueMs;
  final int minMs;
  final int maxMs;
  final int stepMs;
  final Color accentColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final seconds = (valueMs / 1000).toStringAsFixed(2);
    final divisions = (maxMs - minMs) ~/ stepMs;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(minMs / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  '$seconds s  ($valueMs ms)',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(maxMs / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: AppTheme.bgDark,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: valueMs.toDouble().clamp(minMs.toDouble(), maxMs.toDouble()),
              min: minMs.toDouble(),
              max: maxMs.toDouble(),
              divisions: divisions > 0 ? divisions : null,
              onChanged: (val) {
                final snapped =
                    ((val - minMs) / stepMs).round() * stepMs + minMs;
                onChanged(snapped);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslationLanguageSelector extends ConsumerWidget {
  const _TranslationLanguageSelector({
    required this.currentLanguageCode,
    required this.onChanged,
    required this.onManageLanguages,
  });

  final String currentLanguageCode;
  final ValueChanged<String> onChanged;
  final VoidCallback onManageLanguages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedLanguages = ref.watch(unlockedLanguagesProvider);
    final languages = unlockedLanguages.isNotEmpty
        ? unlockedLanguages
        : [AppLanguage.supportedLanguages[0], AppLanguage.supportedLanguages[1]];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((lang) {
            final isSelected =
                lang.code.toLowerCase() == currentLanguageCode.toLowerCase();
            return Material(
              color: isSelected
                  ? AppTheme.sakuraPrimary.withValues(alpha: 0.18)
                  : AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onChanged(lang.code),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.sakuraPrimary
                          : AppTheme.surfaceBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang.flagEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${lang.name} (${lang.voiceDisplayName})',
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.textLight
                              : AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: AppTheme.sakuraPrimary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onManageLanguages,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.settings_outlined,
                  size: 14,
                  color: AppTheme.sakuraMuted,
                ),
                SizedBox(width: 5),
                Text(
                  'Odblokuj lub zablokuj języki globalnie',
                  style: TextStyle(
                    color: AppTheme.sakuraMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaybackSpeedSelector extends StatelessWidget {
  const _PlaybackSpeedSelector({
    required this.currentSpeed,
    required this.onChanged,
  });

  final double currentSpeed;
  final ValueChanged<double> onChanged;

  static const List<double> _speeds = [0.7, 0.8, 0.9, 1.0, 1.2];

  static double _closestSpeed(double target, List<double> speeds) {
    var best = speeds.first;
    var minDiff = (target - best).abs();
    for (final s in speeds) {
      final diff = (target - s).abs();
      if (diff < minDiff) {
        minDiff = diff;
        best = s;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final directMatch = _speeds.any((s) => (currentSpeed - s).abs() < 0.049);
    final closest = _closestSpeed(currentSpeed, _speeds);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _speeds.map((speed) {
        final isSelected = directMatch
            ? (currentSpeed - speed).abs() < 0.049
            : closest == speed;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: isSelected
                  ? AppTheme.sakuraPrimary
                  : AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onChanged(speed),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.sakuraAccent
                          : AppTheme.surfaceBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    PlaybackSpeed.formatLabel(speed),
                    style: TextStyle(
                      color: isSelected ? AppTheme.bgDark : AppTheme.textLight,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
