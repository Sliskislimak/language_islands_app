class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    required this.voiceName,
    required this.locale,
    required this.voiceDisplayName,
  });

  final String code;
  final String name;
  final String nativeName;
  final String flagEmoji;
  final String voiceName;
  final String locale;
  final String voiceDisplayName;

  String get labelWithFlag => '$flagEmoji $name';

  String get fullDisplayName => '$flagEmoji $name ($voiceDisplayName)';

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(
      code: 'en',
      name: 'Angielski',
      nativeName: 'English',
      flagEmoji: '🇬🇧',
      voiceName: 'en-US-JennyNeural',
      locale: 'en-US',
      voiceDisplayName: 'Jenny',
    ),
    AppLanguage(
      code: 'pl',
      name: 'Polski',
      nativeName: 'Polski',
      flagEmoji: '🇵🇱',
      voiceName: 'pl-PL-MarekNeural',
      locale: 'pl-PL',
      voiceDisplayName: 'Marek',
    ),
    AppLanguage(
      code: 'ja',
      name: 'Japoński',
      nativeName: '日本語',
      flagEmoji: '🇯🇵',
      voiceName: 'ja-JP-NanamiNeural',
      locale: 'ja-JP',
      voiceDisplayName: 'Nanami',
    ),
    AppLanguage(
      code: 'de',
      name: 'Niemiecki',
      nativeName: 'Deutsch',
      flagEmoji: '🇩🇪',
      voiceName: 'de-DE-KillianNeural',
      locale: 'de-DE',
      voiceDisplayName: 'Killian',
    ),
    AppLanguage(
      code: 'es',
      name: 'Hiszpański',
      nativeName: 'Español',
      flagEmoji: '🇪🇸',
      voiceName: 'es-ES-AlvaroNeural',
      locale: 'es-ES',
      voiceDisplayName: 'Alvaro',
    ),
    AppLanguage(
      code: 'fr',
      name: 'Francuski',
      nativeName: 'Français',
      flagEmoji: '🇫🇷',
      voiceName: 'fr-FR-DeniseNeural',
      locale: 'fr-FR',
      voiceDisplayName: 'Denise',
    ),
    AppLanguage(
      code: 'it',
      name: 'Włoski',
      nativeName: 'Italiano',
      flagEmoji: '🇮🇹',
      voiceName: 'it-IT-DiegoNeural',
      locale: 'it-IT',
      voiceDisplayName: 'Diego',
    ),
    AppLanguage(
      code: 'uk',
      name: 'Ukraiński',
      nativeName: 'Українська',
      flagEmoji: '🇺🇦',
      voiceName: 'uk-UA-PolinaNeural',
      locale: 'uk-UA',
      voiceDisplayName: 'Polina',
    ),
    AppLanguage(
      code: 'zh',
      name: 'Chiński',
      nativeName: '中文',
      flagEmoji: '🇨🇳',
      voiceName: 'zh-CN-XiaoxiaoNeural',
      locale: 'zh-CN',
      voiceDisplayName: 'Xiaoxiao',
    ),
    AppLanguage(
      code: 'ko',
      name: 'Koreański',
      nativeName: '한국어',
      flagEmoji: '🇰🇷',
      voiceName: 'ko-KR-SunHiNeural',
      locale: 'ko-KR',
      voiceDisplayName: 'SunHi',
    ),
  ];

  static const List<String> defaultUnlockedCodes = ['en', 'pl'];

  static AppLanguage? fromCode(String? code) {
    if (code == null || code.trim().isEmpty) return null;
    final normalized = code.trim().toLowerCase();
    for (final lang in supportedLanguages) {
      if (lang.code.toLowerCase() == normalized) {
        return lang;
      }
    }
    return null;
  }

  static AppLanguage defaultLanguage = supportedLanguages.first;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLanguage &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
