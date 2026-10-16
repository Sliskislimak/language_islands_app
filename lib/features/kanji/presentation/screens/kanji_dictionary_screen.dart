import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/kanji/presentation/dialogs/kanji_details_dialog.dart';
import 'package:language_islands_app/features/kanji/providers/kanji_controller.dart';

class KanjiDictionaryScreen extends ConsumerStatefulWidget {
  const KanjiDictionaryScreen({super.key});

  @override
  ConsumerState<KanjiDictionaryScreen> createState() => _KanjiDictionaryScreenState();
}

class _KanjiDictionaryScreenState extends ConsumerState<KanjiDictionaryScreen> {
  final _searchController = TextEditingController();
  String _selectedLevel = 'ALL';
  final Set<String> _selectedKanji = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(kanjiRepositoryProvider);
    final studyListAsync = ref.watch(kanjiControllerProvider);
    final studyKanjiSet = {
      for (final e in (studyListAsync.valueOrNull ?? const [])) e.kanji,
    };

    final dictionaryItems = repo.searchDictionary(
      query: _searchController.text,
      jlptLevel: _selectedLevel == 'ALL' ? null : _selectedLevel,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text(
          'Słownik Kanji',
          style: TextStyle(color: AppTheme.textLight, fontSize: 18),
        ),
        backgroundColor: AppTheme.bgDark,
        actions: [
          if (_selectedKanji.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.sakuraPrimary,
                ),
                onPressed: () => _addSelected(dictionaryItems),
                icon: const Icon(Icons.add_task_rounded, size: 18),
                label: Text(
                  'Dodaj (${_selectedKanji.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Pasek wyszukiwania i filtry
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: AppTheme.textLight),
                  decoration: InputDecoration(
                    hintText: 'Szukaj znaku, znaczenia (np. słońce) lub czytania...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.sakuraPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filtry poziomu JLPT
                Row(
                  children: [
                    _filterChip(label: 'Wszystkie', value: 'ALL'),
                    const SizedBox(width: 8),
                    _filterChip(label: 'JLPT N5', value: 'N5'),
                    const Spacer(),
                    Text(
                      'Wyniki: ${dictionaryItems.length}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista znaków
          Expanded(
            child: dictionaryItems.isEmpty
                ? const Center(
                    child: Text(
                      'Brak znaków spełniających kryteria.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: dictionaryItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = dictionaryItems[index];
                      final isAlreadyInStudy = studyKanjiSet.contains(item.kanji);
                      final isChecked = _selectedKanji.contains(item.kanji);

                      return Material(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            if (isAlreadyInStudy) {
                              _showDetails(item);
                            } else {
                              setState(() {
                                if (isChecked) {
                                  _selectedKanji.remove(item.kanji);
                                } else {
                                  _selectedKanji.add(item.kanji);
                                }
                              });
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isChecked
                                    ? AppTheme.sakuraPrimary
                                    : (isAlreadyInStudy
                                        ? AppTheme.greenMatcha.withValues(alpha: 0.4)
                                        : AppTheme.surfaceBorder),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                // Checkbox lub wskaźnik stanu
                                if (isAlreadyInStudy)
                                  const Tooltip(
                                    message: 'Ten znak jest już na liście nauki',
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.greenMatcha,
                                      size: 24,
                                    ),
                                  )
                                else
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: AppTheme.sakuraPrimary,
                                    checkColor: AppTheme.bgDark,
                                    side: const BorderSide(color: AppTheme.surfaceBorder),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedKanji.add(item.kanji);
                                        } else {
                                          _selectedKanji.remove(item.kanji);
                                        }
                                      });
                                    },
                                  ),
                                const SizedBox(width: 8),

                                // Znak Kanji
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppTheme.bgDark,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    item.kanji,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.sakuraPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Dane tekstowe
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.meaningsDisplay,
                                        style: const TextStyle(
                                          color: AppTheme.textLight,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'ON: ${item.onyomiDisplay} · KUN: ${item.kunyomiDisplay}',
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Przycisk info
                                IconButton(
                                  icon: const Icon(
                                    Icons.info_outline_rounded,
                                    size: 20,
                                    color: AppTheme.textMuted,
                                  ),
                                  onPressed: () => _showDetails(item),
                                ),

                                // Szybkie dodanie pojedynczego znaku
                                if (!isAlreadyInStudy)
                                  IconButton(
                                    tooltip: 'Dodaj od razu do nauki',
                                    icon: const Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: AppTheme.sakuraPrimary,
                                    ),
                                    onPressed: () => _addSingle(item),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: _selectedKanji.isNotEmpty
          ? Container(
              color: AppTheme.surfaceElevated,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                child: Row(
                  children: [
                    Text(
                      'Zaznaczono: ${_selectedKanji.length}',
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => setState(() => _selectedKanji.clear()),
                      child: const Text('Odznacz', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sakuraPrimary,
                        foregroundColor: AppTheme.bgDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _addSelected(dictionaryItems),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Dodaj do nauki', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _filterChip({required String label, required String value}) {
    final isSelected = _selectedLevel == value;
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
        setState(() => _selectedLevel = value);
      },
    );
  }

  void _showDetails(KanjiEntry item) {
    showDialog<void>(
      context: context,
      builder: (_) => KanjiDetailsDialog(entry: item),
    );
  }

  Future<void> _addSingle(KanjiEntry item) async {
    await ref.read(kanjiControllerProvider.notifier).addKanji([item]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dodano znak ${item.kanji} do nauki!'),
        backgroundColor: AppTheme.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addSelected(List<KanjiEntry> dictionary) async {
    final toAdd = dictionary.where((e) => _selectedKanji.contains(e.kanji)).toList();
    if (toAdd.isEmpty) return;

    await ref.read(kanjiControllerProvider.notifier).addKanji(toAdd);
    setState(() => _selectedKanji.clear());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dodano ${toAdd.length} znaków do listy nauki!'),
        backgroundColor: AppTheme.surfaceElevated,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
