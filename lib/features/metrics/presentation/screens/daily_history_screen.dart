import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/daily_sentence_entry.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/metrics/providers/daily_history_controller.dart';

class DailyHistoryScreen extends ConsumerStatefulWidget {
  const DailyHistoryScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<DailyHistoryScreen> createState() => _DailyHistoryScreenState();
}

class _DailyHistoryScreenState extends ConsumerState<DailyHistoryScreen> {
  late final TextEditingController _noteController;
  String _activeFilter = 'Wszystkie';
  bool _isSavingNote = false;
  bool _noteSavedFeedback = false;
  String? _lastLoadedDateKey;

  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    if (widget.initialDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(dailyHistoryControllerProvider.notifier)
            .selectDate(widget.initialDate!);
      });
    }
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _syncNoteFromState(DailyHistoryState state) {
    if (_lastLoadedDateKey != state.selectedDateKey) {
      _lastLoadedDateKey = state.selectedDateKey;
      _noteController.text = state.dayNote;
      _noteSavedFeedback = false;
    }
  }

  Future<void> _saveNote() async {
    setState(() => _isSavingNote = true);
    await ref
        .read(dailyHistoryControllerProvider.notifier)
        .saveDailyNote(_noteController.text);
    if (!mounted) return;
    setState(() {
      _isSavingNote = false;
      _noteSavedFeedback = true;
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _noteSavedFeedback = false);
    });
  }

  Future<void> _pickDate(BuildContext context, DailyHistoryState state) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: AppTheme.japaneseDarkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.sakuraPrimary,
              onPrimary: AppTheme.bgDark,
              surface: AppTheme.surfaceElevated,
              onSurface: AppTheme.textLight,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      await ref
          .read(dailyHistoryControllerProvider.notifier)
          .selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(dailyHistoryControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text(
          'Historia i Dziennik Dnia',
          style: TextStyle(color: AppTheme.textLight, fontSize: 18),
        ),
        actions: [
          historyAsync.whenOrNull(
                data: (state) {
                  return IconButton(
                    tooltip: 'Wybierz datę z kalendarza',
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppTheme.sakuraPrimary,
                    ),
                    onPressed: () => _pickDate(context, state),
                  );
                },
              ) ??
              const SizedBox(),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.sakuraPrimary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Błąd wczytywania historii: $err',
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ),
        data: (state) {
          _syncNoteFromState(state);
          return _buildContent(context, state);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, DailyHistoryState state) {
    final filteredEntries = _filterEntries(state.sentenceEntries);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _DateNavigationBar(
          state: state,
          onPrevious: () =>
              ref.read(dailyHistoryControllerProvider.notifier).previousDay(),
          onNext: () =>
              ref.read(dailyHistoryControllerProvider.notifier).nextDay(),
          onTapCenter: () => _pickDate(context, state),
          onTodayTap: state.isToday
              ? null
              : () => ref
                  .read(dailyHistoryControllerProvider.notifier)
                  .selectDate(DateTime.now()),
        ),
        const SizedBox(height: 16),
        _DayRatingCard(
          dayRating: state.dayRating,
          onRate: (stars) => ref
              .read(dailyHistoryControllerProvider.notifier)
              .setDayRating(stars),
        ),
        const SizedBox(height: 14),
        _DayProgressSummaryCard(state: state),
        const SizedBox(height: 14),
        _DailyNoteCard(
          controller: _noteController,
          isSaving: _isSavingNote,
          isSaved: _noteSavedFeedback,
          onSave: _saveNote,
        ),
        const SizedBox(height: 20),
        _SentenceEntriesHeader(
          totalCount: state.sentenceEntries.length,
          activeFilter: _activeFilter,
          onFilterChanged: (filter) => setState(() => _activeFilter = filter),
        ),
        const SizedBox(height: 10),
        if (filteredEntries.isEmpty)
          _EmptyDayState(
            isFiltered: state.sentenceEntries.isNotEmpty,
            hasDataOnOtherDays: state.allDatesWithData.isNotEmpty,
          )
        else
          ...filteredEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SentenceLogCard(entry: entry),
            ),
          ),
        if (state.allDatesWithData.length > 1) ...[
          const SizedBox(height: 24),
          _DaysTimelineSelector(
            currentDateKey: state.selectedDateKey,
            dates: state.allDatesWithData,
            onSelectDateKey: (dateKey) {
              final parsed = DateTime.tryParse(dateKey);
              if (parsed != null) {
                ref
                    .read(dailyHistoryControllerProvider.notifier)
                    .selectDate(parsed);
              }
            },
          ),
        ],
      ],
    );
  }

  List<DailySentenceEntry> _filterEntries(List<DailySentenceEntry> entries) {
    switch (_activeFilter) {
      case 'Ocenione ★':
        return entries.where((e) => e.stars > 0).toList();
      case 'Shadowing':
        return entries
            .where((e) => (e.mode ?? '').toLowerCase().contains('shadowing'))
            .toList();
      case 'Recall':
        return entries
            .where((e) => (e.mode ?? '').toLowerCase().contains('recall'))
            .toList();
      default:
        return entries;
    }
  }
}

class _DateNavigationBar extends StatelessWidget {
  const _DateNavigationBar({
    required this.state,
    required this.onPrevious,
    required this.onNext,
    required this.onTapCenter,
    required this.onTodayTap,
  });

  final DailyHistoryState state;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTapCenter;
  final VoidCallback? onTodayTap;

  @override
  Widget build(BuildContext context) {
    final date = state.selectedDate;
    final dateFormatted = _formatPolishDate(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Poprzedni dzień',
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
            color: AppTheme.textLight,
            onPressed: onPrevious,
          ),
          Expanded(
            child: InkWell(
              onTap: onTapCenter,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.isToday ? 'Dzisiaj' : dateFormatted.$1,
                          style: const TextStyle(
                            color: AppTheme.sakuraPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppTheme.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormatted.$2,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onTodayTap != null)
            TextButton(
              onPressed: onTodayTap,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text(
                'Dziś',
                style: TextStyle(
                  color: AppTheme.greenMatcha,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Następny dzień',
            icon: const Icon(Icons.chevron_right_rounded, size: 28),
            color: AppTheme.textLight,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }

  (String, String) _formatPolishDate(DateTime date) {
    const months = [
      'stycznia',
      'lutego',
      'marca',
      'kwietnia',
      'maja',
      'czerwca',
      'lipca',
      'sierpnia',
      'września',
      'października',
      'listopada',
      'grudnia',
    ];
    const weekdays = [
      'Poniedziałek',
      'Wtorek',
      'Środa',
      'Czwartek',
      'Piątek',
      'Sobota',
      'Niedziela',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    final dayStr = '${date.day} $month ${date.year}';
    return (weekday, dayStr);
  }
}

class _DayRatingCard extends StatelessWidget {
  const _DayRatingCard({
    required this.dayRating,
    required this.onRate,
  });

  final int dayRating;
  final ValueChanged<int> onRate;

  String get _ratingLabel {
    switch (dayRating) {
      case 1:
        return '★☆☆☆☆ · Bardzo trudny dzień / Minimalna sesja';
      case 2:
        return '★★☆☆☆ · Wymagający trening, ale zrobiony';
      case 3:
        return '★★★☆☆ · Dobra, solidna sesja treningowa';
      case 4:
        return '★★★★☆ · Bardzo dobry dzień, wysokie skupienie';
      case 5:
        return '★★★★★ · Perfekcyjny dzień, maksymalna płynność!';
      default:
        return 'Dotknij gwiazdki, aby wystawić ocenę tego dnia';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hotel_class_rounded,
                color: AppTheme.sakuraPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'OCENA TEGO DNIA',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (dayRating > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.greenMatcha.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$dayRating / 5 ★',
                    style: const TextStyle(
                      color: AppTheme.greenMatcha,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Duże, wygodne gwiazdki do oceny dnia
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                final filled = starIndex <= dayRating.clamp(0, 5);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onRate(starIndex),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        size: 38,
                        color: filled
                            ? AppTheme.greenMatcha
                            : AppTheme.surfaceBorder,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _ratingLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dayRating > 0
                    ? AppTheme.textLight
                    : AppTheme.textMuted.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayProgressSummaryCard extends StatelessWidget {
  const _DayProgressSummaryCard({required this.state});

  final DailyHistoryState state;

  @override
  Widget build(BuildContext context) {
    final minutes = (state.totalSecondsOnDay / 60).round();
    final avgStars = state.averageSentenceStars > 0
        ? '${state.averageSentenceStars.toStringAsFixed(1)} ★'
        : '—';

    return Row(
      children: [
        Expanded(
          child: _StatMiniTile(
            label: 'POWTÓRZENIA',
            value: '${state.totalRepsOnDay}',
            icon: Icons.repeat_rounded,
            iconColor: AppTheme.sakuraPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMiniTile(
            label: 'OCENIONE ZDANIA',
            value: '${state.ratedSentencesCount}',
            icon: Icons.checklist_rounded,
            iconColor: AppTheme.greenMatcha,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMiniTile(
            label: 'ŚR. GWIAZDEK',
            value: avgStars,
            icon: Icons.star_half_rounded,
            iconColor: AppTheme.yellowPrompt,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatMiniTile(
            label: 'CZAS',
            value: '$minutes min',
            icon: Icons.schedule_rounded,
            iconColor: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _StatMiniTile extends StatelessWidget {
  const _StatMiniTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyNoteCard extends StatelessWidget {
  const _DailyNoteCard({
    required this.controller,
    required this.isSaving,
    required this.isSaved,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool isSaving;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: AppTheme.sakuraPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'NOTATKA Z DNIA',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (isSaved)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppTheme.greenMatcha,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Zapisano',
                      style: TextStyle(
                        color: AppTheme.greenMatcha,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 13,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Zapisz swoje spostrzeżenia z dzisiejszego treningu, trudne słówka, zmęczenie szczęki lub sukcesy...',
              hintStyle: TextStyle(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              filled: true,
              fillColor: AppTheme.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.sakuraPrimary),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.surfaceElevated,
                foregroundColor: AppTheme.textLight,
                side: const BorderSide(color: AppTheme.surfaceBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.sakuraPrimary,
                      ),
                    )
                  : const Icon(
                      Icons.save_outlined,
                      size: 16,
                      color: AppTheme.sakuraPrimary,
                    ),
              label: Text(
                isSaving ? 'Zapisywanie...' : 'Zapisz notatkę',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenceEntriesHeader extends StatelessWidget {
  const _SentenceEntriesHeader({
    required this.totalCount,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final int totalCount;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final filters = ['Wszystkie', 'Ocenione ★', 'Shadowing', 'Recall'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'HISTORIA ZDAŃ I OCEN',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: Text(
                '$totalCount',
                style: const TextStyle(
                  color: AppTheme.sakuraPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              final isSelected = activeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.bgDark
                          : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.sakuraPrimary,
                  backgroundColor: AppTheme.surface,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.sakuraPrimary
                        : AppTheme.surfaceBorder,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  onSelected: (_) => onFilterChanged(filter),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SentenceLogCard extends StatelessWidget {
  const _SentenceLogCard({required this.entry});

  final DailySentenceEntry entry;

  @override
  Widget build(BuildContext context) {
    final isRecall = (entry.mode ?? '').toLowerCase().contains('recall');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target text (Kanji / sentence statement)
          Text(
            entry.targetText,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          // Polish translation / source text
          Text(
            entry.sourceText,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Mode badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isRecall
                      ? AppTheme.greenMatcha.withValues(alpha: 0.12)
                      : AppTheme.sakuraPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isRecall
                        ? AppTheme.greenMatcha.withValues(alpha: 0.4)
                        : AppTheme.sakuraPrimary.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  entry.mode ?? (isRecall ? 'Active Recall' : 'Shadowing'),
                  style: TextStyle(
                    color: isRecall
                        ? AppTheme.greenMatcha
                        : AppTheme.sakuraPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Repetitions on this day
              if (entry.reps > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.repeat_rounded,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.reps} powt.',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              // Stars given to this statement
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = (i + 1) <= entry.stars.clamp(0, 5);
                  return Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: filled
                        ? AppTheme.greenMatcha
                        : AppTheme.surfaceBorder,
                  );
                }),
              ),
              if (entry.stars > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${entry.stars}★',
                  style: const TextStyle(
                    color: AppTheme.greenMatcha,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({
    required this.isFiltered,
    required this.hasDataOnOtherDays,
  });

  final bool isFiltered;
  final bool hasDataOnOtherDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered
                ? Icons.filter_alt_off_rounded
                : Icons.event_note_outlined,
            size: 40,
            color: AppTheme.textMuted.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            isFiltered
                ? 'Brak zdań dla wybranego filtra'
                : 'Brak przećwiczonych zdań w tym dniu',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Zmień filtr na "Wszystkie", aby zobaczyć wszystkie wpisy.'
                : 'Rozpocznij powtórzenia na wybranej wyspie językowej, a Twoje oceny i liczba powtórzeń pojawią się tutaj automatycznie.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysTimelineSelector extends StatelessWidget {
  const _DaysTimelineSelector({
    required this.currentDateKey,
    required this.dates,
    required this.onSelectDateKey,
  });

  final String currentDateKey;
  final List<String> dates;
  final ValueChanged<String> onSelectDateKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DNI Z HISTORIĄ TRENINGU',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dates.map((dateKey) {
              final isCurrent = dateKey == currentDateKey;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    dateKey,
                    style: TextStyle(
                      color: isCurrent
                          ? AppTheme.sakuraPrimary
                          : AppTheme.textLight,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: isCurrent
                      ? AppTheme.surfaceElevated
                      : AppTheme.surface,
                  side: BorderSide(
                    color: isCurrent
                        ? AppTheme.sakuraPrimary
                        : AppTheme.surfaceBorder,
                  ),
                  onPressed: () => onSelectDateKey(dateKey),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
