import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';

class EditCollectionJsonDialog extends ConsumerStatefulWidget {
  const EditCollectionJsonDialog({super.key, required this.collection});

  final SentenceCollection collection;

  @override
  ConsumerState<EditCollectionJsonDialog> createState() =>
      _EditCollectionJsonDialogState();
}

class _EditCollectionJsonDialogState
    extends ConsumerState<EditCollectionJsonDialog> {
  late final TextEditingController _jsonController;
  String? _errorMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController(
      text: widget.collection.toJsonString(pretty: true),
    );
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      _showToast('Schowek jest pusty.');
      return;
    }

    setState(() {
      _jsonController.text = text.trim();
      _errorMessage = null;
    });
    _showToast('Wklejono JSON ze schowka!');
  }

  void _copyCurrentJson() {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      _showToast('Brak tekstu do skopiowania.');
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    _showToast('Skopiowano aktualny JSON do schowka!');
  }

  void _formatJson() {
    final raw = _jsonController.text.trim();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      setState(() {
        _jsonController.text = formatted;
        _errorMessage = null;
      });
      _showToast('Sformatowano kod JSON.');
    } catch (e) {
      setState(() {
        _errorMessage = 'Nie można sformatować – niepoprawna składnia JSON: $e';
      });
    }
  }

  void _stripAudioFromJsonController() {
    final raw = _jsonController.text.trim();
    if (raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final map = Map<String, dynamic>.from(decoded);
        if (map['sentences'] is List) {
          final list = map['sentences'] as List;
          final cleanedList = <Map<String, dynamic>>[];
          for (final item in list) {
            if (item is Map) {
              final sMap = Map<String, dynamic>.from(item);
              sMap.remove('targetAudioPath');
              sMap.remove('translationAudioPath');
              sMap.remove('sourceAudioPath');
              sMap.remove('targetAudio');
              sMap.remove('translationAudio');
              sMap.remove('sourceAudio');
              sMap.remove('targetAudioBase64');
              sMap.remove('target_audio_base64');
              sMap.remove('translationAudioBase64');
              sMap.remove('translation_audio_base64');
              sMap.remove('sourceAudioBase64');
              sMap.remove('source_audio_base64');
              cleanedList.add(sMap);
            }
          }
          map['sentences'] = cleanedList;
        }
        setState(() {
          _jsonController.text =
              const JsonEncoder.withIndent('  ').convert(map);
          _errorMessage = null;
        });
      }
    } catch (_) {}
  }

  Future<void> _showDeleteDialog() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Czy chcesz usunąć?',
              style: TextStyle(
                color: AppTheme.textLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wyspa: ${widget.collection.title}',
                style: const TextStyle(
                  color: AppTheme.sakuraPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Wybierz co chcesz usunąć:',
                style: TextStyle(color: AppTheme.textLight, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(ctx).pop('delete_list'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Usuń całą listę',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Całkowicie usuwa tę listę fiszek i wszystkie powiązane nagrania z aplikacji.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(ctx).pop('delete_audio'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.yellowPrompt.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.yellowPrompt.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          color: AppTheme.yellowPrompt,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Usuń audio zapisane w pamięci',
                                style: TextStyle(
                                  color: AppTheme.yellowPrompt,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Kasuje nagrania i pliki cache z pamięci oraz usuwa ścieżki audio w JSON (naprawia problem przesuniętych nagrań).',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text(
              'Anuluj',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'delete_list') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Potwierdź usunięcie listy',
            style: TextStyle(color: AppTheme.textLight, fontSize: 16),
          ),
          content: Text(
            'Czy na pewno chcesz bezpowrotnie usunąć listę "${widget.collection.title}" wraz ze wszystkimi fiszkami i nagraniami audio?\n\nTej operacji nie można cofnąć.',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Anuluj', style: TextStyle(color: AppTheme.textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Usuń bezpowrotnie'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() => _isSaving = true);
      try {
        await ref
            .read(collectionsControllerProvider.notifier)
            .deleteCollection(widget.collection.id);
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pomyślnie usunięto listę "${widget.collection.title}".',
              ),
              backgroundColor: AppTheme.surfaceElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _errorMessage = 'Błąd podczas usuwania listy: $e';
          });
        }
      }
    } else if (choice == 'delete_audio') {
      setState(() => _isSaving = true);
      try {
        await ref
            .read(collectionsControllerProvider.notifier)
            .clearCollectionAudio(widget.collection.id);
        _stripAudioFromJsonController();

        if (mounted) {
          setState(() {
            _isSaving = false;
            _errorMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pomyślnie usunięto pliki audio z pamięci dla wyspy "${widget.collection.title}". Ścieżki audio zostały wyczyszczone.',
              ),
              backgroundColor: AppTheme.surfaceElevated,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _errorMessage = 'Błąd podczas usuwania audio: $e';
          });
        }
      }
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
        backgroundColor: AppTheme.surfaceElevated,
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onSave() async {
    final raw = _jsonController.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorMessage = 'Kod JSON nie może być pusty.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(collectionsControllerProvider.notifier)
          .updateCollectionFromJson(widget.collection.id, raw);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pomyślnie zaktualizowano JSON wyspy "${widget.collection.title}"!',
            ),
            backgroundColor: AppTheme.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Błąd zapisu JSON: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          const Icon(
            Icons.edit_note_rounded,
            color: AppTheme.sakuraPrimary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edycja JSON wyspy',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.collection.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 680,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toolbar row: Wklej ze schowka, Kopiuj, Formatuj
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.sakuraPrimary,
                    side: BorderSide(
                      color: AppTheme.sakuraPrimary.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste_rounded, size: 16),
                  label: const Text(
                    'Wklej ze schowka',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                    side: const BorderSide(color: AppTheme.surfaceBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _copyCurrentJson,
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text(
                    'Kopiuj',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.yellowPrompt,
                    side: BorderSide(
                      color: AppTheme.yellowPrompt.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _formatJson,
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
                  label: const Text(
                    'Formatuj',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _isSaving ? null : _showDeleteDialog,
                  icon: const Icon(Icons.delete_outline_rounded, size: 15),
                  label: const Text(
                    'Usuń...',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Editor field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _errorMessage != null
                        ? Colors.redAccent.withValues(alpha: 0.7)
                        : AppTheme.surfaceBorder,
                  ),
                ),
                child: TextField(
                  controller: _jsonController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: AppTheme.textLight,
                    height: 1.4,
                  ),
                  cursorColor: AppTheme.sakuraPrimary,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText: 'Wklej tutaj nowy kod JSON dla tej wyspy...',
                    hintStyle: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
          ),
          onPressed: _isSaving ? null : _showDeleteDialog,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text(
            'Usuń...',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Anuluj',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.sakuraPrimary,
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving ? null : _onSave,
          icon: _isSaving
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_rounded, size: 16),
          label: Text(
            _isSaving ? 'Zapisywanie...' : 'Zapisz i zaktualizuj wyspę',
          ),
        ),
      ],
    );
  }
}
