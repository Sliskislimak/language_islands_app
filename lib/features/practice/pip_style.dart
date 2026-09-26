enum PipWindowSize {
  small(label: 'PiP: S', width: 320.0, height: 76.0, fontDelta: -2),
  medium(label: 'PiP: M', width: 360.0, height: 90.0, fontDelta: 0),
  large(label: 'PiP: L', width: 395.0, height: 108.0, fontDelta: 3);

  const PipWindowSize({
    required this.label,
    required this.width,
    required this.height,
    required this.fontDelta,
  });

  final String label;
  final double width;
  final double height;
  final int fontDelta;

  String get chipLabel => label;

  PipWindowSize get next => switch (this) {
        PipWindowSize.small => PipWindowSize.medium,
        PipWindowSize.medium => PipWindowSize.large,
        PipWindowSize.large => PipWindowSize.small,
      };
}

enum PipFontSize {
  standard(label: 'Aa', delta: 0),
  medium(label: 'Aa+', delta: 2),
  large(label: 'Aa++', delta: 4);

  const PipFontSize({required this.label, required this.delta});
  final String label;
  final int delta;

  String get chipLabel => label;

  PipFontSize get next => switch (this) {
        PipFontSize.standard => PipFontSize.medium,
        PipFontSize.medium => PipFontSize.large,
        PipFontSize.large => PipFontSize.standard,
      };
}

enum PipTranslationSize {
  small(label: 'PL: S', delta: 0),
  medium(label: 'PL: M', delta: 2),
  large(label: 'PL: L', delta: 4);

  const PipTranslationSize({required this.label, required this.delta});
  final String label;
  final int delta;

  String get chipLabel => label;

  PipTranslationSize get next => switch (this) {
        PipTranslationSize.small => PipTranslationSize.medium,
        PipTranslationSize.medium => PipTranslationSize.large,
        PipTranslationSize.large => PipTranslationSize.small,
      };
}