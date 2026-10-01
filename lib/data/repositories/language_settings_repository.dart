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
    await file.parent.create(recursive: true);
    final data = {
      'unlockedLanguages': codes.toList()..sort(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
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
