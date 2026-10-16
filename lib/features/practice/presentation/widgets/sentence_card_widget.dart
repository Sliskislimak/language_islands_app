import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/audio_translation_mode.dart';
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
  if (sentence.hasNotes) {
    parts.add('--- Notatki ---');
    parts.add(sentence.notes!);
  }
  return parts.join('\n');
}

class SentenceCardWidget extends StatefulWidget {
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
    this.onSaveNotes,
    this.activeAudioChannel = ActiveAudioChannel.none,
    this.targetLanguageCode,
  });

  final Sentence sentence;
  final int displayIndex;
  final bool isActive;
  final bool isRevealed;
  final PracticeMode currentMode;
  final VoidCallback onPlayAudio;
  final VoidCallback onToggleReveal;
  final ValueChanged<int> onRate;
  final ValueChanged<String>? onSaveNotes;
  final ActiveAudioChannel activeAudioChannel;
  final String? targetLanguageCode;

  @override
  State<SentenceCardWidget> createState() => _SentenceCardWidgetState();
}

class _SentenceCardWidgetState extends State<SentenceCardWidget> {
  bool _isFlipped = false;
  late bool _isLocked;
  late TextEditingController _notesController;
  final FocusNode _notesFocusNode = FocusNode();
  Timer? _debounceTimer;

  int get _displayScore => switch (widget.currentMode) {
        PracticeMode.shadowing => widget.sentence.comprehensionScore,
        PracticeMode.recall => widget.sentence.speakingScore,
      };

  @override
  void initState() {
    super.initState();
    _isLocked = widget.sentence.hasNotes;
    _notesController = TextEditingController(text: widget.sentence.notes ?? '');
  }

  @override
  void didUpdateWidget(SentenceCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sentence.id != oldWidget.sentence.id) {
      _isFlipped = false;
      _isLocked = widget.sentence.hasNotes;
      _notesController.text = widget.sentence.notes ?? '';
    } else if (widget.sentence.notes != oldWidget.sentence.notes &&
        !_notesFocusNode.hasFocus) {
      _notesController.text = widget.sentence.notes ?? '';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    _saveNotes();
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isFlipped && _notesController.text.trim().isEmpty) {
        _isLocked = false;
      }
    });
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
    });
    if (_isLocked) {
      _notesFocusNode.unfocus();
      _saveNotes();
    } else {
      _notesFocusNode.requestFocus();
    }
  }

  void _onNotesChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), _saveNotes);
  }

  void _saveNotes() {
    _debounceTimer?.cancel();
    final text = _notesController.text;
    widget.onSaveNotes?.call(text);
  }

  void _copyNotes() {
    final text = _notesController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Brak notatek do skopiowania',
            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
          backgroundColor: AppTheme.surfaceElevated,
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
          width: 240,
        ),
      );
      return;
    }
    _copyToClipboard(context, text, 'Skopiowano notatki z odwrotu');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isActive ? AppTheme.sakuraAccent : AppTheme.surfaceBorder,
          width: widget.isActive ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              _isFlipped ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToolbarRow(
                index: widget.displayIndex,
                score: _displayScore,
                hasNotes: widget.sentence.hasNotes,
                onPlayAudio: widget.onPlayAudio,
                onRate: widget.onRate,
                onCopyAll: () => _copyToClipboard(
                  context,
                  _fullCardClipboardText(widget.sentence),
                  'Skopiowano całą kartę',
                ),
                onFlip: _toggleFlip,
              ),
              const SizedBox(height: 12),
              _TextSection(
                sentence: widget.sentence,
                currentMode: widget.currentMode,
                isRevealed: widget.isRevealed,
                activeAudioChannel: widget.isActive
                    ? widget.activeAudioChannel
                    : ActiveAudioChannel.none,
                targetLanguageCode: widget.targetLanguageCode,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _RevealBar(
                      sentence: widget.sentence,
                      isRevealed: widget.isRevealed,
                      onToggleReveal: widget.onToggleReveal,
                      activeAudioChannel: widget.isActive
                          ? widget.activeAudioChannel
                          : ActiveAudioChannel.none,
                    ),
                  ),
                  if (widget.sentence.visualEmojis.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 2),
                      child: _EmojiVisualCuesBadge(
                        emojis: widget.sentence.visualEmojis,
                      ),
                    ),
                ],
              ),
            ],
          ),
          secondChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _BackToolbarRow(
                isLocked: _isLocked,
                onToggleLock: _toggleLock,
                onCopyNotes: _copyNotes,
                onFlip: _toggleFlip,
              ),
              const SizedBox(height: 10),
              _BackNotesArea(
                isLocked: _isLocked,
                controller: _notesController,
                focusNode: _notesFocusNode,
                onChanged: _onNotesChanged,
                onUnlockTap: () {
                  setState(() => _isLocked = false);
                  _notesFocusNode.requestFocus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarRow extends StatelessWidget {
  const _ToolbarRow({
    required this.index,
    required this.score,
    required this.hasNotes,
    required this.onPlayAudio,
    required this.onRate,
    required this.onCopyAll,
    required this.onFlip,
  });

  final int index;
  final int score;
  final bool hasNotes;
  final VoidCallback onPlayAudio;
  final ValueChanged<int> onRate;
  final VoidCallback onCopyAll;
  final VoidCallback onFlip;

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
        const SizedBox(width: 8),
        Tooltip(
          message: hasNotes
              ? 'Odwróć fiszkę (zawiera notatki)'
              : 'Odwróć fiszkę (notatki/teoria)',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFlip,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.turn_right_rounded,
                      size: 20,
                      color: hasNotes
                          ? AppTheme.sakuraPrimary
                          : AppTheme.textMuted,
                    ),
                    if (hasNotes)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.sakuraAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackToolbarRow extends StatelessWidget {
  const _BackToolbarRow({
    required this.isLocked,
    required this.onToggleLock,
    required this.onCopyNotes,
    required this.onFlip,
  });

  final bool isLocked;
  final VoidCallback onToggleLock;
  final VoidCallback onCopyNotes;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Button in top-left: lock/unlock edit
        Tooltip(
          message: isLocked
              ? 'Kliknij, aby odblokować zapis notatek'
              : 'Kliknij, aby zablokować możliwość zapisu',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleLock,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isLocked ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                  size: 19,
                  color: isLocked ? AppTheme.textMuted : AppTheme.yellowPrompt,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Button next to lock: copy back content
        Tooltip(
          message: 'Kopiuj zawartość odwrotu',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCopyNotes,
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
        ),
        const SizedBox(width: 8),
        Text(
          isLocked ? 'Notatki / Teoria' : 'Notatki (edycja odblokowana)',
          style: TextStyle(
            color: isLocked ? AppTheme.textMuted : AppTheme.yellowPrompt,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        // Arrow in top-right to flip back to front
        Tooltip(
          message: 'Powrót do przodu fiszki',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFlip,
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.turn_left_rounded,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackNotesArea extends StatelessWidget {
  const _BackNotesArea({
    required this.isLocked,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onUnlockTap,
  });

  final bool isLocked;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onUnlockTap;

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      final text = controller.text.trim();
      if (text.isEmpty) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onUnlockTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.surfaceBorder,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: AppTheme.textMuted,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Brak notatek. Kliknij kłódkę w lewym górnym rogu lub tutaj, aby zapisać wyjaśnienia gramatyczne lub teorię.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.surfaceBorder),
        ),
        child: SelectableText(
          text,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.sakuraAccent.withValues(alpha: 0.5)),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        minLines: 3,
        maxLines: 8,
        style: const TextStyle(
          color: AppTheme.textLight,
          fontSize: 14,
          height: 1.45,
        ),
        cursorColor: AppTheme.sakuraPrimary,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12),
          hintText:
              'Wpisz wyjaśnienia gramatyczne, teorię lub notatki dla tego zdania...',
          hintStyle: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _EmojiVisualCuesBadge extends StatelessWidget {
  const _EmojiVisualCuesBadge({required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.surfaceBorder.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Tooltip(
        message: 'Skojarzenie wizualne (${emojis.join(' ')})',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < emojis.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Text(
                emojis[i],
                style: const TextStyle(fontSize: 20),
              ),
            ],
          ],
        ),
      ),
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
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
              child: Icon(
                Icons.star_rounded,
                size: 28,
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
    this.activeAudioChannel = ActiveAudioChannel.none,
    this.targetLanguageCode,
  });

  final Sentence sentence;
  final PracticeMode currentMode;
  final bool isRevealed;
  final ActiveAudioChannel activeAudioChannel;
  final String? targetLanguageCode;

  bool get _showRecallPromptOnly =>
      currentMode == PracticeMode.recall && !isRevealed;

  @override
  Widget build(BuildContext context) {
    if (_showRecallPromptOnly) {
      final isHighlight = activeAudioChannel.isTranslation;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isHighlight
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
            : EdgeInsets.zero,
        decoration: isHighlight
            ? BoxDecoration(
                color: AppTheme.yellowPrompt.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.yellowPrompt.withValues(alpha: 0.75),
                  width: 1.5,
                ),
              )
            : null,
        child: Row(
          children: [
            if (isHighlight) ...[
              const Icon(
                Icons.volume_up_rounded,
                size: 20,
                color: AppTheme.yellowPrompt,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: _CopyableLine(
                text: sentence.sourceText,
                style: TextStyle(
                  color: isHighlight
                      ? AppTheme.yellowPrompt
                      : AppTheme.textLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
                copyMessage: 'Skopiowano tłumaczenie',
              ),
            ),
          ],
        ),
      );
    }

    return JapaneseReadingColumn(
      sentence: sentence,
      targetFontSize: 21,
      katakanaFontSize: 15,
      romajiFontSize: 13,
      activeAudioChannel: activeAudioChannel,
      targetLanguageCode: targetLanguageCode,
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
    this.activeAudioChannel = ActiveAudioChannel.none,
    this.targetLanguageCode,
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
  final ActiveAudioChannel activeAudioChannel;
  final String? targetLanguageCode;

  @override
  Widget build(BuildContext context) {
    final lines = SentenceDisplayLines.resolve(sentence);
    final align = textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final isTargetActive = activeAudioChannel.isTarget;
    final isTranslationActive = activeAudioChannel.isTranslation;
    final targetLang = targetLanguageCode != null
        ? AppLanguage.find(targetLanguageCode!)
        : null;
    final targetLangName = targetLang?.name ?? 'Japoński';

    final targetChildren = <Widget>[
      _readingLine(
        text: lines.targetText,
        style: TextStyle(
          color: AppTheme.sakuraPrimary,
          fontSize: targetFontSize,
          fontWeight: FontWeight.w700,
          height: 1.35,
          shadows: isTargetActive
              ? const [
                  Shadow(
                    color: AppTheme.sakuraAccent,
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        copyMessage: 'Skopiowano tekst ${targetLangName == 'Japoński' ? 'japoński' : 'docelowy'}',
      ),
    ];

    final katakana = lines.katakana;
    if (katakana != null) {
      targetChildren
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
      targetChildren
        ..add(SizedBox(height: gap))
        ..add(
          _readingLine(
            text: romaji,
            style: TextStyle(
              color: AppTheme.yellowPrompt,
              fontSize: romajiFontSize,
              fontWeight: FontWeight.w600,
              height: 1.35,
              shadows: isTargetActive
                  ? const [
                      Shadow(
                        color: AppTheme.yellowPrompt,
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            copyMessage: 'Skopiowano zapis fonetyczny',
          ),
        );
    }

    final targetBlock = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: isTargetActive
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
          : EdgeInsets.zero,
      decoration: isTargetActive
          ? BoxDecoration(
              color: AppTheme.sakuraAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.sakuraAccent.withValues(alpha: 0.7),
                width: 1.5,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTargetActive) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.volume_up_rounded,
                  size: 16,
                  color: AppTheme.sakuraPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  '$targetLangName (Audio docelowe)',
                  style: const TextStyle(
                    color: AppTheme.sakuraPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          ...targetChildren,
        ],
      ),
    );

    if (!showSource) {
      return targetBlock;
    }

    final sourceBlock = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: isTranslationActive
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
          : EdgeInsets.zero,
      decoration: isTranslationActive
          ? BoxDecoration(
              color: AppTheme.yellowPrompt.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.yellowPrompt.withValues(alpha: 0.75),
                width: 1.5,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTranslationActive) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.volume_up_rounded,
                  size: 16,
                  color: AppTheme.yellowPrompt,
                ),
                SizedBox(width: 6),
                Text(
                  'Tłumaczenie (Lektor PL)',
                  style: TextStyle(
                    color: AppTheme.yellowPrompt,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          _readingLine(
            text: sentence.sourceText,
            style: TextStyle(
              color: isTranslationActive
                  ? AppTheme.yellowPrompt
                  : AppTheme.textMuted,
              fontSize: sourceFontSize,
              fontWeight: isTranslationActive
                  ? FontWeight.w600
                  : FontWeight.normal,
              height: 1.4,
            ),
            copyMessage: 'Skopiowano tłumaczenie',
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        targetBlock,
        SizedBox(height: gap + 4),
        sourceBlock,
      ],
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
    this.activeAudioChannel = ActiveAudioChannel.none,
  });

  final Sentence sentence;
  final bool isRevealed;
  final VoidCallback onToggleReveal;
  final ActiveAudioChannel activeAudioChannel;

  @override
  Widget build(BuildContext context) {
    final isTranslationActive = activeAudioChannel.isTranslation;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggleReveal,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: isTranslationActive
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
              : const EdgeInsets.symmetric(vertical: 6),
          decoration: isTranslationActive
              ? BoxDecoration(
                  color: AppTheme.yellowPrompt.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.yellowPrompt.withValues(alpha: 0.75),
                    width: 1.2,
                  ),
                )
              : null,
          child: isRevealed
              ? Row(
                  children: [
                    if (isTranslationActive) ...[
                      const Icon(
                        Icons.volume_up_rounded,
                        size: 16,
                        color: AppTheme.yellowPrompt,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Tłumaczenie (Lektor PL): ',
                        style: TextStyle(
                          color: AppTheme.yellowPrompt,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    Expanded(
                      child: GestureDetector(
                        onLongPress: () => _copyToClipboard(
                          context,
                          sentence.sourceText,
                          'Skopiowano tłumaczenie',
                        ),
                        child: Tooltip(
                          message: 'Przytrzymaj, aby skopiować',
                          child: Text(
                            sentence.sourceText,
                            style: TextStyle(
                              color: isTranslationActive
                                  ? AppTheme.yellowPrompt
                                  : AppTheme.textMuted,
                              fontSize: 14,
                              fontWeight: isTranslationActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
