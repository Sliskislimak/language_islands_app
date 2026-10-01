import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/constants/api_constants.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/services/azure_tts_service.dart';

void main() {
  group('EdgeTtsService / AzureTtsService', () {
    late AzureTtsService service;

    setUp(() {
      service = AzureTtsService();
    });

    tearDown(() {
      service.dispose();
    });

    test('isConfigured is true by default without requiring Azure keys', () {
      expect(service.isConfigured, isTrue);
      expect(EdgeTtsService, equals(AzureTtsService));
    });

    test('isAzureConfigured reflects whether an Azure key is supplied', () {
      // With empty or placeholder key, isAzureConfigured is false
      expect(
        service.isAzureConfigured,
        ApiConstants.azureSubscriptionKey.isNotEmpty &&
            ApiConstants.azureSubscriptionKey != 'TWOJ_KLUCZ_AZURE',
      );
    });

    test('returns existing targetAudioPath without network call', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_target_audio.mp3');
      await tempFile.writeAsString('dummy mp3 content');

      try {
        final sentence = Sentence(
          id: 'test_1',
          sourceText: 'Cześć',
          targetText: 'こんにちは',
          phoneticReading: 'Konnichiwa',
          targetAudioPath: tempFile.path,
        );

        final result = await service.ensureTargetAudio(sentence);
        expect(result, equals(tempFile.path));
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    test('returns existing translationAudioPath without network call', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_trans_audio.mp3');
      await tempFile.writeAsString('dummy mp3 translation content');

      try {
        final sentence = Sentence(
          id: 'test_2',
          sourceText: 'Dziękuję',
          targetText: 'ありがとう',
          phoneticReading: 'Arigatou',
          translationAudioPath: tempFile.path,
        );

        final result = await service.ensureTranslationAudio(sentence);
        expect(result, equals(tempFile.path));
      } finally {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });
  });
}
