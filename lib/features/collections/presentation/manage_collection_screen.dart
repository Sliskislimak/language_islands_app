import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/presentation/edit_collection_json_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/sentence_edit_dialog.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/practice/presentation/practice_session_screen.dart';

class ManageCollectionScreen extends ConsumerStatefulWidget {
  const ManageCollectionScreen({
    super.key,
    required this.collectionId,
    required this.initialCollection,
  });

  final String collectionId;
  final SentenceCollection initialCollection;

  @override
  ConsumerState<ManageCollectionScreen> createState() =>
      _ManageCollectionScreenState();
}

class _ManageCollectionScreenState
    extends ConsumerState<ManageCollectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddSentenceDialog(SentenceCollection collection) async {
    final result = await showSentenceEditDialog(
      context,
      collectionId: collection.id,
      targetLanguageCode: collection.targetLanguage,
      onSave: (newSentence) async {
        await ref
            .read(collectionsControllerProvider.notifier)
            .addSentence(collection.id, newSentence);
      },
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.greenMatcha,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Dodano nową fiszkę: "${result.targetText}"'),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEditSentenceDialog(
    SentenceCollection collection,
    Sentence sentence,
  ) async {
    final result = await showSentenceEditDialog(
      context,
      collectionId: collection.id,
      sentence: sentence,
      targetLanguageCode: collection.targetLanguage,
      onSave: (updated) async {
        await ref
            .read(collectionsControllerProvider.notifier)
            .updateSentence(collection.id, updated);
      },
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.greenMatcha,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Zaktualizowano fiszkę: "${result.targetText}"'),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeleteSentence(
    SentenceCollection collection,
    Sentence sentence,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Usunąć tę fiszkę?',
          style: TextStyle(color: AppTheme.textLight, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sentence.targetText,
              style: const TextStyle(
                color: AppTheme.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sentence.sourceText,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tej operacji nie można cofnąć.',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(collectionsControllerProvider.notifier)
          .deleteSentence(collection.id, sentence.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usunięto fiszkę ze zbioru.'),
            backgroundColor: AppTheme.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editCollectionTitle(SentenceCollection collection) async {
    final controller = TextEditingController(text: collection.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Zmień nazwę grupy fiszek',
          style: TextStyle(color: AppTheme.textLight, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textLight),
          decoration: const InputDecoration(
            labelText: 'Nazwa grupy / wyspy',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.sakuraPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty && mounted) {
      await ref
          .read(collectionsControllerProvider.notifier)
          .updateCollectionTitle(collection.id, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionsAsync = ref.watch(collectionsControllerProvider);

    final collection =
        collectionsAsync.valueOrNull?.firstWhere(
          (c) => c.id == widget.collectionId,
          orElse: () => widget.initialCollection,
        ) ??
        widget.initialCollection;

    final targetLang = collection.targetLanguage != null
        ? AppLanguage.fromCode(collection.targetLanguage!)
        : null;

    final allSentences = collection.sentences;
    final filteredSentences = _searchFilter.isEmpty
        ? allSentences
        : allSentences.where((s) {
            final q = _searchFilter.toLowerCase();
            return s.targetText.toLowerCase().contains(q) ||
                s.sourceText.toLowerCase().contains(q) ||
                (s.phoneticReading?.toLowerCase().contains(q) ?? false) ||
                (s.katakana?.toLowerCase().contains(q) ?? false) ||
                (s.notes?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    collection.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppTheme.sakuraPrimary,
                  ),
                  tooltip: 'Zmień nazwę zbioru',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _editCollectionTitle(collection),
                ),
              ],
            ),
            Text(
              'Tryb edycji fiszek • ${collection.sentences.length} fiszek',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.play_circle_fill_rounded,
              color: AppTheme.sakuraPrimary,
            ),
            tooltip: 'Rozpocznij naukę tej grupy',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeSessionScreen(collection: collection),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Więcej opcji grupy',
            icon: const Icon(Icons.more_vert_rounded),
            color: AppTheme.surfaceElevated,
            onSelected: (value) async {
              if (value == 'add') {
                _openAddSentenceDialog(collection);
              } else if (value == 'editJson') {
                showDialog<void>(
                  context: context,
                  builder: (context) =>
                      EditCollectionJsonDialog(collection: collection),
                );
              } else if (value == 'copyJson') {
                Clipboard.setData(
                  ClipboardData(text: collection.toJsonString(pretty: true)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Skopiowano JSON wyspy do schowka.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: AppTheme.sakuraPrimary,
                    ),
                    SizedBox(width: 10),
                    Text('Dodaj nową fiszkę'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copyJson',
                child: Row(
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 20,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(width: 10),
                    Text('Kopiuj JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'editJson',
                child: Row(
                  children: [
                    Icon(
                      Icons.code_rounded,
                      size: 20,
                      color: AppTheme.textMuted,
                    ),
                    SizedBox(width: 10),
                    Text('Edytuj surowy JSON'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.sakuraPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Dodaj fiszkę',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        tooltip: 'Dodaj nową pojedynczą fiszkę do tego zbioru',
        onPressed: () => _openAddSentenceDialog(collection),
      ),
      body: Column(
        children: [
          // Header search and quick add bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchFilter = val.trim();
                      });
                    },
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Szukaj w tym zbiorze...',
                      hintStyle: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                      suffixIcon: _searchFilter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchFilter = '';
                                });
                              },
                            )
                          : null,
                      isDense: true,
                      filled: true,
                      fillColor: AppTheme.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () => _openAddSentenceDialog(collection),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.sakuraPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Dodaj',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Stats bar: Total cards, recorded voice stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceElevated,
              border: Border(bottom: BorderSide(color: AppTheme.surfaceBorder)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  size: 15,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  'Fiszek: ${allSentences.length}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 1,
                  height: 12,
                  color: AppTheme.surfaceBorder,
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.mic_rounded,
                  size: 15,
                  color: allSentences.any((s) => s.hasCustomTargetAudio || s.hasCustomTranslationAudio)
                      ? AppTheme.greenMatcha
                      : AppTheme.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  'Nagrania głosowe: ${allSentences.where((s) => s.hasCustomTargetAudio || s.hasCustomTranslationAudio).length}/${allSentences.length}',
                  style: TextStyle(
                    color: allSentences.any((s) => s.hasCustomTargetAudio || s.hasCustomTranslationAudio)
                        ? AppTheme.textLight
                        : AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Main list or empty state
          Expanded(
            child: filteredSentences.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchFilter.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.style_outlined,
                            size: 48,
                            color: AppTheme.textMuted.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchFilter.isNotEmpty
                                ? 'Brak fiszek pasujących do filtra "$_searchFilter"'
                                : 'Ten zbiór nie ma jeszcze żadnych fiszek.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _openAddSentenceDialog(collection),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.sakuraPrimary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Dodaj pierwszą fiszkę'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _searchFilter.isNotEmpty
                // When searching, display regular ListView
                ? ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 14,
                      bottom: 84,
                    ),
                    itemCount: filteredSentences.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final sentence = filteredSentences[index];
                      final originalIndex = allSentences.indexOf(sentence);
                      return _SentenceRowTile(
                        key: ValueKey(sentence.id),
                        sentence: sentence,
                        index: originalIndex + 1,
                        targetLanguageFlag: targetLang?.flagEmoji,
                        onEdit: () =>
                            _openEditSentenceDialog(collection, sentence),
                        onDelete: () =>
                            _confirmDeleteSentence(collection, sentence),
                        showDragHandle: false,
                      );
                    },
                  )
                // When not searching, allow reordering
                : ReorderableListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 14,
                      bottom: 84,
                    ),
                    itemCount: allSentences.length,
                    // ignore: deprecated_member_use
                    onReorder: (oldIndex, newIndex) {
                      ref
                          .read(collectionsControllerProvider.notifier)
                          .reorderSentences(collection.id, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final sentence = allSentences[index];
                      return _SentenceRowTile(
                        key: ValueKey(sentence.id),
                        sentence: sentence,
                        index: index + 1,
                        targetLanguageFlag: targetLang?.flagEmoji,
                        onEdit: () =>
                            _openEditSentenceDialog(collection, sentence),
                        onDelete: () =>
                            _confirmDeleteSentence(collection, sentence),
                        showDragHandle: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SentenceRowTile extends StatelessWidget {
  const _SentenceRowTile({
    super.key,
    required this.sentence,
    required this.index,
    this.targetLanguageFlag,
    required this.onEdit,
    required this.onDelete,
    required this.showDragHandle,
  });

  final Sentence sentence;
  final int index;
  final String? targetLanguageFlag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Index chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#$index',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target sentence text
                    Text(
                      sentence.targetText,
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Phonetic reading / Katakana if present
                    if (sentence.phoneticReading != null &&
                        sentence.phoneticReading!.isNotEmpty) ...[
                      Text(
                        sentence.phoneticReading!,
                        style: const TextStyle(
                          color: AppTheme.sakuraPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    if (sentence.katakana != null &&
                        sentence.katakana!.isNotEmpty) ...[
                      Text(
                        sentence.katakana!,
                        style: const TextStyle(
                          color: AppTheme.greenMatcha,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Translation / Source text
                    Text(
                      sentence.sourceText,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),

                    // Notes badge if present
                    if (sentence.hasNotes) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.sticky_note_2_outlined,
                            size: 13,
                            color: AppTheme.sakuraPrimary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sentence.notes!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Custom voice badge if present
                    if (sentence.hasCustomTargetAudio ||
                        sentence.hasCustomTranslationAudio) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.greenMatcha
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppTheme.greenMatcha
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mic_rounded,
                                  size: 11,
                                  color: AppTheme.greenMatcha,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sentence.hasCustomTargetAudio &&
                                          sentence.hasCustomTranslationAudio
                                      ? 'Nagranie: Obustronne'
                                      : sentence.hasCustomTargetAudio
                                          ? 'Nagranie głosu'
                                          : 'Nagranie tłumaczenia',
                                  style: const TextStyle(
                                    color: AppTheme.greenMatcha,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action buttons: Edit, Delete, Reorder handle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      size: 20,
                      color: AppTheme.sakuraPrimary,
                    ),
                    tooltip: 'Edytuj tę fiszkę',
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Usuń tę fiszkę',
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (showDragHandle)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        size: 20,
                        color: AppTheme.textMuted,
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
