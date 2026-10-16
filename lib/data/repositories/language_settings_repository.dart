import 'dart:convert';
import 'dart:io';

import 'package:language_islands_app/core/models/app_language.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LanguageSettingsRepository {
  LanguageSettingsRepository();

  Set<String>? _cachedUnlocked;

  Future<Set<String>> loadUnlockedLanguages() async {
    if (_cachedUnlocked != null) {
      return Set.unmodifiable(_cachedUnlocked!);
    }

    final file = await _settingsFile();
    if (!await file.exists()) {
      _cachedUnlocked = Set<String>.from(AppLanguage.defaultUnlockedCodes);
      await _persist(_cachedUnlocked!);
      return Set.unmodifiable(_cachedUnlocked!);
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return await _resetToDefaults();
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return await _resetToDefaults();
      }
      final codes = decoded['unlockedLanguages'];
      if (codes is! List) {
        return await _resetToDefaults();
      }

      final set = codes
          .whereType<String>()
          .map((s) => s.trim().toLowerCase())
          .where((s) => AppLanguage.fromCode(s) != null)
          .toSet();

      if (set.isEmpty) {
        return await _resetToDefaults();
      }

      _cachedUnlocked = set;
      return Set.unmodifiable(_cachedUnlocked!);
    } catch (_) {
      return await _resetToDefaults();
    }
  }

  String? _cachedDefaultTranslationLanguage;

  String get currentDefaultTranslationLanguage =>
      _cachedDefaultTranslationLanguage ?? 'en';

  Future<String> loadDefaultTranslationLanguage() async {
    if (_cachedDefaultTranslationLanguage != null) {
      return _cachedDefaultTranslationLanguage!;
    }

    final file = await _settingsFile();
    if (!await file.exists()) {
      _cachedDefaultTranslationLanguage = 'en';
      return 'en';
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        _cachedDefaultTranslationLanguage = 'en';
        return 'en';
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> &&
          decoded['defaultTranslationLanguage'] is String) {
        final code = (decoded['defaultTranslationLanguage'] as String)
            .trim()
            .toLowerCase();
        if (AppLanguage.fromCode(code) != null) {
          _cachedDefaultTranslationLanguage = code;
          return code;
        }
      }
    } catch (_) {}

    _cachedDefaultTranslationLanguage = 'en';
    return 'en';
  }

  Future<void> saveDefaultTranslationLanguage(String code) async {
    final normalized = code.trim().toLowerCase();
    if (AppLanguage.fromCode(normalized) == null) {
      throw ArgumentError('Nieobsługiwany kod języka: $code');
    }

    _cachedDefaultTranslationLanguage = normalized;

    final file = await _settingsFile();
    Map<String, dynamic> data = {};
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}
    }

    data['defaultTranslationLanguage'] = normalized;
    data['updatedAt'] = DateTime.now().toIso8601String();

    // Ensure this language is in unlockedLanguages
    final unlocked = await loadUnlockedLanguages();
    if (!unlocked.contains(normalized)) {
      final nextUnlocked = Set<String>.from(unlocked)..add(normalized);
      _cachedUnlocked = nextUnlocked;
      data['unlockedLanguages'] = nextUnlocked.toList()..sort();
    }

    await file.parent.create(recursive: true);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonStr, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  String? _cachedDefaultTargetLanguage;

  String get currentDefaultTargetLanguage =>
      _cachedDefaultTargetLanguage ?? 'ja';

  Future<String> loadDefaultTargetLanguage() async {
    if (_cachedDefaultTargetLanguage != null) {
      return _cachedDefaultTargetLanguage!;
    }

    final file = await _settingsFile();
    if (!await file.exists()) {
      _cachedDefaultTargetLanguage = 'ja';
      return 'ja';
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        _cachedDefaultTargetLanguage = 'ja';
        return 'ja';
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> &&
          decoded['defaultTargetLanguage'] is String) {
        final code = (decoded['defaultTargetLanguage'] as String)
            .trim()
            .toLowerCase();
        if (AppLanguage.fromCode(code) != null) {
          _cachedDefaultTargetLanguage = code;
          return code;
        }
      }
    } catch (_) {}

    _cachedDefaultTargetLanguage = 'ja';
    return 'ja';
  }

  Future<void> saveDefaultTargetLanguage(String code) async {
    final normalized = code.trim().toLowerCase();
    if (AppLanguage.fromCode(normalized) == null) {
      throw ArgumentError('Nieobsługiwany kod języka docelowego: $code');
    }

    _cachedDefaultTargetLanguage = normalized;

    final file = await _settingsFile();
    Map<String, dynamic> data = {};
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}
    }

    data['defaultTargetLanguage'] = normalized;
    data['updatedAt'] = DateTime.now().toIso8601String();

    // Ensure this language is in unlockedLanguages
    final unlocked = await loadUnlockedLanguages();
    if (!unlocked.contains(normalized)) {
      final nextUnlocked = Set<String>.from(unlocked)..add(normalized);
      _cachedUnlocked = nextUnlocked;
      data['unlockedLanguages'] = nextUnlocked.toList()..sort();
    }

    await file.parent.create(recursive: true);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonStr, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  Future<Set<String>> _resetToDefaults() async {
    final defaults = Set<String>.from(AppLanguage.defaultUnlockedCodes);
    await _persist(defaults);
    _cachedUnlocked = defaults;
    return Set.unmodifiable(_cachedUnlocked!);
  }

  Future<void> saveUnlockedLanguages(Set<String> codes) async {
    final valid = codes
        .map((s) => s.trim().toLowerCase())
        .where((s) => AppLanguage.fromCode(s) != null)
        .toSet();

    if (valid.isEmpty) {
      throw ArgumentError('Musi pozostać co najmniej jeden odblokowany język.');
    }

    _cachedUnlocked = valid;
    await _persist(valid);
  }

  Future<void> _persist(Set<String> codes) async {
    final file = await _settingsFile();
    Map<String, dynamic> data = {};
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}
    }

    data['unlockedLanguages'] = codes.toList()..sort();
    data['updatedAt'] = DateTime.now().toIso8601String();
    if (!data.containsKey('defaultTranslationLanguage')) {
      data['defaultTranslationLanguage'] = _cachedDefaultTranslationLanguage ?? 'en';
    }
    if (!data.containsKey('defaultTargetLanguage')) {
      data['defaultTargetLanguage'] = _cachedDefaultTargetLanguage ?? 'ja';
    }

    await file.parent.create(recursive: true);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonStr, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  Future<File> _settingsFile() async {
    final docs = await getApplicationDocumentsDirectory();
    return File(p.join(docs.path, 'settings', 'language_settings.json'));
  }
}
