import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/info/presentation/screens/study_plans_screen.dart';
import 'package:language_islands_app/features/metrics/domain/level_calculator.dart';
import 'package:language_islands_app/features/metrics/presentation/screens/daily_history_screen.dart';
import 'package:language_islands_app/features/metrics/providers/metrics_controller.dart';

class MetricsScreen extends ConsumerWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(metricsControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text(
          'Biegłość',
          style: TextStyle(color: AppTheme.textLight, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Historia i Dziennik Dnia',
            icon: const Icon(
              Icons.auto_stories_rounded,
              color: AppTheme.sakuraPrimary,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DailyHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: metricsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.sakuraPrimary),
        ),
        error: (error, _) => _ErrorPanel(message: error.toString()),
        data: (metrics) => _MetricsBody(metrics: metrics),
      ),
    );
  }
}

class _MetricsBody extends StatelessWidget {
  const _MetricsBody({required this.metrics});

  final GlobalMetricsState metrics;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _LevelTrackCard(
          label: 'Comprehension Level',
          caption: '5★ wyłącznie w Shadowing',
          progress: metrics.comprehensionProgress,
          barColor: AppTheme.sakuraPrimary,
        ),
        const SizedBox(height: 12),
        _LevelTrackCard(
          label: 'Speaking Level',
          caption: '5★ wyłącznie w Active Recall — wolniejszy tor',
          progress: metrics.speakingProgress,
          barColor: AppTheme.greenMatcha,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: 'TOTAL REPS',
                value: '${metrics.totalReps}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryTile(
                label: 'ACTIVE SENTENCES',
                value: '${metrics.practicedSentencesCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SummaryTile(
          label: 'ACTIVE WORDS',
          value: '${metrics.activeWordsCount}',
        ),
        const SizedBox(height: 20),
        const _MethodBlock(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DailyHistoryScreen(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: AppTheme.surfaceElevated,
            foregroundColor: AppTheme.textLight,
            side: const BorderSide(color: AppTheme.surfaceBorder),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
          icon: const Icon(
            Icons.auto_stories_rounded,
            color: AppTheme.greenMatcha,
          ),
          label: const Text(
            'Dziennik Postępów i Historia Dni',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StudyPlansScreen(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: AppTheme.surfaceElevated,
            foregroundColor: AppTheme.textLight,
            side: const BorderSide(color: AppTheme.surfaceBorder),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
          icon: const Icon(
            Icons.calendar_today_rounded,
            color: AppTheme.sakuraPrimary,
          ),
          label: const Text(
            'Otwórz Twój Harmonogram Dnia (90 Dni)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _LevelTrackCard extends StatelessWidget {
  const _LevelTrackCard({
    required this.label,
    required this.caption,
    required this.progress,
    required this.barColor,
  });

  final String label;
  final String caption;
  final LevelProgress progress;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.progress.clamp(0.0, 1.0);
    final nextLabel = progress.currentLevel == progress.nextLevel
        ? progress.currentLevel
        : '${progress.currentLevel}  →  ${progress.nextLevel}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                progress.currentLevel,
                style: TextStyle(
                  color: barColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nextLabel,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FractionBar(fraction: fraction, color: barColor),
          const SizedBox(height: 10),
          Text(
            '${progress.masteredCount} / ${progress.nextLevelTarget} zdań',
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FractionBar extends StatelessWidget {
  const _FractionBar({
    required this.fraction,
    required this.color,
  });

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * fraction;
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.bgDark,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          alignment: Alignment.centerLeft,
          child: Container(
            width: width,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
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
            value,
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

class _MethodBlock extends StatelessWidget {
  const _MethodBlock();

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'METODA',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Comprehension i Speaking to dwa niezależne rejestry. '
            'Gwiazdki z Shadowing nie przesuwają poziomu mowy.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Pięć gwiazdek w Recall oznacza płynną wypowiedź bez namysłu — '
            'nie przybliżenie i nie ciche odczytanie z ekranu.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'To trening mięśni aparatu mowy. Zmęczenie szczęki, języka '
            'i oddechu jest twardym wskaźnikiem, że sesja była realna.',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Błąd wczytywania metryk',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
