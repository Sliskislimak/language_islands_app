import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/audio_settings_sheet.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_state.dart';
import 'package:language_islands_app/features/practice/sentence_display_lines.dart';

/// Dedicated horizontal Desk / Landscape mode view for Shadowing & Active Recall.
///
/// Optimized for desk/stand use with high-contrast, auto-fitted typography
/// across the full screen width and a compact top bar.
class LandscapeExerciseView extends ConsumerStatefulWidget {
  const LandscapeExerciseView({
    super.key,
    required this.onExit,
  });

  /// Action when user taps exit / return to list.
  final VoidCallback onExit;

  @override
  ConsumerState<LandscapeExerciseView> createState() =>
      _LandscapeExerciseViewState();
}

class _LandscapeExerciseViewState extends ConsumerState<LandscapeExerciseView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRevealOrPlay(
    Sentence sentence,
    PracticeMode mode,
    bool isRevealed,
  ) async {
    final notifier = ref.read(practiceSessionProvider.notifier);
    if (mode == PracticeMode.recall) {
      if (!isRevealed) {
        await notifier.revealSentenceForFocus(sentence);
      } else {
        await notifier.playSentenceAudio(sentence);
      }
    } else {
      await notifier.playSentenceAudio(sentence);
    }
  }

  void _handleRate(Sentence sentence, int stars) {
    ref.read(practiceSessionProvider.notifier).rateSentence(sentence, stars);
  }

  void _handleSkipNext() {
    ref.read(practiceSessionProvider.notifier).skipToNextSentence();
  }

  void _handleSkipPrevious() {
    ref.read(practiceSessionProvider.notifier).skipToPreviousSentence();
  }

  void _handleToggleContinuous(PracticeSessionState session) {
    final notifier = ref.read(practiceSessionProvider.notifier);
    if (session.isPlayingContinuous) {
      notifier.pauseContinuousPlayback();
    } else {
      notifier.startContinuousPlayback();
    }
  }

  void _handleSetMode(PracticeMode mode) {
    ref.read(practiceSessionProvider.notifier).setMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(practiceSessionProvider);
    if (session == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: const Center(
          child: Text(
            'Sesja zakończona',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
          ),
        ),
      );
    }

    final sentences = session.visibleSentences;
    if (sentences.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(
                context: context,
                session: session,
                sentence: null,
                currentIndex: 0,
                totalCount: 0,
                score: 0,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    session.filterOnlyWeakSentences
                        ? 'Wszystkie zdania opanowane na minimum 4 gwiazdki!'
                        : 'Brak zdań w kolekcji',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentId = session.activeSentenceId;
    final foundIndex = sentences.indexWhere((s) => s.id == currentId);
    final safeIndex = foundIndex >= 0 ? foundIndex : 0;
    final sentence = sentences[safeIndex];
    final isRevealed = session.revealedSentenceIds.contains(sentence.id);
    final mode = session.mode;
    final score = switch (mode) {
      PracticeMode.shadowing => sentence.comprehensionScore,
      PracticeMode.recall => sentence.speakingScore,
    };

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () {
          _handleRevealOrPlay(sentence, mode, isRevealed);
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): _handleSkipNext,
        const SingleActivator(LogicalKeyboardKey.enter): _handleSkipNext,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _handleSkipPrevious,
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _handleRate(sentence, 1),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _handleRate(sentence, 2),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _handleRate(sentence, 3),
        const SingleActivator(LogicalKeyboardKey.digit4): () =>
            _handleRate(sentence, 4),
        const SingleActivator(LogicalKeyboardKey.digit5): () =>
            _handleRate(sentence, 5),
        const SingleActivator(LogicalKeyboardKey.numpad1): () =>
            _handleRate(sentence, 1),
        const SingleActivator(LogicalKeyboardKey.numpad2): () =>
            _handleRate(sentence, 2),
        const SingleActivator(LogicalKeyboardKey.numpad3): () =>
            _handleRate(sentence, 3),
        const SingleActivator(LogicalKeyboardKey.numpad4): () =>
            _handleRate(sentence, 4),
        const SingleActivator(LogicalKeyboardKey.numpad5): () =>
            _handleRate(sentence, 5),
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: SafeArea(
            left: true,
            right: true,
            top: true,
            bottom: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(
                  context: context,
                  session: session,
                  sentence: sentence,
                  currentIndex: safeIndex,
                  totalCount: sentences.length,
                  score: score,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: _buildCoreContent(
                      sentence: sentence,
                      mode: mode,
                      isRevealed: isRevealed,
                      activeChannel: session.activeAudioChannel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact Top App Bar (~46 px high) with desk controls.
  Widget _buildTopBar({
    required BuildContext context,
    required PracticeSessionState session,
    required Sentence? sentence,
    required int currentIndex,
    required int totalCount,
    required int score,
  }) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final exitButton = IconButton(
            icon: const Icon(
              Icons.view_list_rounded,
              color: AppTheme.textLight,
              size: 20,
            ),
            tooltip: 'Powrót do listy',
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: widget.onExit,
          );

          final modeToggle = Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppTheme.bgDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CompactModeChip(
                  label: 'Shadowing',
                  isSelected: session.mode == PracticeMode.shadowing,
                  onTap: () => _handleSetMode(PracticeMode.shadowing),
                ),
                _CompactModeChip(
                  label: 'Recall',
                  isSelected: session.mode == PracticeMode.recall,
                  onTap: () => _handleSetMode(PracticeMode.recall),
                ),
              ],
            ),
          );

          final counterBadge = totalCount > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${currentIndex + 1}/$totalCount',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null;

          final starRating = sentence != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final filled = star <= score.clamp(0, 5);
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleRate(sentence, star),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 4,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            size: 24,
                            color: filled
                                ? AppTheme.greenMatcha
                                : AppTheme.surfaceBorder,
                          ),
                        ),
                      ),
                    );
                  }),
                )
              : null;

          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.skip_previous_rounded,
                  color: AppTheme.textLight,
                  size: 22,
                ),
                tooltip: 'Poprzednie zdanie',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: totalCount > 0 ? _handleSkipPrevious : null,
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: Icon(
                  session.isPlayingContinuous
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: AppTheme.sakuraPrimary,
                  size: 30,
                ),
                tooltip: session.isPlayingContinuous
                    ? 'Wstrzymaj odtwarzanie'
                    : 'Odtwarzaj ciągle',
                splashRadius: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                onPressed: totalCount > 0
                    ? () => _handleToggleContinuous(session)
                    : null,
              ),
              const SizedBox(width: 2),
              IconButton(
                icon: const Icon(
                  Icons.skip_next_rounded,
                  color: AppTheme.textLight,
                  size: 22,
                ),
                tooltip: 'Następne zdanie',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: totalCount > 0 ? _handleSkipNext : null,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.textLight,
                  size: 20,
                ),
                tooltip: 'Ustawienia odtwarzacza & audio',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => showAudioSettingsSheet(context, ref),
              ),
            ],
          );

          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  exitButton,
                  const SizedBox(width: 6),
                  modeToggle,
                  if (counterBadge != null) ...[
                    const SizedBox(width: 6),
                    counterBadge,
                  ],
                  if (starRating != null) ...[
                    const SizedBox(width: 8),
                    starRating,
                  ],
                  const SizedBox(width: 8),
                  controls,
                ],
              ),
            );
          }

          return Row(
            children: [
              exitButton,
              const SizedBox(width: 8),
              modeToggle,
              if (counterBadge != null) ...[
                const SizedBox(width: 10),
                counterBadge,
              ],
              const Spacer(),
              if (starRating != null) starRating,
              const Spacer(),
              controls,
            ],
          );
        },
      ),
    );
  }

  /// Core Content Area: 4 distinct vertically ordered rows with auto-fit scaling.
  Widget _buildCoreContent({
    required Sentence sentence,
    required PracticeMode mode,
    required bool isRevealed,
    required ActiveAudioChannel activeChannel,
  }) {
    final lines = SentenceDisplayLines.resolve(sentence);
    final isTargetActive = activeChannel.isTarget;
    final isTranslationActive = activeChannel.isTranslation;
    final isRecallHidden = mode == PracticeMode.recall && !isRevealed;
    final session = ref.watch(practiceSessionProvider);
    final targetLang = session?.targetLanguage != null
        ? AppLanguage.find(session!.targetLanguage)
        : null;
    final targetLangName = targetLang?.name ?? 'Japoński';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 3),

          // If Active Recall is unrevealed, conceal Rows 1-3 with a placeholder and reveal trigger
          if (isRecallHidden) ...[
            _buildConcealedRecallBlock(sentence, mode, targetLangName),
          ] else ...[
            // ROW 1: Japanese original text (Kanji / Kana) - Primary Target Script
            _AutoFitRow(
              text: lines.targetText,
              style: TextStyle(
                color: AppTheme.sakuraPrimary,
                fontSize: 44,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                shadows: isTargetActive
                    ? const [
                        Shadow(
                          color: AppTheme.sakuraAccent,
                          blurRadius: 18,
                        ),
                      ]
                    : null,
              ),
              isHighlighted: isTargetActive,
              badgeText: isTargetActive ? 'Audio docelowe' : null,
              badgeColor: AppTheme.sakuraPrimary,
              onTap: () => _handleRevealOrPlay(sentence, mode, isRevealed),
            ),

            // ROW 2: Phonetic script (Katakana / Hiragana) - Secondary Decoding Script
            if (lines.katakana != null) ...[
              const Spacer(flex: 1),
              _AutoFitRow(
                text: lines.katakana!,
                style: TextStyle(
                  color: isTargetActive
                      ? AppTheme.sakuraAccent
                      : AppTheme.phoneticText,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
                isHighlighted: isTargetActive,
                onTap: () => _handleRevealOrPlay(sentence, mode, isRevealed),
              ),
            ],

            // ROW 3: Phonetic transcription (Romaji) - Smooth Pronunciation
            if (lines.romaji != null) ...[
              const Spacer(flex: 1),
              _AutoFitRow(
                text: lines.romaji!,
                style: TextStyle(
                  color: AppTheme.yellowPrompt,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  shadows: isTargetActive
                      ? const [
                          Shadow(
                            color: AppTheme.yellowPrompt,
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                isHighlighted: isTargetActive,
                onTap: () => _handleRevealOrPlay(sentence, mode, isRevealed),
              ),
            ],
          ],

          const Spacer(flex: 2),

          // ROW 4: Translation (Native Language / PL) - Semantic Anchor
          _AutoFitRow(
            text: sentence.sourceText,
            style: TextStyle(
              color: isTranslationActive
                  ? AppTheme.yellowPrompt
                  : (isRecallHidden ? AppTheme.textLight : AppTheme.textMuted),
              fontSize: isRecallHidden ? 30 : 24,
              fontWeight: isTranslationActive || isRecallHidden
                  ? FontWeight.w700
                  : FontWeight.w500,
              letterSpacing: 0.4,
              shadows: isTranslationActive
                  ? const [
                      Shadow(
                        color: AppTheme.yellowPrompt,
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            isHighlighted: isTranslationActive,
            badgeText: isTranslationActive
                ? 'Lektor tłumaczenia (PL)'
                : (isRecallHidden
                    ? (targetLangName == 'Japoński'
                        ? 'Pytanie (Przypomnij sobie japoński)'
                        : 'Pytanie (Przypomnij sobie ${targetLangName.toLowerCase()})')
                    : null),
            badgeColor: isTranslationActive
                ? AppTheme.yellowPrompt
                : AppTheme.textMuted,
            onTap: () => _handleRevealOrPlay(sentence, mode, isRevealed),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  /// Concealed block shown during Active Recall before answer is revealed.
  Widget _buildConcealedRecallBlock(
    Sentence sentence,
    PracticeMode mode, [
    String targetLangName = 'Japoński',
  ]) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '• • •   [ $targetLangName ukryty ]   • • •',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _handleRevealOrPlay(sentence, mode, false),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.yellowPrompt.withValues(alpha: 0.7),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: AppTheme.yellowPrompt,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Odsłoń odpowiedź (Spacja)',
                    style: TextStyle(
                      color: AppTheme.yellowPrompt,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dynamic auto-fit single line row that fills the width without clipping or overflowing.
class _AutoFitRow extends StatelessWidget {
  const _AutoFitRow({
    required this.text,
    required this.style,
    this.isHighlighted = false,
    this.badgeText,
    this.badgeColor,
    this.onTap,
  });

  final String text;
  final TextStyle style;
  final bool isHighlighted;
  final String? badgeText;
  final Color? badgeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBadgeColor = badgeColor ?? AppTheme.sakuraPrimary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isHighlighted
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: isHighlighted
            ? BoxDecoration(
                color: effectiveBadgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: effectiveBadgeColor.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeText != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    size: 14,
                    color: effectiveBadgeColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    badgeText!,
                    style: TextStyle(
                      color: effectiveBadgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact toggle chip for mode selection in the landscape top bar.
class _CompactModeChip extends StatelessWidget {
  const _CompactModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.sakuraAccent : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textMuted,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
