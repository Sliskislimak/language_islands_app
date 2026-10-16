import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/kanji_entry.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';

enum KanjiListFilter {
  all,
  learning,
  dueOrNew,
  mastered,
}

class KanjiStats {
  const KanjiStats({
    required this.totalCount,
    required this.masteredCount,
    required this.learningCount,
    required this.newCount,
  });

  final int totalCount;
  final int masteredCount;
  final int learningCount;
  final int newCount;
}

final kanjiFilterProvider = StateProvider<KanjiListFilter>((ref) => KanjiListFilter.all);

final kanjiControllerProvider =
    AsyncNotifierProvider<KanjiController, List<KanjiEntry>>(
  KanjiController.new,
);

final kanjiStatsProvider = Provider<KanjiStats>((ref) {
  final list = ref.watch(kanjiControllerProvider).valueOrNull ?? const [];
  var mastered = 0;
  var learning = 0;
  var newCount = 0;

  for (final item in list) {
    if (item.masteryScore >= 5) {
      mastered++;
    } else if (item.masteryScore > 0) {
      learning++;
    } else {
      newCount++;
    }
  }

  return KanjiStats(
    totalCount: list.length,
    masteredCount: mastered,
    learningCount: learning,
    newCount: newCount,
  );
});

final filteredKanjiListProvider = Provider<List<KanjiEntry>>((ref) {
  final list = ref.watch(kanjiControllerProvider).valueOrNull ?? const [];
  final filter = ref.watch(kanjiFilterProvider);

  switch (filter) {
    case KanjiListFilter.all:
      return list;
    case KanjiListFilter.learning:
      return list.where((e) => e.isLearning).toList();
    case KanjiListFilter.dueOrNew:
      return list.where((e) => e.isNew || (e.masteryScore > 0 && e.masteryScore < 3)).toList();
    case KanjiListFilter.mastered:
      return list.where((e) => e.isMastered).toList();
  }
});

class KanjiController extends AsyncNotifier<List<KanjiEntry>> {
  @override
  Future<List<KanjiEntry>> build() async {
    final repo = ref.read(kanjiRepositoryProvider);
    return repo.loadStudyList();
  }

  Future<void> addKanji(List<KanjiEntry> entries) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(kanjiRepositoryProvider);
      await repo.addKanjiToStudyList(entries);
      return repo.loadStudyList();
    });
  }

  Future<void> removeKanji(String kanjiChar) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(kanjiRepositoryProvider);
      await repo.removeKanjiFromStudyList(kanjiChar);
      return repo.loadStudyList();
    });
  }

  Future<void> updateMastery(String kanjiChar, int score) async {
    final repo = ref.read(kanjiRepositoryProvider);
    await repo.updateMastery(kanjiChar, score);
    // Odśwież listę w tle bez uderzania całego widoku spinnerem
    final updated = await repo.loadStudyList();
    state = AsyncData(updated);
  }

  Future<int> importFromJson(String jsonStr) async {
    state = const AsyncLoading();
    var count = 0;
    state = await AsyncValue.guard(() async {
      final repo = ref.read(kanjiRepositoryProvider);
      count = await repo.importFromJsonString(jsonStr);
      return repo.loadStudyList();
    });
    return count;
  }

  Future<String> exportToJsonString({bool pretty = true}) async {
    final repo = ref.read(kanjiRepositoryProvider);
    return repo.exportToJsonString(pretty: pretty);
  }
}
