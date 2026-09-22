import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/collections/presentation/import_collection_dialog.dart';
import 'package:language_islands_app/features/info/presentation/screens/philosophy_screen.dart';
import 'package:language_islands_app/features/info/presentation/screens/study_plans_screen.dart';
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
            tooltip: 'Biegłość',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MetricsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.insights_rounded),
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
              }
            },
            itemBuilder: (context) => [
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
        error: (error, _) => _MessagePanel(
          title: 'Błąd wczytywania',
          message: error.toString(),
        ),
        data: (collections) {
          if (collections.isEmpty) {
            return _MessagePanel(
              title: 'Brak kolekcji',
              message:
                  'Zaimportuj plik JSON z wyspą językową (przycisk w pasku narzędzi).',
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
              return _CollectionTile(collection: collection);
            },
          );
        },
      ),
    );
  }

  Future<void> _openImportDialog(BuildContext context, WidgetRef ref) async {
    final jsonStr = await showDialog<String>(
      context: context,
      builder: (context) => const ImportCollectionDialog(),
    );
    if (jsonStr == null || jsonStr.trim().isEmpty) return;
    if (!context.mounted) return;

    try {
      await ref
          .read(collectionsControllerProvider.notifier)
          .importFromJson(jsonStr);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kolekcja zaimportowana.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import nieudany: $error')),
        );
      }
    }
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.collection});

  final SentenceCollection collection;

  @override
  Widget build(BuildContext context) {
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
              Text(
                collection.title,
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _ChipLabel(text: collection.cefrLevel),
                  const SizedBox(width: 8),
                  Text(
                    '${collection.sentences.length} zdań',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
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

enum _CollectionsMenuAction { philosophy, importJson }

class _PopupMenuRow extends StatelessWidget {
  const _PopupMenuRow({
    required this.icon,
    required this.label,
  });

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
