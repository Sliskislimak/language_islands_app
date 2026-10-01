class ApiConstants {
  // Głosy Microsoft Neural (używane przez darmowy Edge TTS - nie wymagają klucza ani konta Azure!)
  static const String japaneseVoiceName = 'ja-JP-NanamiNeural';
  static const String polishVoiceName = 'pl-PL-MarekNeural';

  // Opcjonalne parametry Azure (używane jako ewentualny fallback, domyślnie puste)
  static const String azureSubscriptionKey = '';
  static const String azureRegion = 'westeurope';
}
