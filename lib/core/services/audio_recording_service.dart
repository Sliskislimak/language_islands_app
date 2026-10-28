import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

abstract class AudioRecordingService {
  Future<bool> hasPermission();
  Future<bool> isRecording();
  Future<String> startRecording({
    required String sentenceId,
    required bool isTargetLanguage,
  });
  Future<String?> stopRecording();
  Future<void> cancelRecording();
  Future<String> convertAudioFileToBase64(String filePath);
  Future<String> saveBase64ToAudioFile({
    required String base64Data,
    required String sentenceId,
    required bool isTargetLanguage,
  });
  Future<String> getRecordingPath({
    required String sentenceId,
    required bool isTargetLanguage,
  });
  Future<void> deleteRecordingFile({
    required String sentenceId,
    required bool isTargetLanguage,
  });
  void dispose();
}

class RecordAudioRecordingService implements AudioRecordingService {
  RecordAudioRecordingService({AudioRecorder? recorder})
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _currentRecordingPath;

  @override
  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('AudioRecordingService hasPermission error: $e');
      return false;
    }
  }

  @override
  Future<bool> isRecording() async {
    try {
      return await _recorder.isRecording();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String> getRecordingPath({
    required String sentenceId,
    required bool isTargetLanguage,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(p.join(docs.path, 'user_recordings'));
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final suffix = isTargetLanguage ? 'target' : 'trans';
    final safeSentenceId = sentenceId.replaceAll(RegExp(r'[^\w\-]'), '_');
    return p.join(recordingsDir.path, 'rec_${safeSentenceId}_$suffix.m4a');
  }

  @override
  Future<String> startRecording({
    required String sentenceId,
    required bool isTargetLanguage,
  }) async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw const AudioRecordingPermissionException('Brak uprawnień do korzystania z mikrofonu.');
    }

    if (await isRecording()) {
      await stopRecording();
    }

    final targetPath = await getRecordingPath(
      sentenceId: sentenceId,
      isTargetLanguage: isTargetLanguage,
    );
    _currentRecordingPath = targetPath;

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      try {
        await targetFile.delete();
      } catch (_) {}
    }

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 48000,
      sampleRate: 44100,
      numChannels: 1,
    );

    await _recorder.start(config, path: targetPath);
    return targetPath;
  }

  @override
  Future<String?> stopRecording() async {
    try {
      final recordedPath = await _recorder.stop();
      final path = recordedPath ?? _currentRecordingPath;
      _currentRecordingPath = null;
      if (path != null && await File(path).exists()) {
        return path;
      }
      return null;
    } catch (e) {
      debugPrint('AudioRecordingService stopRecording error: $e');
      _currentRecordingPath = null;
      return null;
    }
  }

  @override
  Future<void> cancelRecording() async {
    try {
      await _recorder.cancel();
      if (_currentRecordingPath != null) {
        final f = File(_currentRecordingPath!);
        if (await f.exists()) {
          await f.delete();
        }
      }
    } catch (e) {
      debugPrint('AudioRecordingService cancelRecording error: $e');
    } finally {
      _currentRecordingPath = null;
    }
  }

  @override
  Future<String> convertAudioFileToBase64(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileNotFoundException('Plik nagrania nie istnieje: $filePath');
    }
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  @override
  Future<String> saveBase64ToAudioFile({
    required String base64Data,
    required String sentenceId,
    required bool isTargetLanguage,
  }) async {
    final targetPath = await getRecordingPath(
      sentenceId: sentenceId,
      isTargetLanguage: isTargetLanguage,
    );
    final file = File(targetPath);
    await file.parent.create(recursive: true);
    final bytes = base64Decode(base64Data.trim());
    await file.writeAsBytes(bytes, flush: true);
    return targetPath;
  }

  @override
  Future<void> deleteRecordingFile({
    required String sentenceId,
    required bool isTargetLanguage,
  }) async {
    final targetPath = await getRecordingPath(
      sentenceId: sentenceId,
      isTargetLanguage: isTargetLanguage,
    );
    final file = File(targetPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
  }
}

class FileNotFoundException implements Exception {
  FileNotFoundException(this.message);
  final String message;

  @override
  String toString() => 'FileNotFoundException: $message';
}

class AudioRecordingPermissionException implements Exception {
  const AudioRecordingPermissionException([this.message = 'Brak uprawnień do korzystania z mikrofonu.']);
  final String message;

  @override
  String toString() => 'AudioRecordingPermissionException: $message';
}

final audioRecordingServiceProvider =
    Provider<AudioRecordingService>((ref) {
  final service = RecordAudioRecordingService();
  ref.onDispose(service.dispose);
  return service;
});
