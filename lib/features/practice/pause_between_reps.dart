/// Preset gaps between shadowing repetitions (seconds).
abstract final class PauseBetweenReps {
  static const List<Duration> presets = [
    Duration(milliseconds: 500),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 1500),
    Duration(milliseconds: 2000),
    Duration(milliseconds: 3000),
  ];

  static int presetIndex(Duration duration) {
    final index = presets.indexWhere((p) => p == duration);
    if (index >= 0) return index;
    return presets.indexOf(const Duration(milliseconds: 1500));
  }

  static Duration cycle(Duration current) {
    final nextIndex = (presetIndex(current) + 1) % presets.length;
    return presets[nextIndex];
  }

  static String formatLabel(Duration duration) {
    final seconds = duration.inMilliseconds / 1000;
    if (seconds == seconds.roundToDouble()) {
      return 'Pause ${seconds.toStringAsFixed(0)}s';
    }
    return 'Pause ${seconds.toStringAsFixed(1)}s';
  }
}
