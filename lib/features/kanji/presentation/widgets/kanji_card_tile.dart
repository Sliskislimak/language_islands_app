import 'package:flutter/material.dart';
import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

class KanjiCardTile extends StatelessWidget {
  const KanjiCardTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onDelete,
    required this.onRatingChanged,
  });

  final KanjiEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: entry.isMastered
                  ? AppTheme.greenMatcha.withValues(alpha: 0.5)
                  : AppTheme.surfaceBorder,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kolumna 1: Duży znak Kanji + Badge poziomu
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: entry.isMastered
                        ? AppTheme.greenMatcha.withValues(alpha: 0.3)
                        : AppTheme.surfaceBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.kanji,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.sakuraPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Kolumna 2: Szczegóły (Znaczenia, czytania On/Kun, przykłady)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.meaningsDisplay,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _LevelBadge(level: entry.jlptLevel),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Czytania: On & Kun
                    RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, height: 1.3),
                        children: [
                          if (entry.onyomi.isNotEmpty) ...[
                            const TextSpan(
                              text: 'ON: ',
                              style: TextStyle(
                                color: AppTheme.sakuraAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: '${entry.onyomiDisplay}   ',
                              style: const TextStyle(color: AppTheme.textLight),
                            ),
                          ],
                          if (entry.kunyomi.isNotEmpty) ...[
                            const TextSpan(
                              text: 'KUN: ',
                              style: TextStyle(
                                color: AppTheme.yellowPrompt,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: entry.kunyomiDisplay,
                              style: const TextStyle(color: AppTheme.textLight),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Pasek gwiazdek (Mastery 0-5)
                    Row(
                      children: [
                        for (int i = 1; i <= 5; i++)
                          GestureDetector(
                            onTap: () => onRatingChanged(i == entry.masteryScore ? 0 : i),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Icon(
                                i <= entry.masteryScore
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 18,
                                color: i <= entry.masteryScore
                                    ? (entry.isMastered
                                        ? AppTheme.greenMatcha
                                        : AppTheme.yellowPrompt)
                                    : AppTheme.surfaceBorder,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (entry.totalReps > 0)
                          Text(
                            '${entry.totalReps} powtórzeń',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Przycisk więcej
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppTheme.textMuted),
                color: AppTheme.surfaceElevated,
                onSelected: (val) {
                  if (val == 'delete') {
                    onDelete();
                  } else if (val == 'details') {
                    onTap();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textMuted),
                        SizedBox(width: 8),
                        Text('Szczegóły znaku', style: TextStyle(color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Usuń z nauki', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Text(
        level,
        style: const TextStyle(
          color: AppTheme.sakuraPrimary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
