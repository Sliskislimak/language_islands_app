import 'package:flutter/material.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

/// Dialog to add a new flashcard or edit an existing one.
class SentenceEditDialog extends StatefulWidget {
  const SentenceEditDialog({
    super.key,
    required this.collectionId,
    this.sentence,
    this.targetLanguageCode,
    this.onSave,
  });

  final String collectionId;
  final Sentence? sentence;
  final String? targetLanguageCode;
  final Future<void> Function(Sentence savedSentence)? onSave;

  bool get isEditing => sentence != null;

  @override
  State<SentenceEditDialog> createState() => _SentenceEditDialogState();
}

class _SentenceEditDialogState extends State<SentenceEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _targetTextController;
  late final TextEditingController _sourceTextController;
  late final TextEditingController _phoneticController;
  late final TextEditingController _katakanaController;
  late final TextEditingController _notesController;

  bool _showAdvanced = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final s = widget.sentence;
    _targetTextController = TextEditingController(text: s?.targetText ?? '');
    _sourceTextController = TextEditingController(text: s?.sourceText ?? '');
    _phoneticController =
        TextEditingController(text: s?.phoneticReading ?? '');
    _katakanaController = TextEditingController(text: s?.katakana ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');

    if (s != null &&
        (s.phoneticReading != null || s.katakana != null || s.hasNotes)) {
      _showAdvanced = true;
    }
  }

  @override
  void dispose() {
    _targetTextController.dispose();
    _sourceTextController.dispose();
    _phoneticController.dispose();
    _katakanaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetText = _targetTextController.text.trim();
    final sourceText = _sourceTextController.text.trim();
    final phonetic = _phoneticController.text.trim();
    final katakana = _katakanaController.text.trim();
    final notes = _notesController.text.trim();

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final Sentence saved;
      if (widget.isEditing) {
        final prev = widget.sentence!;
        final targetChanged = prev.targetText != targetText;
        final sourceChanged = prev.sourceText != sourceText;

        saved = prev.copyWith(
          targetText: targetText,
          sourceText: sourceText,
          phoneticReading: phonetic.isNotEmpty ? phonetic : null,
          clearPhoneticReading: phonetic.isEmpty,
          katakana: katakana.isNotEmpty ? katakana : null,
          clearKatakana: katakana.isEmpty,
          notes: notes.isNotEmpty ? notes : null,
          clearNotes: notes.isEmpty,
          clearTargetAudioPath: targetChanged,
          clearTranslationAudioPath: sourceChanged,
        );
      } else {
        final id = 's_${DateTime.now().millisecondsSinceEpoch}';
        saved = Sentence(
          id: id,
          targetText: targetText,
          sourceText: sourceText,
          phoneticReading: phonetic.isNotEmpty ? phonetic : null,
          katakana: katakana.isNotEmpty ? katakana : null,
          notes: notes.isNotEmpty ? notes : null,
        );
      }

      if (widget.onSave != null) {
        await widget.onSave!(saved);
      }

      if (mounted) {
        Navigator.of(context).pop(saved);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Błąd zapisu: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetLang = widget.targetLanguageCode != null
        ? AppLanguage.fromCode(widget.targetLanguageCode!)
        : null;
    final targetLangLabel = targetLang != null
        ? '${targetLang.flagEmoji} ${targetLang.nativeName}'
        : 'język docelowy';

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
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
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_circle_outline_rounded,
                        color: AppTheme.sakuraPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing
                                ? 'Edytuj fiszkę'
                                : 'Dodaj nową fiszkę',
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.isEditing
                                ? 'Zmień treść, tłumaczenie lub wymowę'
                                : 'Pojedyncza fiszka do wybranego zbioru',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Body fields (scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Target Text
                        Text(
                          'Treść zdania / Fiszka ($targetLangLabel)',
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _targetTextController,
                          maxLines: 3,
                          minLines: 1,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'np. 今日はとても楽しかったです。 lub Dzień dobry!',
                            hintStyle: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceElevated,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.surfaceBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.surfaceBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.sakuraPrimary,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Treść fiszki nie może być pusta.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Source Text (Translation)
                        const Text(
                          'Tłumaczenie (znaczenie w Twoim języku)',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _sourceTextController,
                          maxLines: 3,
                          minLines: 1,
                          style: const TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'np. Dzisiaj było bardzo wesoło / Dzisiejszy dzień był miły.',
                            hintStyle: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceElevated,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.surfaceBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.surfaceBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.sakuraPrimary,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tłumaczenie nie może być puste.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Advanced / Optional toggle
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showAdvanced = !_showAdvanced;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  _showAdvanced
                                      ? Icons.arrow_drop_down_rounded
                                      : Icons.arrow_right_rounded,
                                  color: AppTheme.sakuraPrimary,
                                ),
                                const SizedBox(width: 4),
                                const Flexible(
                                  child: Text(
                                    'Więcej opcji (wymowa, fonetyka, notatki)',
                                    style: TextStyle(
                                      color: AppTheme.sakuraPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_showAdvanced) ...[
                          const SizedBox(height: 10),
                          // Phonetic reading / Romaji
                          const Text(
                            'Czytanie fonetyczne (Romaji / Pinyin / Wymowa)',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _phoneticController,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'np. Kyou wa totemo tanoshikatta desu.',
                              hintStyle: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.surfaceBorder,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Katakana
                          const Text(
                            'Zapis Katakana (dla Koharu / fonetyka japońska)',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _katakanaController,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'np. ジェン ドブリ (dla zdań po polsku)',
                              hintStyle: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceElevated,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.surfaceBorder,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Notes
                          const Text(
                            'Notatki gramatyczne / Wskazówki (rewers fiszki)',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            minLines: 1,
                            style: const TextStyle(
                              color: AppTheme.textLight,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'np. Używane w sytuacjach nieformalnych...',
                              hintStyle: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                              filled: true,
                              fillColor: AppTheme.surfaceElevated,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppTheme.surfaceBorder,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Footer buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Anuluj',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.sakuraPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(widget.isEditing
                              ? Icons.check_rounded
                              : Icons.add_rounded),
                      label: Text(
                        widget.isEditing ? 'Zapisz zmiany' : 'Dodaj fiszkę',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper method to open the sentence edit dialog.
Future<Sentence?> showSentenceEditDialog(
  BuildContext context, {
  required String collectionId,
  Sentence? sentence,
  String? targetLanguageCode,
  Future<void> Function(Sentence savedSentence)? onSave,
}) {
  return showDialog<Sentence>(
    context: context,
    builder: (context) => SentenceEditDialog(
      collectionId: collectionId,
      sentence: sentence,
      targetLanguageCode: targetLanguageCode,
      onSave: onSave,
    ),
  );
}
