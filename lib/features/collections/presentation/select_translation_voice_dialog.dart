import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/presentation/language_management_dialog.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/collections/providers/language_settings_controller.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_notifier.dart';

Future<void> showSelectTranslationVoiceDialog(
  BuildContext context, {
  SentenceCollection? collection,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => SelectTranslationVoiceDialog(collection: collection),
  );
}

class SelectTranslationVoiceDialog extends ConsumerWidget {
  const SelectTranslationVoiceDialog({super.key, this.collection});

  final SentenceCollection? collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultLangAsync = ref.watch(defaultTranslationLanguageProvider);
    final defaultCode = defaultLangAsync.valueOrNull ?? 'en';

    final session = ref.watch(practiceSessionProvider);
    final currentCode = collection?.translationLanguage ??
        (session != null && session.collection.id == collection?.id
            ? session.translationLanguage
            : (session?.translationLanguage ?? defaultCode));

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.sakuraPrimary.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: AppTheme.sakuraPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Głos lektora tłumaczenia',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Wybierz głos do czytania tłumaczeń zdań',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.surfaceBorder, height: 1),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shrinkWrap: true,
                itemCount: AppLanguage.supportedLanguages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final lang = AppLanguage.supportedLanguages[index];
                  final isSelected = lang.code == currentCode;

                  return Material(
                    color: isSelected
                        ? AppTheme.sakuraPrimary.withAlpha(35)
                        : AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        await _selectLanguage(context, ref, lang);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.sakuraPrimary
                                : AppTheme.surfaceBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              lang.flagEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        lang.name,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppTheme.sakuraPrimary
                                              : AppTheme.textLight,
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '(${lang.nativeName})',
                                        style: const TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Lektor: ${lang.voiceDisplayName} · ${lang.voiceName}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppTheme.textLight.withAlpha(210)
                                          : AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.sakuraPrimary,
                                size: 22,
                              )
                            else
                              const Icon(
                                Icons.radio_button_unchecked_rounded,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: AppTheme.surfaceBorder, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showLanguageManagementDialog(context);
                      },
                      icon: const Icon(
                        Icons.settings_outlined,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                      label: const Text(
                        'Odblokowane języki',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Zamknij',
                      style: TextStyle(color: AppTheme.sakuraPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLanguage(
    BuildContext context,
    WidgetRef ref,
    AppLanguage lang,
  ) async {
    // 1. Zapisz jako domyślny język w ustawieniach
    await ref
        .read(defaultTranslationLanguageProvider.notifier)
        .setLanguage(lang.code);

    // 2. Jeśli mamy konkretną kolekcję, zapisz w niej
    if (collection != null) {
      await ref
          .read(collectionsControllerProvider.notifier)
          .setTranslationLanguageForCollection(collection!.id, lang.code);
    } else {
      // Jeśli ustawiane globalnie z ekranu głównego, zaktualizuj też wszystkie kolekcje
      await ref
          .read(collectionsControllerProvider.notifier)
          .setTranslationLanguageForAllCollections(lang.code);
    }

    // 3. Jeśli sesja ćwiczeń jest aktualnie aktywna, zaktualizuj natychmiast lektora sesji
    final session = ref.read(practiceSessionProvider);
    if (session != null) {
      await ref
          .read(practiceSessionProvider.notifier)
          .setTranslationLanguage(lang.code);
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ustawiono lektora tłumaczenia: ${lang.flagEmoji} ${lang.name} (${lang.voiceDisplayName} Neural)',
        ),
        backgroundColor: AppTheme.surfaceElevated,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
