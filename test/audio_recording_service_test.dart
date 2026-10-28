import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:language_islands_app/core/services/audio_recording_service.dart';
import 'package:language_islands_app/core/services/mock_audio_recording_service.dart';

void main() {
  late Directory tempDir;
  late MockAudioRecordingService recordingService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('voice_rec_test_');
    recordingService = MockAudioRecordingService(customDocsDir: tempDir);
  });

  tearDown(() async {
    recordingService.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MockAudioRecordingService Tests', () {
    test('hasPermission returns true by default and false when set to false', () async {
      expect(await recordingService.hasPermission(), isTrue);

      recordingService.hasPermissionResult = false;
      expect(await recordingService.hasPermission(), isFalse);
    });

    test('startRecording throws AudioRecordingPermissionException when hasPermission is false', () async {
      recordingService.hasPermissionResult = false;
      expect(
        () => recordingService.startRecording(
          sentenceId: 's_perm',
          isTargetLanguage: true,
        ),
        throwsA(isA<AudioRecordingPermissionException>()),
      );
    });

    test('startRecording and stopRecording create audio file with mock bytes', () async {
      final path = await recordingService.startRecording(
        sentenceId: 's_test_1',
        isTargetLanguage: true,
      );

      expect(await recordingService.isRecording(), isTrue);
      expect(path, contains('rec_s_test_1_target.m4a'));

      final stoppedPath = await recordingService.stopRecording();
      expect(stoppedPath, equals(path));
      expect(await recordingService.isRecording(), isFalse);

      final file = File(path);
      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, 'MOCK_AUDIO_DATA_FOR_s_test_1');
    });

    test('cancelRecording terminates recording and deletes created file', () async {
      final path = await recordingService.startRecording(
        sentenceId: 's_cancel',
        isTargetLanguage: false,
      );
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString('temporary data');
      expect(await file.exists(), isTrue);

      await recordingService.cancelRecording();
      expect(await recordingService.isRecording(), isFalse);
      expect(await file.exists(), isFalse);
    });

    test('saveBase64ToAudioFile decodes base64 and writes to disk', () async {
      final sampleText = 'Test voice recording bytes';
      final base64String = base64Encode(utf8.encode(sampleText));

      final savedPath = await recordingService.saveBase64ToAudioFile(
        base64Data: base64String,
        sentenceId: 's_b64',
        isTargetLanguage: true,
      );

      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      final readBytes = await file.readAsBytes();
      expect(utf8.decode(readBytes), sampleText);

      // Verify convertAudioFileToBase64 round-trips correctly
      final roundtripB64 = await recordingService.convertAudioFileToBase64(savedPath);
      expect(roundtripB64, base64String);
    });

    test('convertAudioFileToBase64 throws FileNotFoundException when file is missing', () async {
      expect(
        () => recordingService.convertAudioFileToBase64('/invalid/non_existent_path.m4a'),
        throwsA(isA<FileNotFoundException>()),
      );
    });

    test('deleteRecordingFile removes file from disk and cache', () async {
      final savedPath = await recordingService.saveBase64ToAudioFile(
        base64Data: base64Encode([1, 2, 3, 4]),
        sentenceId: 's_del',
        isTargetLanguage: true,
      );

      expect(await File(savedPath).exists(), isTrue);

      await recordingService.deleteRecordingFile(
        sentenceId: 's_del',
        isTargetLanguage: true,
      );

      expect(await File(savedPath).exists(), isFalse);
    });
  });
}
