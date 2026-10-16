import 'dart:convert';
import 'dart:io';

import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/data/datasets/hiragana_data.dart';
import 'package:language_islands_app/data/datasets/kanji_dictionary_data.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Odpowiada za trwały zapis listy Kanji użytkownika oraz przeszukiwanie słownika.
class KanjiRepository {
  KanjiRepository();

  List<KanjiEntry>? _studyListCache;

  static final List<KanaItem> _sortedKana = () {
    final all = [
      ...HiraganaData.yoonList,
      ...HiraganaData.dakuonList,
      ...HiraganaData.seionList,
    ];
    all.sort((a, b) => b.romaji.length.compareTo(a.romaji.length));
    return all;
  }();

  static String _romajiToHiragana(String text) {
    var result = text.toLowerCase();
    for (final item in _sortedKana) {
      result = result.replaceAll(item.romaji, item.kana);
    }
    return result;
  }

  static String _hiraganaToKatakana(String hira) {
    return String.fromCharCodes(hira.runes.map((r) {
      if (r >= 0x3041 && r <= 0x3096) {
        return r + 0x60;
      }
      return r;
    }));
  }

  /// Pobiera listę znaków wyznaczonych do nauki przez użytkownika.
  Future<List<KanjiEntry>> loadStudyList() async {
    if (_studyListCache != null) {
      return List.unmodifiable(_studyListCache!);
    }
    _studyListCache = await _readStudyListFromDisk();
    return List.unmodifiable(_studyListCache!);
  }

  /// Przeszukuje wbudowany słownik Kanji po znaku, znaczeniu (PL/EN) lub czytaniu (romaji/kana).
  List<KanjiEntry> searchDictionary({
    String? query,
    String? jlptLevel,
  }) {
    final cleanQuery = query?.trim().toLowerCase();
    final cleanLevel = jlptLevel?.trim().toUpperCase();
    final hiraganaQuery = cleanQuery != null && cleanQuery.isNotEmpty
        ? _romajiToHiragana(cleanQuery)
        : null;
    final katakanaQuery =
        hiraganaQuery != null ? _hiraganaToKatakana(hiraganaQuery) : null;

    return KanjiDictionaryData.defaultDictionary.where((entry) {
      if (cleanLevel != null && cleanLevel != 'ALL' && cleanLevel.isNotEmpty) {
        if (entry.jlptLevel.toUpperCase() != cleanLevel) return false;
      }

      if (cleanQuery == null || cleanQuery.isEmpty) return true;

      // 1. Dopasowanie znaku Kanji
      if (entry.kanji.contains(cleanQuery)) return true;

      // 2. Dopasowanie znaczeń
      for (final m in entry.meanings) {
        if (m.toLowerCase().contains(cleanQuery)) return true;
      }

      // 3. Dopasowanie czytań on'yomi i kun'yomi (w tym przez Romaji)
      for (final on in entry.onyomi) {
        if (on.toLowerCase().contains(cleanQuery)) return true;
        if (katakanaQuery != null && on.contains(katakanaQuery)) return true;
        if (hiraganaQuery != null && on.contains(hiraganaQuery)) return true;
      }
      for (final kun in entry.kunyomi) {
        if (kun.toLowerCase().contains(cleanQuery)) return true;
        if (hiraganaQuery != null && kun.contains(hiraganaQuery)) return true;
      }

      // 4. Dopasowanie przykładowych słów
      for (final ex in entry.examples) {
        if (ex.word.contains(cleanQuery) ||
            ex.reading.toLowerCase().contains(cleanQuery) ||
            ex.meaning.toLowerCase().contains(cleanQuery) ||
            (hiraganaQuery != null && ex.reading.contains(hiraganaQuery))) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  /// Dodaje znaki kanji do listy aktywnej nauki użytkownika.
  /// Jeśli znak już istnieje, zachowuje dotychczasowy postęp użytkownika.
  Future<void> addKanjiToStudyList(List<KanjiEntry> newEntries) async {
    final current = List<KanjiEntry>.from(await loadStudyList());
    final existingMap = {for (final e in current) e.kanji: e};

    for (final item in newEntries) {
      if (item.kanji.trim().isEmpty) continue;
      if (!existingMap.containsKey(item.kanji)) {
        final withMeta = item.copyWith(
          addedAt: item.addedAt ?? DateTime.now(),
        );
        current.add(withMeta);
        existingMap[item.kanji] = withMeta;
      }
    }

    _studyListCache = current;
    await _writeStudyListToDisk(current);
  }

  /// Usuwa znak kanji z listy nauki.
  Future<void> removeKanjiFromStudyList(String kanjiChar) async {
    final current = List<KanjiEntry>.from(await loadStudyList());
    current.removeWhere((e) => e.kanji == kanjiChar);
    _studyListCache = current;
    await _writeStudyListToDisk(current);
  }

  /// Aktualizuje wynik opanowania (0-5 gwiazdek) i liczbę powtórzeń.
  Future<void> updateMastery(String kanjiChar, int newScore) async {
    final current = List<KanjiEntry>.from(await loadStudyList());
    final index = current.indexWhere((e) => e.kanji == kanjiChar);
    if (index < 0) return;

    final existing = current[index];
    current[index] = existing.copyWith(
      masteryScore: newScore.clamp(0, 5),
      totalReps: existing.totalReps + 1,
      lastStudiedAt: DateTime.now(),
    );

    _studyListCache = current;
    await _writeStudyListToDisk(current);
  }

  /// Importuje znaki z ciągu JSON (obsługuje tablicę `[...]` lub obiekt z listą `kanji`/`items`).
  Future<int> importFromJsonString(String jsonStr) async {
    final decoded = jsonDecode(jsonStr);
    List<dynamic> itemsList;

    if (decoded is List) {
      itemsList = decoded;
    } else if (decoded is Map) {
      final possibleList = decoded['kanji'] ?? decoded['items'] ?? decoded['data'];
      if (possibleList is List) {
        itemsList = possibleList;
      } else {
        throw const FormatException(
          'JSON musi być tablicą kanji lub obiektem zawierającym listę "kanji".',
        );
      }
    } else {
      throw const FormatException('Nieprawidłowy format JSON');
    }

    final parsedEntries = <KanjiEntry>[];
    for (final item in itemsList) {
      if (item is Map<String, dynamic>) {
        parsedEntries.add(KanjiEntry.fromMap(item));
      } else if (item is Map) {
        parsedEntries.add(KanjiEntry.fromMap(Map<String, dynamic>.from(item)));
      }
    }

    if (parsedEntries.isEmpty) {
      throw const FormatException('Plik JSON nie zawiera poprawnych znaków kanji.');
    }

    await addKanjiToStudyList(parsedEntries);
    return parsedEntries.length;
  }

  /// Zwraca bieżącą listę nauki jako sformatowany JSON.
  Future<String> exportToJsonString({bool pretty = true}) async {
    final list = await loadStudyList();
    final data = list.map((e) => e.toMap()).toList();
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(data);
    }
    return jsonEncode(data);
  }

  // --- Operacje na plikach na dysku ---

  Future<File> _getFile() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'kanji'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'my_kanji.json'));
  }

  Future<List<KanjiEntry>> _readStudyListFromDisk() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }
      final jsonStr = await file.readAsString();
      if (jsonStr.trim().isEmpty) return [];

      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map((m) => KanjiEntry.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeStudyListToDisk(List<KanjiEntry> list) async {
    final file = await _getFile();
    final data = list.map((e) => e.toMap()).toList();
    final encoded = jsonEncode(data);
    await file.writeAsString(encoded, flush: true);
  }
}
