import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/metrics/providers/metrics_controller.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

enum _MetricsRange { today, allTime }

class SessionMetricsSidebar extends ConsumerStatefulWidget {
  const SessionMetricsSidebar({super.key});

  @override
  ConsumerState<SessionMetricsSidebar> createState() =>
      _SessionMetricsSidebarState();
}

class _SessionMetricsSidebarState extends ConsumerState<SessionMetricsSidebar> {
  _MetricsRange _range = _MetricsRange.today;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(practiceSessionProvider);
    if (session == null) return const SizedBox.shrink();

    final metricsAsync = ref.watch(metricsControllerProvider);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SegmentedRangeToggle(
            range: _range,
            onChanged: (value) => setState(() => _range = value),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: metricsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.sakuraPrimary,
                ),
              ),
              error: (error, _) => _SidebarError(message: error.toString()),
              data: (metrics) {
                final isToday = _range == _MetricsRange.today;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MetricsGrid(
                        practiced: isToday
                            ? metrics.todayPracticedCount
                            : metrics.practicedSentencesCount,
                        reps: isToday ? metrics.todayReps : metrics.totalReps,
                        mastered: isToday
                            ? metrics.todayMasteredSpeakingCount
                            : metrics.masteredSpeakingCount,
                      ),
                      const SizedBox(height: 20),
                      const _MethodTldrBlock(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedRangeToggle extends StatelessWidget {
  const _SegmentedRangeToggle({
    required this.range,
    required this.onChanged,
  });

  final _MetricsRange range;
  final ValueChanged<_MetricsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SegmentChip(
            label: 'Today',
            selected: range == _MetricsRange.today,
            onTap: () => onChanged(_MetricsRange.today),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SegmentChip(
            label: 'All-time',
            selected: range == _MetricsRange.allTime,
            onTap: () => onChanged(_MetricsRange.allTime),
          ),
        ),
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
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
      color: selected ? AppTheme.surfaceElevated : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppTheme.sakuraMuted : AppTheme.surfaceBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.textLight : AppTheme.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.practiced,
    required this.reps,
    required this.mastered,
  });

  final int practiced;
  final int reps;
  final int mastered;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'PRACTICED',
                value: practiced,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'REPS',
                value: reps,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _MetricTile(
          label: 'MASTERED',
          value: mastered,
          fullWidth: true,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String label;
  final int value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTldrBlock extends StatelessWidget {
  const _MethodTldrBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Max Results, Minimum Time',
          style: TextStyle(
            color: AppTheme.textLight,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Shadow: Słuchaj, pauzuj i powtarzaj na głos aż do płynności.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Recall: Tłumacz z pamięci na głos z natychmiastową weryfikacją.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'MASTERED liczy wyłącznie zdania z 5★ w Active Recall.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Mięśnie mowy: Wskaźnikiem dobrego treningu jest fizyczne zmęczenie aparatu mowy.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SidebarError extends StatelessWidget {
  const _SidebarError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.yellowPrompt,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
