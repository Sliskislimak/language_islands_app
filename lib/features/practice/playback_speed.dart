/// Allowed target-language playback speeds (shadowing sequencer).
abstract final class PlaybackSpeed {
  static const double min = 0.7;
  static const double max = 1.5;

  static const List<double> presets = [
    0.7,
    0.75,
    0.8,
    0.85,
    0.9,
    1.0,
    1.1,
    1.2,
    1.25,
    1.5,
  ];

  static double snapToPreset(double value) {
    final clamped = value.clamp(min, max);
    var nearest = presets.first;
    var bestDistance = (clamped - nearest).abs();
    for (final preset in presets) {
      final distance = (clamped - preset).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = preset;
      }
    }
    return nearest;
  }

  static int presetIndex(double speed) {
    final snapped = snapToPreset(speed);
    return presets.indexOf(snapped);
  }

  static String formatLabel(double speed) {
    final snapped = snapToPreset(speed);
    if (snapped == snapped.roundToDouble()) {
      return '${snapped.toStringAsFixed(1)}x';
    }
    return '${snapped}x';
  }
}
