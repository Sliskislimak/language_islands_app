import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';

final languageSettingsControllerProvider =
    AsyncNotifierProvider<LanguageSettingsController, Set<String>>(
  LanguageSettingsController.new,
);

final unlockedLanguagesProvider = Provider<List<AppLanguage>>((ref) {
  final codesAsync = ref.watch(languageSettingsControllerProvider);
  final codes = codesAsync.valueOrNull ??
      Set<String>.from(AppLanguage.defaultUnlockedCodes);
  return AppLanguage.supportedLanguages
      .where((lang) => codes.contains(lang.code))
      .toList();
});

class LanguageSettingsController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final repo = ref.read(languageSettingsRepositoryProvider);
    return repo.loadUnlockedLanguages();
  }

  Future<bool> toggleLanguage(String code) async {
    final current = state.valueOrNull ?? await build();
    final normalized = code.trim().toLowerCase();

    if (current.contains(normalized)) {
      if (current.length <= 1) {
        // Cannot lock the last remaining language
        return false;
      }
      final next = Set<String>.from(current)..remove(normalized);
      await _save(next);
      return true;
    } else {
      final next = Set<String>.from(current)..add(normalized);
      await _save(next);
      return true;
    }
  }

  Future<void> setLanguageUnlocked(String code, bool unlocked) async {
    final current = state.valueOrNull ?? await build();
    final normalized = code.trim().toLowerCase();

    if (!unlocked && current.contains(normalized) && current.length <= 1) {
      return;
    }

    final next = Set<String>.from(current);
    if (unlocked) {
      next.add(normalized);
    } else {
      next.remove(normalized);
    }
    await _save(next);
  }

  Future<void> _save(Set<String> next) async {
    final repo = ref.read(languageSettingsRepositoryProvider);
    await repo.saveUnlockedLanguages(next);
    state = AsyncData(next);
  }
}

final defaultTranslationLanguageProvider =
    AsyncNotifierProvider<DefaultTranslationLanguageController, String>(
  DefaultTranslationLanguageController.new,
);

class DefaultTranslationLanguageController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final repo = ref.read(languageSettingsRepositoryProvider);
    return repo.loadDefaultTranslationLanguage();
  }

  Future<void> setLanguage(String code) async {
    final repo = ref.read(languageSettingsRepositoryProvider);
    await repo.saveDefaultTranslationLanguage(code);
    state = AsyncData(code);
    ref.invalidate(languageSettingsControllerProvider);
  }
}

final defaultTargetLanguageProvider =
    AsyncNotifierProvider<DefaultTargetLanguageController, String>(
  DefaultTargetLanguageController.new,
);

class DefaultTargetLanguageController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final repo = ref.read(languageSettingsRepositoryProvider);
    return repo.loadDefaultTargetLanguage();
  }

  Future<void> setLanguage(String code) async {
    final repo = ref.read(languageSettingsRepositoryProvider);
    await repo.saveDefaultTargetLanguage(code);
    state = AsyncData(code);
    ref.invalidate(languageSettingsControllerProvider);
  }
}

