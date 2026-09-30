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

    test('detects N5 everyday objects: key, umbrella, camera, photo, window, light', () {
      expect(
        VisualCueDetector.detectEmojis(
          targetText: 'これは私の鍵です。',
          phoneticReading: 'Kore wa watashi no kagi desu.',
          sourceText: 'This is my key.',
        ),
        contains('🔑'),
      );

      expect(
        VisualCueDetector.detectEmojis(
          targetText: '傘と鍵を持ちました。',
          sourceText: 'An umbrella and key, I took.',
        ),
        containsAll(['🔑', '☂️']),
      );

      expect(
        VisualCueDetector.detectEmojis(
          targetText: '日本のカメラを買いました。',
          sourceText: 'A Japanese camera, I bought.',
        ),
        contains('📷'),
      );

      expect(
        VisualCueDetector.detectEmojis(
          targetText: '寒いから、窓を閉めます。',
          sourceText: 'Because it is cold, I close the window.',
        ),
        contains('🪟'),
      );

      expect(
        VisualCueDetector.detectEmojis(
          targetText: '暗いから、電気を点けます。',
          sourceText: 'Because it is dark, I turn on the light.',
        ),
        contains('💡'),
      );
    });

    test('train densha does not trigger car emoji due to compound exclusion', () {
      final emojis = VisualCueDetector.detectEmojis(
        targetText: '次の駅で電車を降ります。',
        phoneticReading: 'Tsugi no eki de densha o orimasu.',
        sourceText: 'At the next station, the train I get off.',
      );

      expect(emojis, contains('🚆'));
      expect(emojis, isNot(contains('🚗')));
    });
  });
}
