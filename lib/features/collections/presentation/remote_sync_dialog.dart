import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/providers/remote_sync_controller.dart';

Future<void> showRemoteSyncDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const RemoteSyncDialog(),
  );
}

class RemoteSyncDialog extends ConsumerStatefulWidget {
  const RemoteSyncDialog({super.key});

  @override
  ConsumerState<RemoteSyncDialog> createState() => _RemoteSyncDialogState();
}

class _RemoteSyncDialogState extends ConsumerState<RemoteSyncDialog> {
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _autoSync = false;
  bool _isLoading = false;
  bool _isGuideExpanded = false;
  String? _statusMessage;
  bool? _lastSuccess;

  @override
  void initState() {
    super.initState();
    final config = ref.read(remoteDatabaseConfigProvider).valueOrNull;
    if (config != null) {
      _urlController.text = config.url;
      _apiKeyController.text = config.apiKey;
      _autoSync = config.autoSyncOnStartup;
      _statusMessage = config.lastSyncStatus;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleSync() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wprowadź adres URL zdalnej bazy lub endpointu JSON.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await ref.read(remoteDatabaseConfigProvider.notifier).updateConfig(
            url: url,
            apiKey: _apiKeyController.text.trim(),
            autoSyncOnStartup: _autoSync,
          );

      final result = await ref.read(remoteDatabaseConfigProvider.notifier).syncNow(
            overrideUrl: url,
            overrideApiKey: _apiKeyController.text.trim(),
          );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastSuccess = result.success;
        _statusMessage = result.message;
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppTheme.surfaceElevated,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastSuccess = false;
        _statusMessage = 'Wystąpił błąd: $e';
      });
    }
  }

  void _copySampleJson() {
    const sample = '''
{
  "id": "polski_dla_przyjaciolki_01",
  "title": "Polski dla początkujących - Lekcja 1",
  "cefrLevel": "A1",
  "tags": ["polski", "podstawy", "powitania"],
  "targetLanguage": "pl",
  "translationLanguage": "ja",
  "sentences": [
    {
      "id": "pl_001",
      "targetText": "Cześć! Jak się masz?",
      "phoneticReading": "Czeszć! Jak shye masz?",
      "sourceText": "こんにちは！お元気ですか？",
      "notes": "Podstawowe przywitanie. Odpowiedź: Dobrze, dziękuję.",
      "emojis": ["👋", "😊"]
    },
    {
      "id": "pl_002",
      "targetText": "Bardzo mi miło cię poznać.",
      "phoneticReading": "Bardzo mi miwo cye poznacz.",
      "sourceText": "はじめまして、よろしくお願いします。",
      "notes": "Używane przy pierwszym spotkaniu.",
      "emojis": ["🤝", "🌸"]
    }
  ]
}''';
    Clipboard.setData(const ClipboardData(text: sample));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skopiowano przykładowy JSON do schowka!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.sakuraPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_sync_rounded,
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
                          'Zdalna Baza Zdań',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pobieraj zdania zdalnie dodawane dla przyjaciółki',
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
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _urlController,
                      style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Adres URL bazy danych / JSON',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        hintText: 'https://... (Supabase REST, GitHub Gist, JSONBin, serwer)',
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        prefixIcon: Icon(Icons.link_rounded, color: AppTheme.sakuraPrimary, size: 20),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.surfaceBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.sakuraPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Klucz API / Token autoryzacji (opcjonalny)',
                        labelStyle: TextStyle(color: AppTheme.textMuted),
                        hintText: 'np. anon key dla Supabase lub Bearer token',
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        prefixIcon: Icon(Icons.key_rounded, color: AppTheme.textMuted, size: 20),
                        border: OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.surfaceBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.sakuraPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _autoSync,
                          activeColor: AppTheme.sakuraPrimary,
                          onChanged: (val) {
                            setState(() {
                              _autoSync = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Automatycznie sprawdzaj aktualizacje bazy przy uruchomieniu',
                            style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_lastSuccess == true)
                              ? AppTheme.greenMatcha.withValues(alpha: 0.12)
                              : Colors.redAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_lastSuccess == true)
                                ? AppTheme.greenMatcha.withValues(alpha: 0.5)
                                : Colors.redAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (_lastSuccess == true)
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.error_outline_rounded,
                              color: (_lastSuccess == true)
                                  ? AppTheme.greenMatcha
                                  : Colors.redAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  color: (_lastSuccess == true)
                                      ? AppTheme.greenMatcha
                                      : Colors.redAccent,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Action button: Synchronizuj
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _handleSync,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.sakuraPrimary,
                        foregroundColor: AppTheme.bgDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.bgDark,
                              ),
                            )
                          : const Icon(Icons.cloud_download_rounded, size: 20),
                      label: Text(
                        _isLoading ? 'Pobieranie zdań z bazy…' : 'Zapisz i pobierz zdania teraz',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Guide card
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              setState(() {
                                _isGuideExpanded = !_isGuideExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: AppTheme.yellowPrompt,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'Jak zdalnie dodawać zdania dla przyjaciółki?',
                                      style: TextStyle(
                                        color: AppTheme.textLight,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _isGuideExpanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    color: AppTheme.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isGuideExpanded) ...[
                            const Divider(height: 1, color: AppTheme.surfaceBorder),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '1. Wybierz darmowy serwis bazodanowy:\n'
                                    '• GitHub Gist: Utwórz publiczny lub prywatny Gist z plikiem collections.json, a w aplikacji wklej link do pliku "Raw".\n'
                                    '• Supabase (PostgreSQL): Stwórz tabelę i użyj wbudowanego REST API (np. https://xyz.supabase.co/rest/v1/collections) z kluczem anonimowym.\n'
                                    '• JSONBin.io lub własny serwer: Wklej adres endpointu zwracającego JSON.\n\n'
                                    '2. Struktura JSON (Polski z japońskim tłumaczeniem):\n'
                                    'Ustaw "targetLanguage": "pl" oraz "translationLanguage": "ja".',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    onPressed: _copySampleJson,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.sakuraPrimary,
                                      side: const BorderSide(color: AppTheme.sakuraPrimary),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                    label: const Text(
                                      'Kopiuj przykładowy JSON bazy',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
