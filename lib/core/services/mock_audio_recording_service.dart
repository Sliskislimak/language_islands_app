import 'dart:convert';
import 'dart:io';

import 'package:language_islands_app/core/services/audio_recording_service.dart';
import 'package:path/path.dart' as p;

class MockAudioRecordingService implements AudioRecordingService {
  MockAudioRecordingService({this.customDocsDir});

  final Directory? customDocsDir;
  bool hasPermissionResult = true;
  bool isRecordingState = false;
  String? lastRecordedPath;
  String? currentSentenceId;
  bool? currentIsTargetLanguage;

  final Map<String, String> inMemoryAudioFiles = {};

  @override
  Future<bool> hasPermission() async => hasPermissionResult;

  @override
  Future<bool> isRecording() async => isRecordingState;

  @override
  Future<String> getRecordingPath({
    required String sentenceId,
    required bool isTargetLanguage,
  }) async {
    final baseDir = customDocsDir?.path ?? Directory.systemTemp.path;
    final suffix = isTargetLanguage ? 'target' : 'trans';
    final safeSentenceId = sentenceId.replaceAll(RegExp(r'[^\w\-]'), '_');
    final dir = Directory(p.join(baseDir, 'user_recordings'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return p.join(dir.path, 'rec_${safeSentenceId}_$suffix.m4a');
  }

  @override
  Future<String> startRecording({
    required String sentenceId,
    required bool isTargetLanguage,
  }) async {
    if (!hasPermissionResult) {
      throw const SocketException('Permission denied');
    }
    isRecordingState = true;
    currentSentenceId = sentenceId;
    currentIsTargetLanguage = isTargetLanguage;
    final path = await getRecordingPath(
      sentenceId: sentenceId,
      isTargetLanguage: isTargetLanguage,
    );
    lastRecordedPath = path;
    return path;
  }

  @override
  Future<String?> stopRecording() async {
    if (!isRecordingState) return null;
    isRecordingState = false;
    final path = lastRecordedPath;
    if (path != null) {
      final f = File(path);
      await f.parent.create(recursive: true);
      // Write mock audio bytes (fake AAC header or dummy bytes)
      await f.writeAsBytes(utf8.encode('MOCK_AUDIO_DATA_FOR_$currentSentenceId'));
      inMemoryAudioFiles[path] = 'MOCK_BASE64_DATA';
    }
    return path;
  }

  @override
  Future<void> cancelRecording() async {
    isRecordingState = false;
    if (lastRecordedPath != null) {
      final f = File(lastRecordedPath!);
      if (await f.exists()) {
        await f.delete();
      }
    }
    lastRecordedPath = null;
  }

  @override
  Future<String> convertAudioFileToBase64(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (inMemoryAudioFiles.containsKey(filePath)) {
        return inMemoryAudioFiles[filePath]!;
      }
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
    inMemoryAudioFiles[targetPath] = base64Data;
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
    inMemoryAudioFiles.remove(targetPath);
  }

  @override
  void dispose() {}
}
