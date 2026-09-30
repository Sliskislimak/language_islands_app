import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/audio_translation_mode.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/audio_settings_sheet.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/landscape_exercise_view.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/sentence_card_widget.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/weak_sentences_filter_button.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

class FocusModeScreen extends ConsumerStatefulWidget {
  const FocusModeScreen({super.key, required this.initialIndex});

  final int initialIndex;

  @override
  ConsumerState<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends ConsumerState<FocusModeScreen> {
  late int _cardIndex;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _cardIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(practiceSessionProvider.notifier)
          .setActiveSentenceIndex(_cardIndex);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Sentence? _sentenceAt(int index) {
    final session = ref.read(practiceSessionProvider);
    final sentences = session?.visibleSentences ?? [];
    if (sentences.isEmpty || index < 0 || index >= sentences.length) {
      return null;
    }
    return sentences[index];
  }

  void _goToIndex(int index) {
    final session = ref.read(practiceSessionProvider);
    final count = session?.visibleSentences.length ?? 0;
    if (count == 0) return;
    final next = index.clamp(0, count - 1);
    final prev = _cardIndex;
    setState(() => _cardIndex = next);
    if (session?.isPlayingContinuous == true) {
      if (next > prev) {
        ref.read(practiceSessionProvider.notifier).skipToNextSentence();
      } else if (next < prev) {
        ref.read(practiceSessionProvider.notifier).skipToPreviousSentence();
      }
    } else {
      ref.read(practiceSessionProvider.notifier).setActiveSentenceIndex(next);
    }
  }

  void _syncCardIndexToVisible() {
    if (!mounted) return;
    final session = ref.read(practiceSessionProvider);
    if (session == null) return;
    final sentences = session.visibleSentences;
    if (sentences.isEmpty) {
      if (_cardIndex != 0) {
        setState(() => _cardIndex = 0);
      }
      return;
    }

    final currentId = session.activeSentenceId;
    final byId = sentences.indexWhere((s) => s.id == currentId);
    final next = byId >= 0 ? byId : _cardIndex.clamp(0, sentences.length - 1);
    if (next != _cardIndex) {
      setState(() => _cardIndex = next);
    }
    if (byId < 0) {
      ref.read(practiceSessionProvider.notifier).setActiveSentenceIndex(next);
    }
  }

  void _goPrevious() => _goToIndex(_cardIndex - 1);

  void _goNext() => _goToIndex(_cardIndex + 1);

  Future<void> _onRevealOrPlay() async {
    final sentence = _sentenceAt(_cardIndex);
    if (sentence == null) return;
    await ref
        .read(practiceSessionProvider.notifier)
        .revealSentenceForFocus(sentence);
  }

  void _onRate(int stars) {
    final sentence = _sentenceAt(_cardIndex);
    if (sentence == null) return;
    ref.read(practiceSessionProvider.notifier).rateSentence(sentence, stars);
  }

  Future<void> _playAudio() async {
    final sentence = _sentenceAt(_cardIndex);
    if (sentence == null) return;
    await ref
        .read(practiceSessionProvider.notifier)
        .playSentenceAudio(sentence);
  }

  void _openNotesSheet(Sentence sentence) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FocusNotesSheet(
        sentence: sentence,
        onSave: (notes) {
          ref
              .read(practiceSessionProvider.notifier)
              .updateSentenceNotes(sentence.id, notes);
        },
      ),
    );
  }

  void _shadowingReveal(Sentence sentence) {
    ref.read(practiceSessionProvider.notifier).toggleReveal(sentence.id);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      practiceSessionProvider.select(
        (s) => s?.filterOnlyWeakSentences ?? false,
      ),
      (previous, next) => _syncCardIndexToVisible(),
    );
    ref.listen<int>(
      practiceSessionProvider.select((s) => s?.visibleSentences.length ?? 0),
      (previous, next) => _syncCardIndexToVisible(),
    );
    ref.listen<String?>(
      practiceSessionProvider.select((s) => s?.activeSentenceId),
      (previous, next) {
        if (next != null && next != previous) {
          _syncCardIndexToVisible();
        }
      },
    );

    final orientation = MediaQuery.orientationOf(context);
    if (orientation == Orientation.landscape) {
      return LandscapeExerciseView(
        onExit: () => Navigator.of(context).pop(),
      );
    }

    final session = ref.watch(practiceSessionProvider);
    if (session == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
          child: Text(
            'Sesja zakończona',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }

    final sentences = session.visibleSentences;
    if (sentences.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(session.collection.title),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: WeakSentencesFilterButton(),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.filterOnlyWeakSentences
                      ? 'Wszystkie zdania opanowane na minimum 4 gwiazdki!'
                      : 'Brak zdań w kolekcji',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (session.filterOnlyWeakSentences) ...[
                  const SizedBox(height: 16),
                  Material(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => ref
                          .read(practiceSessionProvider.notifier)
                          .toggleWeakSentencesFilter(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.yellowPrompt),
                        ),
                        child: const Text(
                          'Wyłącz filtr',
                          style: TextStyle(
                            color: AppTheme.yellowPrompt,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final safeIndex = _cardIndex.clamp(0, sentences.length - 1);
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
          _onRevealOrPlay();
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): _goNext,
        const SingleActivator(LogicalKeyboardKey.enter): _goNext,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _goPrevious,
        const SingleActivator(LogicalKeyboardKey.digit1): () => _onRate(1),
        const SingleActivator(LogicalKeyboardKey.digit2): () => _onRate(2),
        const SingleActivator(LogicalKeyboardKey.digit3): () => _onRate(3),
        const SingleActivator(LogicalKeyboardKey.digit4): () => _onRate(4),
        const SingleActivator(LogicalKeyboardKey.digit5): () => _onRate(5),
        const SingleActivator(LogicalKeyboardKey.numpad1): () => _onRate(1),
        const SingleActivator(LogicalKeyboardKey.numpad2): () => _onRate(2),
        const SingleActivator(LogicalKeyboardKey.numpad3): () => _onRate(3),
        const SingleActivator(LogicalKeyboardKey.numpad4): () => _onRate(4),
        const SingleActivator(LogicalKeyboardKey.numpad5): () => _onRate(5),
      },
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FocusTopBar(
                  title: session.collection.title,
                  sentence: sentence,
                  cardIndex: safeIndex,
                  total: sentences.length,
                  onClose: () => Navigator.of(context).pop(),
                  onOpenNotes: () => _openNotesSheet(sentence),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: _FocusCardContent(
                        sentence: sentence,
                        mode: mode,
                        isRevealed: isRevealed,
                        onShadowingReveal: () => _shadowingReveal(sentence),
                        onRecallReveal: _onRevealOrPlay,
                        activeAudioChannel: session.activeAudioChannel,
                      ),
                    ),
                  ),
                ),
                _FocusControlPanel(
                  score: score,
                  onPlay: _playAudio,
                  onRate: _onRate,
                  onPrevious: _goPrevious,
                  onNext: _goNext,
                  canGoPrevious: safeIndex > 0,
                  canGoNext: safeIndex < sentences.length - 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusTopBar extends ConsumerWidget {
  const _FocusTopBar({
    required this.title,
    required this.sentence,
    required this.cardIndex,
    required this.total,
    required this.onClose,
    required this.onOpenNotes,
  });

  final String title;
  final Sentence sentence;
  final int cardIndex;
  final int total;
  final VoidCallback onClose;
  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppTheme.textLight),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Karta ${cardIndex + 1} z $total',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: 'Lektor tłumaczenia & Audio',
            child: IconButton(
              onPressed: () => showAudioSettingsSheet(context, ref),
              icon: const Icon(Icons.tune_rounded, color: AppTheme.textLight),
            ),
          ),
          const SizedBox(width: 2),
          Tooltip(
            message: sentence.hasNotes
                ? 'Notatki (zawiera notatki)'
                : 'Notatki / Teoria',
            child: IconButton(
              onPressed: onOpenNotes,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.turn_right_rounded,
                    color: sentence.hasNotes
                        ? AppTheme.sakuraPrimary
                        : AppTheme.textMuted,
                  ),
                  if (sentence.hasNotes)
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
          const SizedBox(width: 4),
          const WeakSentencesFilterButton(),
        ],
      ),
    );
  }
}

class _FocusCardContent extends StatelessWidget {
  const _FocusCardContent({
    required this.sentence,
    required this.mode,
    required this.isRevealed,
    required this.onShadowingReveal,
    required this.onRecallReveal,
    this.activeAudioChannel = ActiveAudioChannel.none,
  });

  final Sentence sentence;
  final PracticeMode mode;
  final bool isRevealed;
  final VoidCallback onShadowingReveal;
  final VoidCallback onRecallReveal;
  final ActiveAudioChannel activeAudioChannel;

  @override
  Widget build(BuildContext context) {
    if (mode == PracticeMode.recall && !isRevealed) {
      final isHighlight = activeAudioChannel.isTranslation;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: isHighlight
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                : EdgeInsets.zero,
            decoration: isHighlight
                ? BoxDecoration(
                    color: AppTheme.yellowPrompt.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.yellowPrompt.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isHighlight) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.volume_up_rounded,
                        size: 20,
                        color: AppTheme.yellowPrompt,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Lektor tłumaczenia (PL)',
                        style: TextStyle(
                          color: AppTheme.yellowPrompt,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  sentence.sourceText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isHighlight
                        ? AppTheme.yellowPrompt
                        : AppTheme.textLight,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _TapToRevealButton(onTap: onRecallReveal),
          if (sentence.visualEmojis.isNotEmpty) ...[
            const SizedBox(height: 24),
            _FocusEmojiVisualCuesBadge(emojis: sentence.visualEmojis),
          ],
        ],
      );
    }

    if (mode == PracticeMode.recall && isRevealed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          JapaneseReadingColumn(
            sentence: sentence,
            textAlign: TextAlign.center,
            targetFontSize: 32,
            katakanaFontSize: 22,
            romajiFontSize: 18,
            sourceFontSize: 16,
            gap: 10,
            showSource: true,
            enableCopy: false,
            activeAudioChannel: activeAudioChannel,
          ),
          if (sentence.visualEmojis.isNotEmpty) ...[
            const SizedBox(height: 24),
            _FocusEmojiVisualCuesBadge(emojis: sentence.visualEmojis),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        JapaneseReadingColumn(
          sentence: sentence,
          textAlign: TextAlign.center,
          targetFontSize: 32,
          katakanaFontSize: 22,
          romajiFontSize: 18,
          sourceFontSize: 16,
          gap: 10,
          showSource: isRevealed,
          enableCopy: false,
          activeAudioChannel: activeAudioChannel,
        ),
        if (!isRevealed) ...[
          const SizedBox(height: 28),
          _TapToRevealButton(onTap: onShadowingReveal),
        ],
        if (sentence.visualEmojis.isNotEmpty) ...[
          const SizedBox(height: 24),
          _FocusEmojiVisualCuesBadge(emojis: sentence.visualEmojis),
        ],
      ],
    );
  }
}

class _TapToRevealButton extends StatelessWidget {
  const _TapToRevealButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.surfaceBorder),
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
                'Tap to reveal',
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
    );
  }
}

class _FocusControlPanel extends StatelessWidget {
  const _FocusControlPanel({
    required this.score,
    required this.onPlay,
    required this.onRate,
    required this.onPrevious,
    required this.onNext,
    required this.canGoPrevious,
    required this.canGoNext,
  });

  final int score;
  final VoidCallback onPlay;
  final ValueChanged<int> onRate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoPrevious;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.surfaceBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppTheme.surfaceElevated,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPlay,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 36,
                  color: AppTheme.sakuraPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              final filled = star <= score.clamp(0, 5);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onRate(star),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.star_rounded,
                        size: 42,
                        color: filled
                            ? AppTheme.greenMatcha
                            : AppTheme.surfaceBorder,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavCircleButton(
                icon: Icons.chevron_left_rounded,
                onPressed: canGoPrevious ? onPrevious : null,
              ),
              const SizedBox(width: 24),
              _NavCircleButton(
                icon: Icons.chevron_right_rounded,
                onPressed: canGoNext ? onNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavCircleButton extends StatelessWidget {
  const _NavCircleButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? AppTheme.surfaceElevated : AppTheme.bgDark,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 32,
            color: enabled ? AppTheme.textLight : AppTheme.surfaceBorder,
          ),
        ),
      ),
    );
  }
}

class _FocusNotesSheet extends StatefulWidget {
  const _FocusNotesSheet({required this.sentence, required this.onSave});

  final Sentence sentence;
  final ValueChanged<String> onSave;

  @override
  State<_FocusNotesSheet> createState() => _FocusNotesSheetState();
}

class _FocusNotesSheetState extends State<_FocusNotesSheet> {
  late bool _isLocked;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isLocked = widget.sentence.hasNotes;
    _controller = TextEditingController(text: widget.sentence.notes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleLock() {
    setState(() => _isLocked = !_isLocked);
    if (_isLocked) {
      _focusNode.unfocus();
      widget.onSave(_controller.text);
    } else {
      _focusNode.requestFocus();
    }
  }

  void _copyNotes() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skopiowano notatki z odwrotu'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: _isLocked ? 'Odblokuj edycję' : 'Zablokuj zapis',
                icon: Icon(
                  _isLocked
                      ? Icons.lock_outline_rounded
                      : Icons.lock_open_rounded,
                  color: _isLocked ? AppTheme.textMuted : AppTheme.yellowPrompt,
                ),
                onPressed: _toggleLock,
              ),
              IconButton(
                tooltip: 'Kopiuj notatki',
                icon: const Icon(
                  Icons.copy_outlined,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
                onPressed: _copyNotes,
              ),
              const SizedBox(width: 8),
              Text(
                _isLocked ? 'Notatki / Teoria' : 'Notatki (edycja)',
                style: TextStyle(
                  color: _isLocked ? AppTheme.textLight : AppTheme.yellowPrompt,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                onPressed: () {
                  widget.onSave(_controller.text);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLocked)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: _controller.text.trim().isEmpty
                  ? const Text(
                      'Brak notatek dla tej karty. Kliknij kłódkę w lewym górnym rogu, aby dodać teorię lub notatki.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    )
                  : SelectableText(
                      _controller.text,
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
            )
          else
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 15),
              cursorColor: AppTheme.sakuraPrimary,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                hintText: 'Wpisz notatki gramatyczne, teorię lub kontekst...',
                hintStyle:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.sakuraAccent),
                ),
              ),
              onChanged: widget.onSave,
            ),
        ],
      ),
    );
  }
}

class _FocusEmojiVisualCuesBadge extends StatelessWidget {
  const _FocusEmojiVisualCuesBadge({required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.surfaceBorder.withValues(alpha: 0.8),
          width: 0.8,
        ),
      ),
      child: Tooltip(
        message: 'Skojarzenie wizualne',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < emojis.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Text(
                emojis[i],
                style: const TextStyle(fontSize: 26),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
