import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

const _aiJsonPromptTemplate = '''
Jesteś ekspertem lingwistycznym i twórcą materiałów do nauki języków metodą Shadowingu, Active Recall oraz Wysp Językowych.
Twoim zadaniem jest wygenerowanie bazy zdań w poprawnym formacie JSON zgodnym z poniższym schematem.

ZASADY TWORZENIA ZDAŃ:
1. Uczymy wyłącznie CAŁYCH ZDAŃ – zero pojedynczych, wyizolowanych słówek.
2. Zdania muszą być naturalne, praktyczne i gotowe do natychmiastowego użycia w rozmowie.
3. Gramatyka i koniugacje mają wynikać bezpośrednio z kontekstu zdań.
4. Dla poziomu A1 zdania powinny być krótkie i zwięzłe (najlepiej do 5-7 słów).
5. Pole `katakana` jest opcjonalne i zawiera wyłącznie katakanę. Pole `phoneticReading` zawiera Romaji. Te dwa zapisy mają być w osobnych polach, nigdy w jednym wierszu.
6. Pole `notes` na odwrocie fiszki (opcjonalne) – służy do wyjaśnienia teorii gramatycznej, niuansów, konstrukcji zdania lub wskazówek.
7. Pole `emojis` (opcjonalne) – tablica emoji (np. ["🐱"], ["🏥"]), które służą jako wizualne skojarzenia ułatwiające zapamiętywanie słów w zdaniu.

WYMAGANY FORMAT JSON (zwróć TYLKO czysty kod JSON bez znaczników markdown):
{
  "id": "unikalne_id_kolekcji_np_verbs_a1_part1",
  "title": "Tytuł kolekcji (np. 100 najczęstszych czasowników - Część 1)",
  "cefrLevel": "A1",
  "tags": ["czasowniki", "koniugacje", "codzienne"],
  "isCustomIsland": false,
  "sentences": [
    {
      "id": "unikalne_id_zdania_1",
      "targetText": "毎朝コーヒーを飲みます。",
      "katakana": "コーヒー",
      "phoneticReading": "Maiasa kōhī o nomimasu.",
      "sourceText": "Piję kawę każdego ranka.",
      "notes": "Konstrukcja: 毎朝 (każdego ranka) + コーヒー (kawa) + partykuła を (biernik) + 飲みます (pić w formie grzecznej masu).",
      "emojis": ["☕"]
    },
    {
      "id": "unikalne_id_zdania_2",
      "targetText": "猫は病院の前にいます。",
      "phoneticReading": "Neko wa byōin no mae ni imasu.",
      "sourceText": "Kot jest przed szpitalem.",
      "notes": "Neko (kot) + wa + byōin (szpital) + no mae ni (przed) + imasu (jest dla istot żywych).",
      "emojis": ["🐱", "🏥"]
    }
  ]
}
''';

class ImportCollectionRequest {
  const ImportCollectionRequest({required this.jsonStr, required this.title});

  final String jsonStr;
  final String title;
}

class ImportCollectionDialog extends StatefulWidget {
  const ImportCollectionDialog({super.key});

  @override
  State<ImportCollectionDialog> createState() => _ImportCollectionDialogState();
}

class _ImportCollectionDialogState extends State<ImportCollectionDialog> {
  final _jsonController = TextEditingController();
  final _titleController = TextEditingController();
  bool _titleTouched = false;

  @override
  void initState() {
    super.initState();
    _jsonController.addListener(_syncTitleFromJson);
  }

  @override
  void dispose() {
    _jsonController.removeListener(_syncTitleFromJson);
    _jsonController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _syncTitleFromJson() {
    if (_titleTouched) return;
    final title = SentenceCollection.tryParseTitle(_jsonController.text);
    if (title == null || title == _titleController.text) return;
    _titleController.text = title;
  }

  void _copyAiTemplate(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _aiJsonPromptTemplate));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Skopiowano szablon JSON i instrukcję dla AI do schowka!',
          style: TextStyle(fontSize: 12, color: AppTheme.textLight),
        ),
        backgroundColor: AppTheme.surfaceElevated,
        duration: Duration(milliseconds: 2200),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Row(
        children: [
          const Expanded(
            child: Text(
              'Import kolekcji JSON',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ),
          Tooltip(
            message: 'Kliknij, aby skopiować szablon i instrukcję JSON dla AI',
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              color: AppTheme.sakuraPrimary,
              onPressed: () => _copyAiTemplate(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                onChanged: (_) => _titleTouched = true,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Nazwa listy',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                  hintText: 'Nazwa nowej wyspy językowej',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.sakuraAccent),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _jsonController,
                maxLines: 10,
                style: const TextStyle(
                  color: AppTheme.textLight,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                decoration: const InputDecoration(
                  hintText: 'Wklej zawartość pliku JSON…',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.sakuraAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.greenMatcha,
            foregroundColor: AppTheme.bgDark,
          ),
          onPressed: () => Navigator.of(context).pop(
            ImportCollectionRequest(
              jsonStr: _jsonController.text,
              title: _titleController.text,
            ),
          ),
          child: const Text('Importuj'),
        ),
      ],
    );
  }
}
