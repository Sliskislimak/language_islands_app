import 'package:flutter/material.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

class PhilosophyScreen extends StatelessWidget {
  const PhilosophyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: const Text(
          'Filozofia metody',
          style: TextStyle(color: AppTheme.textLight, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: const [
          _PhilosophySection(
            title: 'Cel',
            body:
                'Narzędzie do powtarzalnego treningu mowy i słuchu — bez grywalizacji, '
                'odznak i sztucznej motywacji. Liczy się wolumen sensownych powtórek.',
          ),
          SizedBox(height: 12),
          _PhilosophySection(
            title: 'Shadowing (Comprehension)',
            body:
                'Jedyny dźwięk to język docelowy. Odtwarzasz sekwencję zdań, powtarzasz na głos, '
                'nie analizujesz gramatyki w locie. Gwiazdki z tego trybu budują wyłącznie poziom '
                'Comprehension.',
          ),
          SizedBox(height: 12),
          _PhilosophySection(
            title: 'Active Recall (Speaking)',
            body:
                'Widzisz prompt w języku ojczystym, tłumaczysz z pamięci na głos, dopiero potem '
                'odsłaniasz język docelowy i weryfikujesz wymowę audio. Pięć gwiazdek oznacza '
                'płynną wypowiedź bez namysłu — nie ciche czytanie z ekranu.',
          ),
          SizedBox(height: 12),
          _PhilosophySection(
            title: 'Wyspy językowe',
            body:
                'Treść pochodzi wyłącznie z Twoich importów (JSON/CSV). Brak wbudowanych słowników '
                'i mocków — budujesz własne kolekcje z tagami i poziomem CEFR.',
          ),
          SizedBox(height: 12),
          _PhilosophySection(
            title: 'Dwa rejestry postępu',
            body:
                'Comprehension i Speaking to niezależne ścieżki. Oceny z Shadowing nie przesuwają '
                'poziomu mowy i odwrotnie. Zmęczenie szczęki i oddechu to sygnał, że sesja była realna.',
          ),
        ],
      ),
    );
  }
}

class _PhilosophySection extends StatelessWidget {
  const _PhilosophySection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

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
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: AppTheme.textLight,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
