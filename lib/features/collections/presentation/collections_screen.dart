import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/presentation/add_sentence_for_friend_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/edit_collection_json_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/import_collection_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/language_management_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/remote_sync_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/select_target_language_dialog.dart';
import 'package:language_islands_app/features/collections/presentation/select_translation_voice_dialog.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/collections/providers/language_settings_controller.dart';
import 'package:language_islands_app/features/collections/providers/remote_sync_controller.dart';
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
            tooltip: 'Język nauki (docelowy)',
            onPressed: () => showSelectTargetLanguageDialog(context),
            icon: const Icon(
              Icons.school_rounded,
              color: AppTheme.sakuraPrimary,
            ),
          ),
          IconButton(
            key: const ValueKey('appbar_voice_settings_button'),
            tooltip: 'Głos lektora tłumaczenia',
            onPressed: () => showSelectTranslationVoiceDialog(context),
            icon: const Icon(
              Icons.record_voice_over_rounded,
              color: AppTheme.sakuraPrimary,
            ),
          ),
          IconButton(
            tooltip: 'Zdalna baza zdań / Synchronizacja',
            onPressed: () => showRemoteSyncDialog(context),
            icon: const Icon(
              Icons.cloud_sync_rounded,
              color: AppTheme.greenMatcha,
            ),
          ),
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
              color: AppTheme.textLight,
            ),
          ),
          PopupMenuButton<_CollectionsMenuAction>(
            tooltip: 'Więcej opcji',
            icon: const Icon(Icons.more_vert_rounded),
            color: AppTheme.surfaceElevated,
            onSelected: (action) {
              switch (action) {
                case _CollectionsMenuAction.addSentenceForFriend:
                  showAddSentenceForFriendDialog(context);
                case _CollectionsMenuAction.targetLanguage:
                  showSelectTargetLanguageDialog(context);
                case _CollectionsMenuAction.translationVoice:
                  showSelectTranslationVoiceDialog(context);
                case _CollectionsMenuAction.remoteSync:
                  showRemoteSyncDialog(context);
                case _CollectionsMenuAction.importJson:
                  _openImportDialog(context, ref);
                case _CollectionsMenuAction.dailyHistory:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DailyHistoryScreen(),
                    ),
                  );
                case _CollectionsMenuAction.metrics:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MetricsScreen(),
                    ),
                  );
                case _CollectionsMenuAction.philosophy:
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PhilosophyScreen(),
                    ),
                  );
                case _CollectionsMenuAction.languageManagement:
                  showLanguageManagementDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _CollectionsMenuAction.addSentenceForFriend,
                child: _PopupMenuRow(
                  icon: Icons.send_rounded,
                  label: 'Dla Koharu / Wyślij zwrot',
                ),
              ),
              const PopupMenuItem(
                value: _CollectionsMenuAction.targetLanguage,
                child: _PopupMenuRow(
                  icon: Icons.school_rounded,
                  label: 'Język nauki (docelowy)',
                ),
              ),
              const PopupMenuItem(
                value: _CollectionsMenuAction.translationVoice,
                child: _PopupMenuRow(
                  icon: Icons.record_voice_over_rounded,
                  label: 'Głos lektora tłumaczenia',
                ),
              ),
              const PopupMenuItem(
                value: _CollectionsMenuAction.remoteSync,
                child: _PopupMenuRow(
                  icon: Icons.cloud_sync_rounded,
                  label: 'Zdalna baza zdań / Synchronizacja',
                ),
              ),
              const PopupMenuItem(
                value: _CollectionsMenuAction.importJson,
                child: _PopupMenuRow(
                  icon: Icons.upload_file_outlined,
                  label: 'Import JSON',
                ),
              ),
              const PopupMenuItem(
                value: _CollectionsMenuAction.dailyHistory,
                child: _PopupMenuRow(
                  icon: Icons.auto_stories_rounded,
                  label: 'Historia i Dziennik Dnia',
                ),
              ),
              const PopupMenuItem(
                value: _CollectionsMenuAction.metrics,
                child: _PopupMenuRow(
                  icon: Icons.insights_rounded,
                  label: 'Biegłość i statystyki',
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
                value: _CollectionsMenuAction.languageManagement,
                child: _PopupMenuRow(
                  icon: Icons.settings_outlined,
                  label: 'Odblokowane języki',
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('fab_add_sentence_for_friend'),
        backgroundColor: AppTheme.sakuraPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.send_rounded),
        label: const Text(
          'Dla Koharu / Wyślij',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        tooltip: 'Wyślij nowy zwrot dla Koharu (GitHub Gist) / こはるちゃんへフレーズを送る',
        onPressed: () => showAddSentenceForFriendDialog(context),
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

class _CollectionTile extends ConsumerWidget {
  const _CollectionTile({
    required this.collection,
    required this.onEditJson,
  });

  final SentenceCollection collection;
  final VoidCallback onEditJson;

  void _copyCollectionJson(BuildContext context) {
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
  }

  Future<void> _openSetRemoteUrlDialog(
    BuildContext context,
    WidgetRef ref,
    SentenceCollection collection,
  ) async {
    final controller =
        TextEditingController(text: collection.remoteSourceUrl ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'URL zdalnej bazy dla kolekcji',
          style: TextStyle(color: AppTheme.textLight, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wprowadź bezpośredni adres URL (REST API, GitHub Gist, JSON), z którego aplikacja ma pobierać i aktualizować zdania dla tej kolekcji:',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'https://...',
                hintStyle: TextStyle(color: AppTheme.textMuted),
                border: OutlineInputBorder(),
              ),
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
              backgroundColor: AppTheme.sakuraPrimary,
              foregroundColor: AppTheme.bgDark,
            ),
            child: const Text('Zapisz'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(collectionsControllerProvider.notifier)
          .setRemoteUrlForCollection(collection.id, controller.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zapisano URL zdalnej bazy dla kolekcji.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultLang =
        ref.watch(defaultTranslationLanguageProvider).valueOrNull ?? 'en';
    final langCode = collection.translationLanguage ?? defaultLang;
    final lang = AppLanguage.fromCode(langCode);

    final defaultTarget =
        ref.watch(defaultTargetLanguageProvider).valueOrNull ?? 'ja';
    final targetLangCode = collection.targetLanguage ?? defaultTarget;
    final targetLang = AppLanguage.fromCode(targetLangCode);

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
                        message: 'Głos lektora tłumaczenia',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => showSelectTranslationVoiceDialog(
                              context,
                              collection: collection,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(
                                Icons.record_voice_over_rounded,
                                size: 18,
                                color: AppTheme.sakuraPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Tooltip(
                        message: 'Kopiuj JSON wyspy',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _copyCollectionJson(context),
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
                      const SizedBox(width: 2),
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
                                size: 20,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      PopupMenuButton<_CollectionTileAction>(
                        tooltip: 'Więcej opcji wyspy',
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: AppTheme.textMuted,
                        ),
                        color: AppTheme.surfaceElevated,
                        onSelected: (action) async {
                          switch (action) {
                            case _CollectionTileAction.changeTargetLanguage:
                              showSelectTargetLanguageDialog(
                                context,
                                collection: collection,
                              );
                            case _CollectionTileAction.changeVoice:
                              showSelectTranslationVoiceDialog(
                                context,
                                collection: collection,
                              );
                            case _CollectionTileAction.syncRemote:
                              final res = await ref
                                  .read(remoteDatabaseConfigProvider.notifier)
                                  .syncNow(
                                    overrideUrl: collection.remoteSourceUrl,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.message),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            case _CollectionTileAction.setRemoteUrl:
                              await _openSetRemoteUrlDialog(context, ref, collection);
                            case _CollectionTileAction.editJson:
                              onEditJson();
                            case _CollectionTileAction.copyJson:
                              _copyCollectionJson(context);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: _CollectionTileAction.changeTargetLanguage,
                            child: _PopupMenuRow(
                              icon: Icons.school_rounded,
                              label: 'Język nauki (docelowy)',
                            ),
                          ),
                          const PopupMenuItem(
                            value: _CollectionTileAction.changeVoice,
                            child: _PopupMenuRow(
                              icon: Icons.record_voice_over_rounded,
                              label: 'Głos lektora tłumaczenia',
                            ),
                          ),
                          if (collection.remoteSourceUrl != null &&
                              collection.remoteSourceUrl!.isNotEmpty)
                            const PopupMenuItem(
                              value: _CollectionTileAction.syncRemote,
                              child: _PopupMenuRow(
                                icon: Icons.cloud_sync_rounded,
                                label: 'Synchronizuj z bazą zdalną',
                              ),
                            ),
                          const PopupMenuItem(
                            value: _CollectionTileAction.setRemoteUrl,
                            child: _PopupMenuRow(
                              icon: Icons.link_rounded,
                              label: 'Ustaw URL zdalnej bazy',
                            ),
                          ),
                          const PopupMenuItem(
                            value: _CollectionTileAction.editJson,
                            child: _PopupMenuRow(
                              icon: Icons.edit_note_rounded,
                              label: 'Edytuj JSON wyspy',
                            ),
                          ),
                          const PopupMenuItem(
                            value: _CollectionTileAction.copyJson,
                            child: _PopupMenuRow(
                              icon: Icons.copy_rounded,
                              label: 'Kopiuj JSON wyspy',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ChipLabel(text: collection.cefrLevel),
                  Tooltip(
                    message: 'Kliknij, aby zmienić język nauki (docelowy)',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => showSelectTargetLanguageDialog(
                        context,
                        collection: collection,
                      ),
                      child: _ChipLabel(
                        text:
                            '🎯 ${targetLang?.flagEmoji ?? '🇯🇵'} ${targetLang?.name ?? targetLangCode.toUpperCase()}',
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Kliknij, aby zmienić głos lektora tłumaczenia',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => showSelectTranslationVoiceDialog(
                        context,
                        collection: collection,
                      ),
                      child: _ChipLabel(
                        text:
                            '🔊 ${lang?.flagEmoji ?? '🌐'} ${lang?.name ?? langCode.toUpperCase()} (${lang?.voiceDisplayName ?? 'Głos'})',
                      ),
                    ),
                  ),
                  if (collection.remoteSourceUrl != null &&
                      collection.remoteSourceUrl!.isNotEmpty)
                    Tooltip(
                      message:
                          'Kolekcja połączona z bazą zdalną (kliknij, aby zsynchronizować)',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () async {
                          final res = await ref
                              .read(remoteDatabaseConfigProvider.notifier)
                              .syncNow(
                                overrideUrl: collection.remoteSourceUrl,
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(res.message),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const _ChipLabel(
                          text: '☁️ Baza zdalna',
                          muted: true,
                        ),
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

enum _CollectionsMenuAction {
  addSentenceForFriend,
  targetLanguage,
  translationVoice,
  remoteSync,
  importJson,
  dailyHistory,
  metrics,
  philosophy,
  languageManagement,
}

enum _CollectionTileAction {
  changeTargetLanguage,
  changeVoice,
  syncRemote,
  setRemoteUrl,
  editJson,
  copyJson,
}

class _PopupMenuRow extends StatelessWidget {
  const _PopupMenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
