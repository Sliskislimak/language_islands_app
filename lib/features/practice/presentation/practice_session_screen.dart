import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/practice/playback_speed.dart';
import 'package:language_islands_app/features/practice/presentation/screens/focus_mode_screen.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/audio_settings_sheet.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/focus_mode_launch_button.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/landscape_exercise_view.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/pause_duration_button.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/pip_style_buttons.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/pip_toggle_button.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/playback_speed_picker.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/recall_thinking_duration_button.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/sentence_card_widget.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/session_metrics_sidebar.dart';
import 'package:language_islands_app/features/practice/presentation/widgets/weak_sentences_filter_button.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_state.dart';

class PracticeSessionScreen extends ConsumerStatefulWidget {
  const PracticeSessionScreen({super.key, required this.collection});

  final SentenceCollection collection;

  @override
  ConsumerState<PracticeSessionScreen> createState() =>
      _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  final _sentenceItemKeys = <String, GlobalKey>{};
  bool _forceListViewInLandscape = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(practiceSessionProvider.notifier)
          .startSession(widget.collection);
    });
  }

  @override
  void dispose() {
    try {
      ref.read(practiceSessionProvider.notifier).endSession();
    } catch (_) {}
    super.dispose();
  }

  void _scrollToActiveSentence(String? sentenceId) {
    if (sentenceId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _sentenceItemKeys[sentenceId]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
        alignment: 0.25,
      );
    });
  }

  int _sentenceIndexForSession(PracticeSessionState? session) {
    if (session == null) return 0;
    final id = session.activeSentenceId;
    if (id == null) return 0;
    final index = session.visibleSentences.indexWhere(
      (sentence) => sentence.id == id,
    );
    return index >= 0 ? index : 0;
  }

  void _openFocusMode() {
    final session = ref.read(practiceSessionProvider);
    if (session == null || session.visibleSentences.isEmpty) return;

    ref.read(practiceSessionProvider.notifier).pauseContinuousPlayback();

    final initialIndex = _sentenceIndexForSession(session);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FocusModeScreen(initialIndex: initialIndex),
      ),
    );
  }

  void _openExportDialog(BuildContext context, SentenceCollection collection) {
    showDialog<void>(
      context: context,
      builder: (context) => _ExportCollectionDialog(collection: collection),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      practiceSessionProvider.select((s) => s?.activeSentenceId),
      (previous, next) {
        if (next != null && next != previous) {
          _scrollToActiveSentence(next);
        }
      },
    );

    final orientation = MediaQuery.orientationOf(context);
    if (orientation == Orientation.portrait && _forceListViewInLandscape) {
      _forceListViewInLandscape = false;
    }
    final isLandscape = orientation == Orientation.landscape;

    if (isLandscape && !_forceListViewInLandscape) {
      return LandscapeExerciseView(
        onExit: () {
          setState(() {
            _forceListViewInLandscape = true;
          });
        },
      );
    }

    final session = ref.watch(practiceSessionProvider);
    final collection = session?.collection ?? widget.collection;
    final mode = session?.mode ?? PracticeMode.shadowing;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text(
          collection.title,
          style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
        ),
        actions: [
          if (isLandscape)
            IconButton(
              tooltip: 'Włącz tryb biurkowy (Landscape)',
              icon: const Icon(
                Icons.fullscreen_rounded,
                color: AppTheme.sakuraPrimary,
              ),
              onPressed: () {
                setState(() {
                  _forceListViewInLandscape = false;
                });
              },
            ),
          IconButton(
            tooltip: 'Ustawienia odtwarzacza & lektora audio',
            icon: const Icon(Icons.tune_rounded, color: AppTheme.textLight),
            onPressed: () => showAudioSettingsSheet(context, ref),
          ),
          IconButton(
            tooltip: 'Eksportuj kolekcję (JSON)',
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.textLight),
            onPressed: () => _openExportDialog(context, collection),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(session != null ? 108 : 44),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (session != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: mode == PracticeMode.shadowing
                      ? _ShadowingSequencerBar(session: session)
                      : _RecallSequencerBar(session: session),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    _ModeToggle(
                      label: 'Shadowing',
                      selected: mode == PracticeMode.shadowing,
                      onTap: () => ref
                          .read(practiceSessionProvider.notifier)
                          .setMode(PracticeMode.shadowing),
                    ),
                    const SizedBox(width: 8),
                    _ModeToggle(
                      label: 'Recall',
                      selected: mode == PracticeMode.recall,
                      onTap: () => ref
                          .read(practiceSessionProvider.notifier)
                          .setMode(PracticeMode.recall),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 950;
          final sessionColumn = _SessionContentColumn(
            session: session,
            collection: collection,
            mode: mode,
            sentenceItemKeys: _sentenceItemKeys,
            onOpenFocusMode: _openFocusMode,
          );

          if (!isDesktop) {
            return sessionColumn;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 7, child: sessionColumn),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 16, 16),
                  child: const SessionMetricsSidebar(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionContentColumn extends ConsumerWidget {
  const _SessionContentColumn({
    required this.session,
    required this.collection,
    required this.mode,
    required this.sentenceItemKeys,
    required this.onOpenFocusMode,
  });

  final PracticeSessionState? session;
  final SentenceCollection collection;
  final PracticeMode mode;
  final Map<String, GlobalKey> sentenceItemKeys;
  final VoidCallback onOpenFocusMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sentences = session?.visibleSentences ?? collection.sentences;
    final filterActive = session?.filterOnlyWeakSentences ?? false;
    final showEmptyFilterState = filterActive && sentences.isEmpty;

    return Column(
      children: [
        if (session?.audioError != null)
          Container(
            width: double.infinity,
            color: AppTheme.surfaceBorder,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              session!.audioError!,
              style: const TextStyle(
                color: AppTheme.yellowPrompt,
                fontSize: 12,
              ),
            ),
          ),
        _SmartReviewHeader(session: session),
        Expanded(
          child: showEmptyFilterState
              ? _WeakFilterEmptyState(
                  onDisableFilter: () => ref
                      .read(practiceSessionProvider.notifier)
                      .toggleWeakSentencesFilter(),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: sentences.length,
                  itemBuilder: (context, index) {
                    final sentence = sentences[index];
                    final isActive = session?.activeSentenceId == sentence.id;
                    final isRevealed =
                        session?.revealedSentenceIds.contains(sentence.id) ??
                        false;
                    final itemKey = sentenceItemKeys.putIfAbsent(
                      sentence.id,
                      GlobalKey.new,
                    );

                    return Padding(
                      key: itemKey,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SentenceCardWidget(
                        sentence: sentence,
                        displayIndex: index + 1,
                        isActive: isActive,
                        isRevealed: isRevealed,
                        currentMode: mode,
                        onPlayAudio: () => ref
                            .read(practiceSessionProvider.notifier)
                            .playSentenceAudio(sentence),
                        onToggleReveal: () => ref
                            .read(practiceSessionProvider.notifier)
                            .toggleReveal(sentence.id),
                        onRate: (stars) => ref
                            .read(practiceSessionProvider.notifier)
                            .rateSentence(sentence, stars),
                        onSaveNotes: (notes) => ref
                            .read(practiceSessionProvider.notifier)
                            .updateSentenceNotes(sentence.id, notes),
                        activeAudioChannel: session?.activeAudioChannel ??
                            ActiveAudioChannel.none,
                      ),
                    );
                  },
                ),
        ),
        FocusModeLaunchButton(
          sentenceCount: sentences.length,
          onPressed: onOpenFocusMode,
        ),
      ],
    );
  }
}

class _SmartReviewHeader extends StatelessWidget {
  const _SmartReviewHeader({required this.session});

  final PracticeSessionState? session;

  @override
  Widget build(BuildContext context) {
    final due = session?.dueCount ?? 0;
    final newCount = session?.newCount ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Smart Review",
            style: TextStyle(
              color: AppTheme.textLight,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$due due · $newCount new',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakFilterEmptyState extends StatelessWidget {
  const _WeakFilterEmptyState({required this.onDisableFilter});

  final VoidCallback onDisableFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Wszystkie zdania opanowane na minimum 4 gwiazdki!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textLight,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onDisableFilter,
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
      ),
    );
  }
}

class _ShadowingSequencerBar extends ConsumerWidget {
  const _ShadowingSequencerBar({required this.session});

  final PracticeSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(practiceSessionProvider.notifier);
    final isPlaying = session.isPlayingContinuous;
    final reps = session.repsPerSentence;
    final speed = session.playbackSpeed;
    final loopMode = session.loopMode;
    final currentRep = session.currentRep;
    final loopActive = loopMode != LoopMode.off;
    final loopIcon = loopMode == LoopMode.single
        ? Icons.repeat_one_rounded
        : Icons.repeat_rounded;
    final loopColor = loopActive ? AppTheme.sakuraAccent : AppTheme.textMuted;
    final loopTooltip = switch (loopMode) {
      LoopMode.off => 'Zapętlanie wyłączone',
      LoopMode.list => 'Zapętl listę',
      LoopMode.single => 'Zapętl jedno zdanie',
    };

    final repLabel = isPlaying && currentRep > 0
        ? 'Rep ${currentRep}x/$reps'
        : 'Rep ${reps}x';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isPlaying) {
                    notifier.pauseContinuousPlayback();
                  } else {
                    notifier.startContinuousPlayback();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 36,
                    color: AppTheme.sakuraPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SequencerChip(
              label: repLabel,
              onTap: notifier.cycleRepsPerSentence,
            ),
            const SizedBox(width: 6),
            _AudioSettingsChip(session: session),
            const SizedBox(width: 6),
            const PauseDurationButton(),
            const SizedBox(width: 6),
            _SequencerChip(
              label: PlaybackSpeed.formatLabel(speed),
              onTap: () =>
                  showPlaybackSpeedPicker(context, ref, currentSpeed: speed),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: loopTooltip,
              child: Material(
                color: loopActive
                    ? AppTheme.sakuraAccent.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: notifier.cycleLoopMode,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: loopActive
                            ? AppTheme.sakuraAccent
                            : AppTheme.surfaceBorder,
                      ),
                    ),
                    child: Icon(loopIcon, size: 22, color: loopColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const PipToggleButton(),
            const PipStyleControls(),
          ],
        ),
      ),
    );
  }
}

class _RecallSequencerBar extends ConsumerWidget {
  const _RecallSequencerBar({required this.session});

  final PracticeSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(practiceSessionProvider.notifier);
    final isPlaying = session.isPlayingContinuous;
    final speed = session.playbackSpeed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isPlaying) {
                    notifier.pauseContinuousPlayback();
                  } else {
                    notifier.startContinuousPlayback();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 36,
                    color: AppTheme.sakuraPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _AudioSettingsChip(session: session),
            const SizedBox(width: 6),
            const RecallThinkingDurationButton(),
            const SizedBox(width: 6),
            const WeakSentencesFilterButton(),
            const SizedBox(width: 6),
            _SequencerChip(
              label: PlaybackSpeed.formatLabel(speed),
              onTap: () =>
                  showPlaybackSpeedPicker(context, ref, currentSpeed: speed),
            ),
            const SizedBox(width: 6),
            const PipToggleButton(),
            const PipStyleControls(),
          ],
        ),
      ),
    );
  }
}

class _AudioSettingsChip extends ConsumerWidget {
  const _AudioSettingsChip({required this.session});

  final PracticeSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = session.audioTranslationMode;
    final isModeActive = mode != AudioTranslationMode.disabled;

    return Tooltip(
      message:
          'Lektor tłumaczenia: ${mode.label} (kliknij, aby dostosować audio)',
      child: Material(
        color: isModeActive
            ? AppTheme.sakuraAccent.withValues(alpha: 0.15)
            : AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => showAudioSettingsSheet(context, ref),
          onLongPress: () => ref
              .read(practiceSessionProvider.notifier)
              .cycleAudioTranslationMode(),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isModeActive
                    ? AppTheme.sakuraAccent
                    : AppTheme.surfaceBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 16,
                  color: isModeActive
                      ? AppTheme.sakuraPrimary
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  mode.shortLabel,
                  style: TextStyle(
                    color:
                        isModeActive ? AppTheme.textLight : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight:
                        isModeActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SequencerChip extends StatelessWidget {
  const _SequencerChip({required this.label, required this.onTap});

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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.sakuraPrimary : AppTheme.surface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppTheme.sakuraAccent : AppTheme.surfaceBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.bgDark : AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportCollectionDialog extends StatelessWidget {
  const _ExportCollectionDialog({required this.collection});

  final SentenceCollection collection;

  @override
  Widget build(BuildContext context) {
    final jsonStr = collection.toJsonString(pretty: true);

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(Icons.code_rounded, color: AppTheme.sakuraPrimary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Eksport JSON: ${collection.title}',
              style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Poniższy JSON zawiera wygenerowane fiszki wraz z polami notatek (odwrotu) oraz przypisanymi ikonami/emoji:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zamknij', style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.sakuraPrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: jsonStr));
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Skopiowano JSON kolekcji do schowka!'),
                backgroundColor: AppTheme.surfaceElevated,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Kopiuj JSON'),
        ),
      ],
    );
  }
}
