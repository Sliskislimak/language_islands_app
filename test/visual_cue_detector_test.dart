import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/services/visual_cue_detector.dart';

void main() {
  group('VisualCueDetector', () {
    test('detects cat emoji for gato, kot, neko, cat', () {
      expect(
        VisualCueDetector.detectEmojis(
          targetText: 'El gato duerme.',
          sourceText: 'Kot śpi.',
        ),
        contains('🐱'),
      );

      expect(
        VisualCueDetector.detectEmojis(
          targetText: '猫が好きです。',
          phoneticReading: 'Neko ga suki desu.',
          sourceText: 'Lubię koty.',
        ),
        contains('🐱'),
      );
    });

    test('detects hospital emoji for bioni, byōin, byoin, hospital, szpital', () {
      // User's specific phonetic transcription: bioni
      expect(
        VisualCueDetector.detectEmojis(
          targetText: '病院に行きます。',
          phoneticReading: 'bioni ni ikimasu.',
          sourceText: 'Idę do szpitala.',
        ),
        contains('🏥'),
      );

      expect(
        VisualCueDetector.detectEmojis(
          targetText: 'Byōin wa doko desu ka?',
          sourceText: 'Where is the hospital?',
        ),
        contains('🏥'),
      );
    });

    test('detects both gato and bioni in a sentence', () {
      final emojis = VisualCueDetector.detectEmojis(
        targetText: 'El gato está en el hospital.',
        phoneticReading: 'gato bioni',
        sourceText: 'Kot jest w szpitalu.',
      );

      expect(emojis, containsAll(['🐱', '🏥']));
    });

    test('uses explicit emojis from JSON when provided', () {
      final emojis = VisualCueDetector.detectEmojis(
        targetText: 'El gato está en el hospital.',
        explicitEmojis: ['⭐', '🚀'],
      );

      expect(emojis, equals(['⭐', '🚀']));
    });

    test('does not false-positive on substring words', () {
      final emojis = VisualCueDetector.detectEmojis(
        targetText: 'This is a category of education.',
        sourceText: 'To jest kategoria edukacji.',
      );

      expect(emojis, isNot(contains('🐱')));
    });

    test('detects food and beverages: coffee, tea, water, bread', () {
      expect(
        VisualCueDetector.detectEmojis(
          targetText: '毎朝コーヒーを飲みます。',
          phoneticReading: 'Maiasa kōhī o nomimasu.',
          sourceText: 'Piję kawę każdego ranka.',
        ),
        contains('☕'),
      );
    });
  });
}
