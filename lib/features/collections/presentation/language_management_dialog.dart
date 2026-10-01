import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/providers/language_settings_controller.dart';

Future<void> showLanguageManagementDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const LanguageManagementDialog(),
  );
}

class LanguageManagementDialog extends ConsumerWidget {
  const LanguageManagementDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlockedCodesAsync = ref.watch(languageSettingsControllerProvider);
    final unlockedCodes = unlockedCodesAsync.valueOrNull ??
        Set<String>.from(AppLanguage.defaultUnlockedCodes);

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.sakuraPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_rounded,
                      color: AppTheme.sakuraPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zarządzanie językami',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Odblokuj języki do wyboru w listach słówek',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    tooltip: 'Zamknij',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppTheme.sakuraPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Odblokowane języki będą widoczne do wyboru w odtwarzaczu i lektorze tłumaczenia. Wymagany min. 1 język.',
                        style: TextStyle(
                          color: AppTheme.textMuted.withValues(alpha: 0.9),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Language List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: AppLanguage.supportedLanguages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final language = AppLanguage.supportedLanguages[index];
                    final isUnlocked = unlockedCodes.contains(language.code);

                    return Material(
                      color: isUnlocked
                          ? AppTheme.surfaceElevated
                          : AppTheme.bgDark.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final success = await ref
                              .read(languageSettingsControllerProvider.notifier)
                              .toggleLanguage(language.code);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Co najmniej jeden język musi pozostać odblokowany!',
                                ),
                                duration: Duration(milliseconds: 1800),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isUnlocked
                                  ? AppTheme.sakuraPrimary.withValues(alpha: 0.5)
                                  : AppTheme.surfaceBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                language.flagEmoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          language.name,
                                          style: TextStyle(
                                            color: isUnlocked
                                                ? AppTheme.textLight
                                                : AppTheme.textMuted,
                                            fontSize: 14,
                                            fontWeight: isUnlocked
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${language.nativeName})',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Głos: ${language.voiceDisplayName} (${language.voiceName})',
                                      style: TextStyle(
                                        color: isUnlocked
                                            ? AppTheme.sakuraMuted
                                            : AppTheme.textMuted.withValues(alpha: 0.6),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: isUnlocked,
                                activeThumbColor: AppTheme.sakuraPrimary,
                                activeTrackColor: AppTheme.sakuraPrimary.withValues(alpha: 0.3),
                                inactiveThumbColor: AppTheme.textMuted,
                                inactiveTrackColor: AppTheme.bgDark,
                                onChanged: (val) async {
                                  final success = await ref
                                      .read(languageSettingsControllerProvider.notifier)
                                      .toggleLanguage(language.code);
                                  if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Co najmniej jeden język musi pozostać odblokowany!',
                                        ),
                                        duration: Duration(milliseconds: 1800),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              // Close button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.sakuraPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Gotowe',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
