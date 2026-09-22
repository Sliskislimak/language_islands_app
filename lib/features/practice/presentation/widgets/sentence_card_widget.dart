import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

void _copyToClipboard(BuildContext context, String text, String message) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
      ),
      backgroundColor: AppTheme.surfaceElevated,
      duration: const Duration(milliseconds: 1200),
      behavior: SnackBarBehavior.floating,
      width: 260,
    ),
  );
}

String _fullCardClipboardText(Sentence sentence) {
  final lines = <String>[sentence.targetText];
  final phonetic = sentence.phoneticReading?.trim();
  if (phonetic != null && phonetic.isNotEmpty) {
    lines.add(phonetic);
  }
  lines.add(sentence.sourceText);
  return lines.join('\n');
}

class SentenceCardWidget extends StatelessWidget {
  const SentenceCardWidget({
    super.key,
    required this.sentence,
    required this.displayIndex,
    required this.isActive,
    required this.isRevealed,
    required this.currentMode,
    required this.onPlayAudio,
    required this.onToggleReveal,
    required this.onRate,
  });

  final Sentence sentence;
  final int displayIndex;
  final bool isActive;
  final bool isRevealed;
  final PracticeMode currentMode;
  final VoidCallback onPlayAudio;
  final VoidCallback onToggleReveal;
  final ValueChanged<int> onRate;

  int get _displayScore => switch (currentMode) {
        PracticeMode.shadowing => sentence.comprehensionScore,
        PracticeMode.recall => sentence.speakingScore,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppTheme.sakuraAccent : AppTheme.surfaceBorder,
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarRow(
              index: displayIndex,
              score: _displayScore,
              onPlayAudio: onPlayAudio,
              onRate: onRate,
              onCopyAll: () => _copyToClipboard(
                context,
                _fullCardClipboardText(sentence),
                'Skopiowano całą kartę',
              ),
            ),
            const SizedBox(height: 12),
            _TextSection(
              sentence: sentence,
              currentMode: currentMode,
              isRevealed: isRevealed,
            ),
            const SizedBox(height: 10),
            _RevealBar(
              sentence: sentence,
              isRevealed: isRevealed,
              onToggleReveal: onToggleReveal,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarRow extends StatelessWidget {
  const _ToolbarRow({
    required this.index,
    required this.score,
    required this.onPlayAudio,
    required this.onRate,
    required this.onCopyAll,
  });

  final int index;
  final int score;
  final VoidCallback onPlayAudio;
  final ValueChanged<int> onRate;
  final VoidCallback onCopyAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '#$index',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPlayAudio,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.volume_up_rounded,
                size: 20,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCopyAll,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.copy_outlined,
                size: 18,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ),
        const Spacer(),
        _StarRatingRow(score: score, onRate: onRate),
      ],
    );
  }
}

class _StarRatingRow extends StatelessWidget {
  const _StarRatingRow({
    required this.score,
    required this.onRate,
  });

  final int score;
  final ValueChanged<int> onRate;

  static const int _maxStars = 5;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_maxStars, (i) {
        final starIndex = i + 1;
        final filled = starIndex <= score.clamp(0, _maxStars);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onRate(starIndex),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                Icons.star_rounded,
                size: 18,
                color: filled ? AppTheme.greenMatcha : AppTheme.surfaceBorder,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _CopyableLine extends StatelessWidget {
  const _CopyableLine({
    required this.text,
    required this.style,
    required this.copyMessage,
  });

  final String text;
  final TextStyle style;
  final String copyMessage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _copyToClipboard(context, text, copyMessage),
      child: Tooltip(
        message: 'Przytrzymaj, aby skopiować',
        child: Text(text, style: style),
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.sentence,
    required this.currentMode,
    required this.isRevealed,
  });

  final Sentence sentence;
  final PracticeMode currentMode;
  final bool isRevealed;

  bool get _showRecallPromptOnly =>
      currentMode == PracticeMode.recall && !isRevealed;

  @override
  Widget build(BuildContext context) {
    if (_showRecallPromptOnly) {
      return _CopyableLine(
        text: sentence.sourceText,
        style: const TextStyle(
          color: AppTheme.textLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        copyMessage: 'Skopiowano tłumaczenie',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CopyableLine(
          text: sentence.targetText,
          style: const TextStyle(
            color: AppTheme.sakuraPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
          copyMessage: 'Skopiowano tekst japoński',
        ),
        if (sentence.phoneticReading != null &&
            sentence.phoneticReading!.isNotEmpty) ...[
          const SizedBox(height: 4),
          _CopyableLine(
            text: sentence.phoneticReading!,
            style: const TextStyle(
              color: AppTheme.phoneticText,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
            copyMessage: 'Skopiowano zapis fonetyczny',
          ),
        ],
      ],
    );
  }
}

class _RevealBar extends StatelessWidget {
  const _RevealBar({
    required this.sentence,
    required this.isRevealed,
    required this.onToggleReveal,
  });

  final Sentence sentence;
  final bool isRevealed;
  final VoidCallback onToggleReveal;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggleReveal,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: isRevealed
              ? GestureDetector(
                  onLongPress: () => _copyToClipboard(
                    context,
                    sentence.sourceText,
                    'Skopiowano tłumaczenie',
                  ),
                  child: Tooltip(
                    message: 'Przytrzymaj, aby skopiować',
                    child: Text(
                      sentence.sourceText,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: AppTheme.yellowPrompt,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Tap to reveal',
                      style: TextStyle(
                        color: AppTheme.yellowPrompt,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
