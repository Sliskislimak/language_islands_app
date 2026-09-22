import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

const _aiJsonPromptTemplate = '''
Jesteś ekspertem lingwistycznym i twórcą materiałów do nauki języków metodą Shadowingu, Active Recall oraz Wysp Językowych.
Twoim zadaniem jest wygenerowanie bazy zdań w poprawnym formacie JSON zgodnym z poniższym schematem.

ZASADY TWORZENIA ZDAŃ:
1. Uczymy wyłącznie CAŁYCH ZDAŃ – zero pojedynczych, wyizolowanych słówek.
2. Zdania muszą być naturalne, praktyczne i gotowe do natychmiastowego użycia w rozmowie.
3. Gramatyka i koniugacje mają wynikać bezpośrednio z kontekstu zdań.
4. Dla poziomu A1 zdania powinny być krótkie i zwięzłe (najlepiej do 5-7 słów).
5. Pole `phoneticReading` musi zawierać zapis fonetyczny (dla japońskiego: Furigana/Hiragana oraz Romaji), ułatwiający natychmiastowe czytanie i powtarzanie na głos.

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
      "targetText": "Zdanie w języku docelowym (np. 毎朝コーヒーを飲みます。)",
      "phoneticReading": "Zapis fonetyczny (np. まいあさコーヒーをのみます。 Maiasa kōhī o nomimasu.)",
      "sourceText": "Naturalne tłumaczenie na język ojczysty (np. Piję kawę każdego ranka.)"
    },
    {
      "id": "unikalne_id_zdania_2",
      "targetText": "Kolejne zdanie w języku docelowym",
      "phoneticReading": "Zapis fonetyczny kolejnego zdania",
      "sourceText": "Tłumaczenie kolejnego zdania"
    }
  ]
}
''';

class ImportCollectionDialog extends StatefulWidget {
  const ImportCollectionDialog({super.key});

  @override
  State<ImportCollectionDialog> createState() => _ImportCollectionDialogState();
}

class _ImportCollectionDialogState extends State<ImportCollectionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        child: TextField(
          controller: _controller,
          maxLines: 12,
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
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Importuj'),
        ),
      ],
    );
  }
}
