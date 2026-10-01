import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/presentation/edit_collection_json_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/import_collection_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/language_management_dialog.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/info/presentation/screens/philosophy_screen.dart';
import 'package:language_islands_app/features/info/presentation/screens/study_plans_screen.dart';
import 'package:language_islands_app/features/metrics/presentation/screens/daily_history_screen.dart';
import 'package:language_islands_app/features/metrics/presentation/screens/metrics_screen.dart';
import 'package:language_islands_app/features/practice/presentation/practice_session_screen.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text(
          'Language Islands',
          style: TextStyle(color: AppTheme.textLight, fontSize: 18),
        ),
        backgroundColor: AppTheme.bgDark,
        actions: [
          IconButton(
            tooltip: 'Twój Plan i Harmonogram Dnia',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StudyPlansScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.sakuraPrimary,
            ),
          ),
          IconButton(
            tooltip: 'Historia i Dziennik Dnia',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DailyHistoryScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.auto_stories_rounded,
              color: AppTheme.textLight,
            ),
          ),
          IconButton(
            tooltip: 'Biegłość',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MetricsScreen()),
              );
            },
            icon: const Icon(Icons.insights_rounded),
          ),
          IconButton(
            tooltip: 'Zarządzanie językami w aplikacji',
            onPressed: () => showLanguageManagementDialog(context),
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textLight,
            ),
          ),
          PopupMenuButton<_CollectionsMenuAction>(
            tooltip: 'Więcej',
            icon: const Icon(Icons.more_vert_rounded),
            color: AppTheme.surfaceElevated,
            onSelected: (action) {
              switch (action) {
                case _CollectionsMenuAction.philosophy:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PhilosophyScreen(),
                    ),
                  );
                case _CollectionsMenuAction.importJson:
                  _openImportDialog(context, ref);
                case _CollectionsMenuAction.languageManagement:
                  showLanguageManagementDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _CollectionsMenuAction.languageManagement,
                child: _PopupMenuRow(
                  icon: Icons.language_rounded,
                  label: 'Zarządzanie językami',
                ),
              ),
              const PopupMenuItem(
                value: _CollectionsMenuAction.philosophy,
                child: _PopupMenuRow(
                  icon: Icons.menu_book_rounded,
                  label: 'Filozofia Metody',
                ),
              ),
              const PopupMenuItem(
                value: _CollectionsMenuAction.importJson,
                child: _PopupMenuRow(
                  icon: Icons.upload_file_outlined,
                  label: 'Import JSON',
                ),
              ),
            ],
          ),
        ],
      ),
      body: collectionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.sakuraPrimary),
        ),
        error: (error, _) =>
            _MessagePanel(title: 'Błąd wczytywania', message: error.toString()),
        data: (collections) {
          if (collections.isEmpty) {
            return _MessagePanel(
              title: 'Brak kolekcji',
              message: 'Zaimportuj plik JSON z wyspą językową (przycisk w pasku narzędzi).',
              actionLabel: 'Import JSON',
              onAction: () => _openImportDialog(context, ref),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: collections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final collection = collections[index];
              return _CollectionTile(
                collection: collection,
                onEditJson: () => _openEditJsonDialog(context, ref, collection),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditJsonDialog(
    BuildContext context,
    WidgetRef ref,
    SentenceCollection collection,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => EditCollectionJsonDialog(collection: collection),
    );
  }

  Future<void> _openImportDialog(BuildContext context, WidgetRef ref) async {
    final request = await showDialog<ImportCollectionRequest>(
      context: context,
      builder: (context) => const ImportCollectionDialog(),
    );
    if (request == null || request.jsonStr.trim().isEmpty) return;
    if (!context.mounted) return;

    try {
      await ref
          .read(collectionsControllerProvider.notifier)
          .importFromJson(request.jsonStr, title: request.title);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kolekcja zaimportowana.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import nieudany: $error')));
      }
    }
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({
    required this.collection,
    required this.onEditJson,
  });

  final SentenceCollection collection;
  final VoidCallback onEditJson;

  @override
  Widget build(BuildContext context) {
    final stats = collection.stats;
    final statsLabel =
        '${stats.sentenceCount} zdań'
        ' · ${stats.newCount} nowe'
        ' · ${stats.dueCount} do powtórki'
        ' · ${stats.masteredCount} opanowane'
        ' · ${stats.totalReps} powtórzeń';

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PracticeSessionScreen(collection: collection),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.surfaceBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.title,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          statsLabel,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Prawy górny róg wyspy: przyciski kopiowania i edycji JSON
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Kopiuj JSON wyspy',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text: collection.toJsonString(pretty: true),
                                ),
                              );
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Skopiowano JSON wyspy "${collection.title}" do schowka!',
                                  ),
                                  backgroundColor: AppTheme.surfaceElevated,
                                  duration: const Duration(milliseconds: 1400),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Edytuj JSON wyspy (wklej nowy)',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: onEditJson,
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 22,
                                color: AppTheme.sakuraPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _ChipLabel(text: collection.cefrLevel),
                  if (collection.translationLanguage != null) ...[
                    const SizedBox(width: 6),
                    _ChipLabel(
                      text:
                          '${AppLanguage.fromCode(collection.translationLanguage)?.flagEmoji ?? '🌐'} ${AppLanguage.fromCode(collection.translationLanguage)?.name ?? collection.translationLanguage!.toUpperCase()}',
                    ),
                  ],
                ],
              ),
              if (collection.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final tag in collection.tags)
                      _ChipLabel(text: tag, muted: true),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.text, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted ? AppTheme.bgDark : AppTheme.surfaceBorder,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: muted ? AppTheme.textMuted : AppTheme.sakuraPrimary,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(color: AppTheme.yellowPrompt),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _CollectionsMenuAction { philosophy, importJson, languageManagement }

class _PopupMenuRow extends StatelessWidget {
  const _PopupMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
        ),
      ],
    );
  }
}
