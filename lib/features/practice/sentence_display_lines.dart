import 'package:language_islands_app/core/models/sentence.dart';

/// Japanese card lines kept on separate rows: kanji, katakana, romaji.
class SentenceDisplayLines {
  const SentenceDisplayLines({
    required this.targetText,
    this.katakana,
    this.romaji,
  });

  final String targetText;
  final String? katakana;
  final String? romaji;

  factory SentenceDisplayLines.resolve(Sentence sentence) {
    final field = _clean(sentence.katakana);
    final phonetic = _clean(sentence.phoneticReading);
    if (phonetic == null) {
      return SentenceDisplayLines(
        targetText: sentence.targetText,
        katakana: field,
      );
    }

    final parts = _splitJapaneseAndRomaji(phonetic);
    final japanese = parts.japanese;
    final romaji = parts.romaji;
    final mixed = japanese != null && romaji != null;

    if (field != null) {
      if (romaji != null) {
        return SentenceDisplayLines(
          targetText: sentence.targetText,
          katakana: field,
          romaji: romaji,
        );
      }
      if (phonetic == field) {
        return SentenceDisplayLines(
          targetText: sentence.targetText,
          katakana: field,
        );
      }
      return SentenceDisplayLines(
        targetText: sentence.targetText,
        katakana: field,
        romaji: phonetic,
      );
    }

    if (mixed) {
      return SentenceDisplayLines(
        targetText: sentence.targetText,
        katakana: japanese,
        romaji: romaji,
      );
    }

    if (japanese != null && _containsKatakana(japanese)) {
      return SentenceDisplayLines(
        targetText: sentence.targetText,
        katakana: japanese,
      );
    }

    return SentenceDisplayLines(
      targetText: sentence.targetText,
      romaji: phonetic,
    );
  }
}

class _ScriptParts {
  const _ScriptParts({this.japanese, this.romaji});

  final String? japanese;
  final String? romaji;
}

_ScriptParts _splitJapaneseAndRomaji(String input) {
  final japanese = StringBuffer();
  final romaji = StringBuffer();
  var japaneseSpace = false;
  var romajiSpace = false;

  for (final rune in input.runes) {
    if (_isWhitespace(rune)) {
      if (japanese.isNotEmpty) japaneseSpace = true;
      if (romaji.isNotEmpty) romajiSpace = true;
      continue;
    }
    if (_isJapaneseRune(rune)) {
      if (japaneseSpace) japanese.write(' ');
      japaneseSpace = false;
      japanese.writeCharCode(rune);
      continue;
    }
    if (_isRomajiRune(rune) || (_isRomajiPunct(rune) && romaji.isNotEmpty)) {
      if (romajiSpace) romaji.write(' ');
      romajiSpace = false;
      romaji.writeCharCode(rune);
      continue;
    }
  }

  return _ScriptParts(
    japanese: _clean(japanese.toString()),
    romaji: _clean(romaji.toString()),
  );
}

String? _clean(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _containsKatakana(String value) {
  return value.runes.any(_isKatakanaRune);
}

bool _isWhitespace(int rune) {
  return rune == 0x20 ||
      rune == 0x09 ||
      rune == 0x0A ||
      rune == 0x0D ||
      rune == 0x3000;
}

bool _isKatakanaRune(int rune) {
  return (rune >= 0x30A0 && rune <= 0x30FF) ||
      (rune >= 0x31F0 && rune <= 0x31FF) ||
      (rune >= 0xFF66 && rune <= 0xFF9D);
}

bool _isJapaneseRune(int rune) {
  if (_isKatakanaRune(rune)) return true;
  if (rune >= 0x3040 && rune <= 0x309F) return true;
  if (rune >= 0x4E00 && rune <= 0x9FFF) return true;
  if (rune >= 0x3400 && rune <= 0x4DBF) return true;
  return rune == 0x3001 ||
      rune == 0x3002 ||
      rune == 0x300C ||
      rune == 0x300D ||
      rune == 0x300E ||
      rune == 0x300F ||
      rune == 0xFF01 ||
      rune == 0xFF1F;
}

bool _isRomajiRune(int rune) {
  if (rune >= 0x41 && rune <= 0x5A) return true;
  if (rune >= 0x61 && rune <= 0x7A) return true;
  if (rune >= 0xC0 && rune <= 0x024F) return true;
  return rune == 0x27 || rune == 0x2019;
}

bool _isRomajiPunct(int rune) {
  return rune == 0x2D ||
      rune == 0x2E ||
      rune == 0x2C ||
      rune == 0x21 ||
      rune == 0x3F ||
      rune == 0x3A;
}
