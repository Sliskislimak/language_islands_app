/// Overall text size of the floating PiP bar (target text + phonetics).
enum PipFontSize {
  standard(0, 'Aa'),
  medium(2, 'Aa+'),
  large(4, 'Aa++');

  const PipFontSize(this.delta, this.label);

  /// Point size added to the 20pt target text and 13pt phonetic line.
  final int delta;
  final String label;

  PipFontSize get next => switch (this) {
        PipFontSize.standard => PipFontSize.medium,
        PipFontSize.medium => PipFontSize.large,
        PipFontSize.large => PipFontSize.standard,
      };
}

/// Text size of the Polish translation line, independent of [PipFontSize].
enum PipTranslationSize {
  small(0, 'S'),
  medium(2, 'M'),
  large(4, 'L');

  const PipTranslationSize(this.delta, this.label);

  /// Point size added on top of the 11pt base translation line.
  final int delta;
  final String label;

  PipTranslationSize get next => switch (this) {
        PipTranslationSize.small => PipTranslationSize.medium,
        PipTranslationSize.medium => PipTranslationSize.large,
        PipTranslationSize.large => PipTranslationSize.small,
      };

  String get chipLabel => 'PL: $label';
}
