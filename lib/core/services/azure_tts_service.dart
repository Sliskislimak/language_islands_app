import 'dart:io';

import 'package:edge_tts/edge_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:language_islands_app/core/constants/api_constants.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Alias for [AzureTtsService], reflecting Edge TTS as primary engine.
typedef EdgeTtsService = AzureTtsService;

/// Synthesizes Japanese target audio and Polish base translation audio via
/// free Microsoft Edge Neural TTS (with optional Azure Speech REST API fallback).
///
/// Cached files are saved locally and never re-fetched once stored on disk.
class AzureTtsService {
  AzureTtsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _outputFormat = 'audio-16khz-128kbitrate-mono-mp3';

  /// Edge TTS requires no API keys, so the service is always configured.
  bool get isConfigured => true;

  /// Whether Azure Speech credentials are configured.
  bool get isAzureConfigured =>
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
  Future<String?> ensureTranslationAudio(
    Sentence sentence, {
    String? voiceName,
    String? locale,
  }) async {
    if (sentence.translationAudioPath != null) {
      final explicit = File(sentence.translationAudioPath!);
      if (await explicit.exists()) {
        return explicit.path;
      }
    }

    final effectiveVoice = voiceName ?? ApiConstants.polishVoiceName;
    final effectiveLocale = locale ?? 'pl-PL';

    final cachePath = await _translationCacheFilePath(sentence.id, effectiveVoice);
    final cacheFile = File(cachePath);
    if (await cacheFile.exists()) {
      return cachePath;
    }

    try {
      await _fetchAndSaveTranslationAudio(
        sentenceId: sentence.id,
        sourceText: sentence.sourceText,
        destination: cacheFile,
        voiceName: effectiveVoice,
        locale: effectiveLocale,
      );
      return cachePath;
    } catch (e) {
      debugPrint(
        'Nie udało się wygenerować lektora tłumaczenia dla "${sentence.id}" ($effectiveVoice): $e',
      );
      return null;
    }
  }

  Future<File> _fetchAndSaveTargetAudio({
    required String sentenceId,
    required String targetText,
    required File destination,
  }) async {
    // 1. Primary: Free Edge TTS (no API key required)
    try {
      final comm = Communicate(
        text: targetText,
        voice: ApiConstants.japaneseVoiceName,
      );
      final bytes = await comm.toBytes();
      if (bytes.isNotEmpty) {
        await destination.parent.create(recursive: true);
        await destination.writeAsBytes(bytes, flush: true);
        return destination;
      }
    } catch (e) {
      debugPrint(
        'Edge TTS target synthesis failed for "$sentenceId": $e',
      );
      if (isAzureConfigured) {
        return _fetchAndSaveTargetAudioViaAzure(
          sentenceId: sentenceId,
          targetText: targetText,
          destination: destination,
        );
      }
      rethrow;
    }

    if (isAzureConfigured) {
      return _fetchAndSaveTargetAudioViaAzure(
        sentenceId: sentenceId,
        targetText: targetText,
        destination: destination,
      );
    }

    throw StateError('Błąd syntezy audio: brak danych audio z Edge TTS.');
  }

  Future<File> _fetchAndSaveTranslationAudio({
    required String sentenceId,
    required String sourceText,
    required File destination,
    String voiceName = ApiConstants.polishVoiceName,
    String locale = 'pl-PL',
  }) async {
    // 1. Primary: Free Edge TTS (no API key required)
    try {
      final comm = Communicate(
        text: sourceText,
        voice: voiceName,
      );
      final bytes = await comm.toBytes();
      if (bytes.isNotEmpty) {
        await destination.parent.create(recursive: true);
        await destination.writeAsBytes(bytes, flush: true);
        return destination;
      }
    } catch (e) {
      debugPrint(
        'Edge TTS translation synthesis failed for "$sentenceId" ($voiceName): $e',
      );
      if (isAzureConfigured) {
        return _fetchAndSaveTranslationAudioViaAzure(
          sentenceId: sentenceId,
          sourceText: sourceText,
          destination: destination,
          voiceName: voiceName,
          locale: locale,
        );
      }
      rethrow;
    }

    if (isAzureConfigured) {
      return _fetchAndSaveTranslationAudioViaAzure(
        sentenceId: sentenceId,
        sourceText: sourceText,
        destination: destination,
        voiceName: voiceName,
        locale: locale,
      );
    }

    throw StateError(
      'Błąd syntezy tłumaczenia: brak danych audio z Edge TTS.',
    );
  }

  // ---------------------------------------------------------------------------
  // Azure Fallback Implementation
  // ---------------------------------------------------------------------------

  Future<File> _fetchAndSaveTargetAudioViaAzure({
    required String sentenceId,
    required String targetText,
    required File destination,
  }) async {
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
      if (response.statusCode == 401) {
        throw HttpException(
          'Błąd autoryzacji Azure Speech (HTTP 401): Klucz API w api_constants.dart wygasł lub został unieważniony.',
          uri: uri,
        );
      }
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

  Future<File> _fetchAndSaveTranslationAudioViaAzure({
    required String sentenceId,
    required String sourceText,
    required File destination,
    required String voiceName,
    required String locale,
  }) async {
    final uri = Uri.parse(
      'https://${ApiConstants.azureRegion}.tts.speech.microsoft.com/cognitiveservices/v1',
    );
    final ssml = _buildTranslationSsml(
      sourceText,
      voiceName: voiceName,
      locale: locale,
    );

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
      if (response.statusCode == 401) {
        throw HttpException(
          'Błąd autoryzacji Azure Speech dla lektora (HTTP 401): Klucz API w api_constants.dart wygasł lub został unieważniony.',
          uri: uri,
        );
      }
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

  String _buildTranslationSsml(
    String sourceText, {
    String voiceName = ApiConstants.polishVoiceName,
    String locale = 'pl-PL',
  }) {
    return '''
<speak version="1.0" xml:lang="$locale">
  <voice name="$voiceName">${_escapeXml(sourceText)}</voice>
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

  static Future<String> _cacheFilePath(String sentenceId) async {
    final docs = await getApplicationDocumentsDirectory();
    final safeId = sentenceId.replaceAll(RegExp(r'[^\w\-.]'), '_');
    return p.join(docs.path, 'audio_cache', 'target_$safeId.mp3');
  }

  static Future<String> _translationCacheFilePath(
    String sentenceId, [
    String? voiceName,
  ]) async {
    final docs = await getApplicationDocumentsDirectory();
    final safeId = sentenceId.replaceAll(RegExp(r'[^\w\-.]'), '_');
    final voicePrefix = voiceName != null
        ? '${voiceName.replaceAll(RegExp(r'[^\w\-.]'), '_')}_'
        : '';
    return p.join(
      docs.path,
      'audio_cache',
      'translation_$voicePrefix$safeId.mp3',
    );
  }

  void dispose() {
    _client.close();
  }
}
