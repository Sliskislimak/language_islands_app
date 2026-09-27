import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/sentence_display_lines.dart';

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
  final lines = SentenceDisplayLines.resolve(sentence);
  final parts = <String>[lines.targetText];
  final katakana = lines.katakana;
  if (katakana != null) parts.add(katakana);
  final romaji = lines.romaji;
  if (romaji != null) parts.add(romaji);
  parts.add(sentence.sourceText);
  return parts.join('\n');
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
  const _StarRatingRow({required this.score, required this.onRate});

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
    this.textAlign = TextAlign.start,
  });

  final String text;
  final TextStyle style;
  final String copyMessage;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _copyToClipboard(context, text, copyMessage),
      child: Tooltip(
        message: 'Przytrzymaj, aby skopiować',
        child: Text(text, textAlign: textAlign, style: style),
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

    return JapaneseReadingColumn(
      sentence: sentence,
      targetFontSize: 21,
      katakanaFontSize: 15,
      romajiFontSize: 13,
    );
  }
}

class JapaneseReadingColumn extends StatelessWidget {
  const JapaneseReadingColumn({
    super.key,
    required this.sentence,
    this.textAlign = TextAlign.start,
    this.targetFontSize = 21,
    this.katakanaFontSize = 15,
    this.romajiFontSize = 13,
    this.sourceFontSize = 16,
    this.gap = 6,
    this.showSource = false,
    this.enableCopy = true,
  });

  final Sentence sentence;
  final TextAlign textAlign;
  final double targetFontSize;
  final double katakanaFontSize;
  final double romajiFontSize;
  final double sourceFontSize;
  final double gap;
  final bool showSource;
  final bool enableCopy;

  @override
  Widget build(BuildContext context) {
    final lines = SentenceDisplayLines.resolve(sentence);
    final align = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final children = <Widget>[
      _readingLine(
        text: lines.targetText,
        style: TextStyle(
          color: AppTheme.sakuraPrimary,
          fontSize: targetFontSize,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
        copyMessage: 'Skopiowano tekst japoński',
      ),
    ];

    final katakana = lines.katakana;
    if (katakana != null) {
      children
        ..add(SizedBox(height: gap))
        ..add(
          _readingLine(
            text: katakana,
            style: TextStyle(
              color: AppTheme.phoneticText,
              fontSize: katakanaFontSize,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            copyMessage: 'Skopiowano katakanę',
          ),
        );
    }

    final romaji = lines.romaji;
    if (romaji != null) {
      children
        ..add(SizedBox(height: gap))
        ..add(
          _readingLine(
            text: romaji,
            style: TextStyle(
              color: AppTheme.yellowPrompt,
              fontSize: romajiFontSize,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            copyMessage: 'Skopiowano zapis fonetyczny',
          ),
        );
    }

    if (showSource) {
      children
        ..add(SizedBox(height: gap + 4))
        ..add(
          _readingLine(
            text: sentence.sourceText,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: sourceFontSize,
              height: 1.4,
            ),
            copyMessage: 'Skopiowano tłumaczenie',
          ),
        );
    }

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _readingLine({
    required String text,
    required TextStyle style,
    required String copyMessage,
  }) {
    final line = Text(text, textAlign: textAlign, style: style);
    if (!enableCopy) return line;
    return _CopyableLine(
      text: text,
      style: style,
      copyMessage: copyMessage,
      textAlign: textAlign,
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
