/// Preset thinking windows before revealing the Japanese sentence in Recall.
abstract final class RecallThinkingDuration {
  static const List<Duration> presets = [
    Duration(milliseconds: 1500),
    Duration(milliseconds: 2000),
    Duration(milliseconds: 2500),
    Duration(milliseconds: 3500),
  ];

  static int presetIndex(Duration duration) {
    final index = presets.indexWhere((p) => p == duration);
    if (index >= 0) return index;
    return presets.indexOf(const Duration(milliseconds: 2500));
  }

  static Duration cycle(Duration current) {
    final nextIndex = (presetIndex(current) + 1) % presets.length;
    return presets[nextIndex];
  }

  static String formatLabel(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    return 'Think ${seconds.toStringAsFixed(1)}s';
  }
}
