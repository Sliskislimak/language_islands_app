import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

const _aiKanjiJsonPromptTemplate = '''
Jesteś ekspertem języka japońskiego. Wygeneruj bazę znaków Kanji w formacie JSON do nauki.

WYMAGANY FORMAT JSON (zwróć TYLKO czysty kod JSON bez znaczników markdown):
[
  {
    "kanji": "日",
    "meanings": ["dzień", "słońce"],
    "onyomi": ["ニチ", "ジツ"],
    "kunyomi": ["ひ", "-び", "-か"],
    "strokeCount": 4,
    "jlptLevel": "N5",
    "examples": [
      {
        "word": "日本",
        "reading": "にほん",
        "meaning": "Japonia"
      },
      {
        "word": "毎日",
        "reading": "まいにち",
        "meaning": "codziennie"
      }
    ]
  }
]
''';

class KanjiImportDialog extends StatefulWidget {
  const KanjiImportDialog({super.key});

  @override
  State<KanjiImportDialog> createState() => _KanjiImportDialogState();
}

class _KanjiImportDialogState extends State<KanjiImportDialog> {
  final _textController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _copyPrompt(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _aiKanjiJsonPromptTemplate));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Skopiowano prompt dla AI do schowka!'),
        backgroundColor: AppTheme.surfaceElevated,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Wklej kod JSON ze znakami kanji.');
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.surfaceBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.upload_file_rounded, color: AppTheme.sakuraPrimary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Wgraj listę Kanji (JSON)',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.yellowPrompt, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Generujesz znaki z AI? Skopiuj gotowy schemat promptu.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.sakuraPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () => _copyPrompt(context),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Kopiuj Prompt', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Wklej treść JSON poniżej:',
                style: TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                  decoration: InputDecoration(
                    hintText: '[\n  {\n    "kanji": "日",\n    "meanings": ["dzień", "słońce"],\n    ...\n  }\n]',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: AppTheme.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.sakuraPrimary),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Anuluj', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sakuraPrimary,
                      foregroundColor: AppTheme.bgDark,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Zaimportuj znaki', style: TextStyle(fontWeight: FontWeight.bold)),
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
