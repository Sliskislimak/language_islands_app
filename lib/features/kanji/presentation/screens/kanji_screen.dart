import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/kanji/presentation/dialogs/kanji_details_dialog.dart';
import 'package:language_islands_app/features/kanji/presentation/dialogs/kanji_import_dialog.dart';
import 'package:language_islands_app/features/kanji/presentation/screens/kanji_dictionary_screen.dart';
import 'package:language_islands_app/features/kanji/presentation/screens/kanji_study_session_screen.dart';
import 'package:language_islands_app/features/kanji/presentation/widgets/kanji_card_tile.dart';
import 'package:language_islands_app/features/kanji/providers/kanji_controller.dart';

class KanjiScreen extends ConsumerWidget {
  const KanjiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanjiAsync = ref.watch(kanjiControllerProvider);
    final stats = ref.watch(kanjiStatsProvider);
    final filteredList = ref.watch(filteredKanjiListProvider);
    final currentFilter = ref.watch(kanjiFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text(
          'Nauka Kanji · 漢字',
          style: TextStyle(color: AppTheme.textLight, fontSize: 18),
        ),
        backgroundColor: AppTheme.bgDark,
        actions: [
          IconButton(
            tooltip: 'Słownik Kanji (wybierz znaki)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const KanjiDictionaryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.library_books_rounded, color: AppTheme.sakuraPrimary),
          ),
          IconButton(
            tooltip: 'Wgraj listę z JSON',
            onPressed: () => _openImportDialog(context, ref),
            icon: const Icon(Icons.upload_file_rounded, color: AppTheme.textLight),
          ),
          IconButton(
            tooltip: 'Kopiuj listę Kanji (JSON)',
            onPressed: () => _copyKanjiJson(context, ref),
            icon: const Icon(Icons.copy_rounded, color: AppTheme.textMuted),
          ),
        ],
      ),
      body: kanjiAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.sakuraPrimary),
        ),
        error: (error, _) => Center(
          child: Text(
            'Błąd wczytywania: $error',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (allKanji) {
          if (allKanji.isEmpty) {
            return _buildEmptyState(context, ref);
          }

          return Column(
            children: [
              // Panel statystyk i CTA "Rozpocznij naukę"
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _buildStatsHeader(context, ref, stats, allKanji, filteredList),
              ),

              // Przełącznik filtrów (Wszystkie, W nauce, Do powtórki, Opanowane)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterTab(
                        ref: ref,
                        label: 'Wszystkie (${stats.totalCount})',
                        filter: KanjiListFilter.all,
                        isSelected: currentFilter == KanjiListFilter.all,
                      ),
                      const SizedBox(width: 8),
                      _filterTab(
                        ref: ref,
                        label: 'W nauce (${stats.learningCount})',
                        filter: KanjiListFilter.learning,
                        isSelected: currentFilter == KanjiListFilter.learning,
                      ),
                      const SizedBox(width: 8),
                      _filterTab(
                        ref: ref,
                        label: 'Nowe/Powtórka (${stats.newCount})',
                        filter: KanjiListFilter.dueOrNew,
                        isSelected: currentFilter == KanjiListFilter.dueOrNew,
                      ),
                      const SizedBox(width: 8),
                      _filterTab(
                        ref: ref,
                        label: 'Opanowane (${stats.masteredCount})',
                        filter: KanjiListFilter.mastered,
                        isSelected: currentFilter == KanjiListFilter.mastered,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Lista kart
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          'Brak znaków w tej kategorii.',
                          style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return KanjiCardTile(
                            entry: item,
                            onTap: () => _openDetailsDialog(context, item),
                            onDelete: () => _confirmDelete(context, ref, item),
                            onRatingChanged: (newScore) {
                              ref
                                  .read(kanjiControllerProvider.notifier)
                                  .updateMastery(item.kanji, newScore);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.sakuraPrimary,
        foregroundColor: AppTheme.bgDark,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const KanjiDictionaryScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Wybierz Kanji ze słownika',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatsHeader(
    BuildContext context,
    WidgetRef ref,
    KanjiStats stats,
    List<KanjiEntry> allKanji,
    List<KanjiEntry> filteredKanji,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statColumn('Wszystkie', '${stats.totalCount}', AppTheme.textLight),
              _statColumn('W nauce', '${stats.learningCount}', AppTheme.yellowPrompt),
              _statColumn('Opanowane', '${stats.masteredCount}', AppTheme.greenMatcha),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sakuraPrimary,
                foregroundColor: AppTheme.bgDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final cardsToStudy = filteredKanji.isNotEmpty ? filteredKanji : allKanji;
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => KanjiStudySessionScreen(studyCards: cardsToStudy),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(
                'Rozpocznij naukę (${filteredKanji.isNotEmpty ? filteredKanji.length : allKanji.length} kart)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _filterTab({
    required WidgetRef ref,
    required String label,
    required KanjiListFilter filter,
    required bool isSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.sakuraPrimary.withValues(alpha: 0.2),
      backgroundColor: AppTheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.sakuraPrimary : AppTheme.textMuted,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.sakuraPrimary : AppTheme.surfaceBorder,
      ),
      onSelected: (_) {
        ref.read(kanjiFilterProvider.notifier).state = filter;
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceBorder),
              ),
              child: const Center(
                child: Text(
                  '漢',
                  style: TextStyle(
                    fontSize: 40,
                    color: AppTheme.sakuraPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Brak znaków do nauki',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wybierz znaki ze słownika Kanji lub wgraj własną listę w formacie JSON.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.sakuraPrimary,
                foregroundColor: AppTheme.bgDark,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const KanjiDictionaryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.library_books_rounded),
              label: const Text('Przeglądaj Słownik Kanji', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textLight,
                side: const BorderSide(color: AppTheme.surfaceBorder),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _openImportDialog(context, ref),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Wgraj JSON z Kanji'),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailsDialog(BuildContext context, KanjiEntry entry) {
    showDialog<void>(
      context: context,
      builder: (_) => KanjiDetailsDialog(entry: entry),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, KanjiEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Usuń znak "${entry.kanji}"?'),
        content: const Text(
          'Czy na pewno chcesz usunąć ten znak z aktywnej listy nauki? Znak nadal będzie dostępny w słowniku.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(kanjiControllerProvider.notifier).removeKanji(entry.kanji);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usunięto znak ${entry.kanji} z listy nauki.'),
            backgroundColor: AppTheme.surfaceElevated,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openImportDialog(BuildContext context, WidgetRef ref) async {
    final jsonStr = await showDialog<String>(
      context: context,
      builder: (_) => const KanjiImportDialog(),
    );
    if (jsonStr == null || jsonStr.trim().isEmpty) return;
    if (!context.mounted) return;

    try {
      final count = await ref.read(kanjiControllerProvider.notifier).importFromJson(jsonStr);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pomyślnie zaimportowano $count znaków Kanji!'),
            backgroundColor: AppTheme.surfaceElevated,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd importu: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _copyKanjiJson(BuildContext context, WidgetRef ref) async {
    final jsonStr = await ref.read(kanjiControllerProvider.notifier).exportToJsonString();
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skopiowano JSON Twojej listy Kanji do schowka!'),
          backgroundColor: AppTheme.surfaceElevated,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
