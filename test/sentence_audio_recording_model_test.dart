import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/models/sentence.dart';

void main() {
  group('Sentence Audio Recording Model Tests', () {
    test('default constructor initializes audio recording fields to null', () {
      const sentence = Sentence(
        id: 's_1',
        targetText: 'こんにちは',
        sourceText: 'Cześć',
      );

      expect(sentence.targetAudioBase64, isNull);
      expect(sentence.translationAudioBase64, isNull);
      expect(sentence.hasCustomTargetAudio, isFalse);
      expect(sentence.hasCustomTranslationAudio, isFalse);
      expect(sentence.hasCustomVoice, isFalse);
    });

    test('hasCustomTargetAudio is true when path or base64 is set', () {
      const withPath = Sentence(
        id: 's_1',
        targetText: 'こんにちは',
        sourceText: 'Cześć',
        targetAudioPath: '/local/user_recordings/target.m4a',
      );
      expect(withPath.hasCustomTargetAudio, isTrue);
      expect(withPath.hasCustomVoice, isTrue);

      const withBase64 = Sentence(
        id: 's_2',
        targetText: 'こんにちは',
        sourceText: 'Cześć',
        targetAudioBase64: 'AAAA',
      );
      expect(withBase64.hasCustomTargetAudio, isTrue);
      expect(withBase64.hasCustomVoice, isTrue);
    });

    test('hasCustomTranslationAudio is true when path or base64 is set', () {
      const withPath = Sentence(
        id: 's_1',
        targetText: 'こんにちは',
        sourceText: 'Cześć',
        translationAudioPath: '/local/user_recordings/translation.m4a',
      );
      expect(withPath.hasCustomTranslationAudio, isTrue);
      expect(withPath.hasCustomVoice, isTrue);

      const withBase64 = Sentence(
        id: 's_2',
        targetText: 'こんにちは',
        sourceText: 'Cześć',
        translationAudioBase64: 'BBBB',
      );
      expect(withBase64.hasCustomTranslationAudio, isTrue);
      expect(withBase64.hasCustomVoice, isTrue);
    });

    test('copyWith properly updates or preserves recording fields', () {
      const initial = Sentence(
        id: 's_1',
        targetText: 'こんにちは',
        sourceText: 'Cześć',
        targetAudioBase64: 'AAAA',
        translationAudioBase64: 'BBBB',
      );

      final updated = initial.copyWith(
        targetAudioBase64: 'CCCC',
        translationAudioPath: '/path/trans.m4a',
      );

      expect(updated.targetAudioBase64, 'CCCC');
      expect(updated.translationAudioBase64, 'BBBB');
      expect(updated.translationAudioPath, '/path/trans.m4a');
    });

    test('toMap and fromMap serialize and deserialize recording fields', () {
      final sentence = Sentence(
        id: 's_full',
        targetText: 'ありがとうございます',
        sourceText: 'Dziękuję bardzo',
        phoneticReading: 'Arigatou gozaimasu',
        targetAudioPath: '/storage/ja_123.m4a',
        translationAudioPath: '/storage/pl_123.m4a',
        targetAudioBase64: 'BASE64_JA_AUDIO',
        translationAudioBase64: 'BASE64_PL_AUDIO',
      );

      final map = sentence.toMap();
      expect(map['targetAudioBase64'], 'BASE64_JA_AUDIO');
      expect(map['translationAudioBase64'], 'BASE64_PL_AUDIO');
      expect(map['targetAudioPath'], '/storage/ja_123.m4a');
      expect(map['translationAudioPath'], '/storage/pl_123.m4a');

      final deserialized = Sentence.fromMap(map);
      expect(deserialized.id, sentence.id);
      expect(deserialized.targetAudioBase64, 'BASE64_JA_AUDIO');
      expect(deserialized.translationAudioBase64, 'BASE64_PL_AUDIO');
      expect(deserialized.targetAudioPath, '/storage/ja_123.m4a');
      expect(deserialized.translationAudioPath, '/storage/pl_123.m4a');
      expect(deserialized, equals(sentence));
    });
  });
}
