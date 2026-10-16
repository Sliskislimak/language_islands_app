import 'package:flutter/material.dart';
import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

class KanjiDetailsDialog extends StatelessWidget {
  const KanjiDetailsDialog({super.key, required this.entry});

  final KanjiEntry entry;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nagłówek z zamykaniem
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgDark,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.surfaceBorder),
                    ),
                    child: Text(
                      'JLPT ${entry.jlptLevel}',
                      style: const TextStyle(
                        color: AppTheme.sakuraPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (entry.strokeCount != null)
                    Text(
                      '${entry.strokeCount} kresek',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Duży znak Kanji i znaczenia
              Center(
                child: Column(
                  children: [
                    Text(
                      entry.kanji,
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.sakuraPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.meaningsDisplay,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.surfaceBorder),
              const SizedBox(height: 8),

              // Czytania
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ReadingRow(
                        title: "On'yomi (音読み - chińskie):",
                        reading: entry.onyomiDisplay,
                        accentColor: AppTheme.sakuraAccent,
                      ),
                      const SizedBox(height: 10),
                      _ReadingRow(
                        title: "Kun'yomi (訓読み - japońskie):",
                        reading: entry.kunyomiDisplay,
                        accentColor: AppTheme.yellowPrompt,
                      ),
                      const SizedBox(height: 16),

                      // Przykładowe słówka
                      if (entry.examples.isNotEmpty) ...[
                        const Text(
                          'Przykładowe słownictwo:',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final ex in entry.examples)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDark,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.surfaceBorder),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  ex.word,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.sakuraPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  ex.reading,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  ex.meaning,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceElevated,
                  foregroundColor: AppTheme.textLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zamknij'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({
    required this.title,
    required this.reading,
    required this.accentColor,
  });

  final String title;
  final String reading;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.bgDark,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          child: Text(
            reading,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
