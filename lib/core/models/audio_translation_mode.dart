enum AudioTranslationMode {
  disabled,
  prefix,
  alternating;

  AudioTranslationMode get next => switch (this) {
        AudioTranslationMode.disabled => AudioTranslationMode.prefix,
        AudioTranslationMode.prefix => AudioTranslationMode.alternating,
        AudioTranslationMode.alternating => AudioTranslationMode.disabled,
      };

  String get label => switch (this) {
        AudioTranslationMode.disabled => 'Wyłączone',
        AudioTranslationMode.prefix => 'Tłumaczenie na początku',
        AudioTranslationMode.alternating => 'Naprzemiennie',
      };

  String get shortLabel => switch (this) {
        AudioTranslationMode.disabled => 'Tylko JP',
        AudioTranslationMode.prefix => '1x PL → N× JP',
        AudioTranslationMode.alternating => 'PL ⇄ JP',
      };

  String get description => switch (this) {
        AudioTranslationMode.disabled =>
          'Standardowy shadowing — odtwarzany jest wyłącznie język docelowy.',
        AudioTranslationMode.prefix =>
          'Lektor czyta tłumaczenie w języku ojczystym 1 raz na początku, po czym następuje seria powtórzeń docelowych.',
        AudioTranslationMode.alternating =>
          'Odtwarzanie naprzemienne: para (Tłumaczenie PL → Język docelowy) powtarzana N razy w pętli.',
      };
}

enum ActiveAudioChannel {
  none,
  translation,
  target;

  bool get isTranslation => this == ActiveAudioChannel.translation;
  bool get isTarget => this == ActiveAudioChannel.target;
}
