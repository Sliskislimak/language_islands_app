import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:language_islands_app/core/constants/api_constants.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Synthesizes Japanese target audio and Polish base translation audio via Azure Speech REST API.
/// Cached files are never re-fetched when they already exist on disk.
class AzureTtsService {
  AzureTtsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _outputFormat = 'audio-16khz-128kbitrate-mono-mp3';

  bool get isConfigured =>
      ApiConstants.azureSubscriptionKey.isNotEmpty &&
      ApiConstants.azureSubscriptionKey != 'TWOJ_KLUCZ_AZURE';

  Future<String> ensureTargetAudio(Sentence sentence) async {
    if (sentence.targetAudioPath != null) {
      final explicit = File(sentence.targetAudioPath!);
      if (await explicit.exists()) {
        return explicit.path;
      }
    }

    final cachePath = await _cacheFilePath(sentence.id);
    final cacheFile = File(cachePath);
    if (await cacheFile.exists()) {
      return cachePath;
    }

    await _fetchAndSaveTargetAudio(
      sentenceId: sentence.id,
      targetText: sentence.targetText,
      destination: cacheFile,
    );
    return cachePath;
  }

  /// Ensures translation audio exists (either pre-recorded or synthesized on-demand).
  /// Returns null if unavailable so the player can gracefully fallback to target-only.
  Future<String?> ensureTranslationAudio(Sentence sentence) async {
    if (sentence.translationAudioPath != null) {
      final explicit = File(sentence.translationAudioPath!);
      if (await explicit.exists()) {
        return explicit.path;
      }
    }

    final cachePath = await _translationCacheFilePath(sentence.id);
    final cacheFile = File(cachePath);
    if (await cacheFile.exists()) {
      return cachePath;
    }

    if (!isConfigured) {
      debugPrint(
        'Azure TTS nie jest skonfigurowane dla lektora tłumaczenia zdania "${sentence.id}".',
      );
      return null;
    }

    try {
      await _fetchAndSaveTranslationAudio(
        sentenceId: sentence.id,
        sourceText: sentence.sourceText,
        destination: cacheFile,
      );
      return cachePath;
    } catch (e) {
      debugPrint(
        'Nie udało się wygenerować lektora tłumaczenia dla "${sentence.id}": $e',
      );
      return null;
    }
  }

  Future<File> _fetchAndSaveTargetAudio({
    required String sentenceId,
    required String targetText,
    required File destination,
  }) async {
    _assertAzureConfigured();

    final uri = Uri.parse(
      'https://${ApiConstants.azureRegion}.tts.speech.microsoft.com/cognitiveservices/v1',
    );
    final ssml = _buildSsml(targetText);

    final response = await _client.post(
      uri,
      headers: {
        'Ocp-Apim-Subscription-Key': ApiConstants.azureSubscriptionKey,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': _outputFormat,
        'User-Agent': 'LanguageIslandsApp',
      },
      body: ssml,
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'Azure TTS failed for sentence "$sentenceId" '
        '(HTTP ${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }

    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(response.bodyBytes, flush: true);
    return destination;
  }

  Future<File> _fetchAndSaveTranslationAudio({
    required String sentenceId,
    required String sourceText,
    required File destination,
  }) async {
    _assertAzureConfigured();

    final uri = Uri.parse(
      'https://${ApiConstants.azureRegion}.tts.speech.microsoft.com/cognitiveservices/v1',
    );
    final ssml = _buildTranslationSsml(sourceText);

    final response = await _client.post(
      uri,
      headers: {
        'Ocp-Apim-Subscription-Key': ApiConstants.azureSubscriptionKey,
        'Content-Type': 'application/ssml+xml',
        'X-Microsoft-OutputFormat': _outputFormat,
        'User-Agent': 'LanguageIslandsApp',
      },
      body: ssml,
    );

    if (response.statusCode != 200) {
      throw HttpException(
        'Azure Translation TTS failed for sentence "$sentenceId" '
        '(HTTP ${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }

    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(response.bodyBytes, flush: true);
    return destination;
  }

  String _buildSsml(String targetText) {
    return '''
<speak version="1.0" xml:lang="ja-JP">
  <voice name="${ApiConstants.japaneseVoiceName}">${_escapeXml(targetText)}</voice>
</speak>''';
  }

  String _buildTranslationSsml(String sourceText) {
    return '''
<speak version="1.0" xml:lang="pl-PL">
  <voice name="${ApiConstants.polishVoiceName}">${_escapeXml(sourceText)}</voice>
</speak>''';
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static void _assertAzureConfigured() {
    if (ApiConstants.azureSubscriptionKey == 'TWOJ_KLUCZ_AZURE' ||
        ApiConstants.azureSubscriptionKey.isEmpty) {
      throw StateError(
        'Skonfiguruj klucz Azure w lib/core/constants/api_constants.dart.',
      );
    }
  }

  static Future<String> _cacheFilePath(String sentenceId) async {
    final docs = await getApplicationDocumentsDirectory();
    final safeId = sentenceId.replaceAll(RegExp(r'[^\w\-.]'), '_');
    return p.join(docs.path, 'audio_cache', 'target_$safeId.mp3');
  }

  static Future<String> _translationCacheFilePath(String sentenceId) async {
    final docs = await getApplicationDocumentsDirectory();
    final safeId = sentenceId.replaceAll(RegExp(r'[^\w\-.]'), '_');
    return p.join(docs.path, 'audio_cache', 'translation_$safeId.mp3');
  }

  void dispose() {
    _client.close();
  }
}
