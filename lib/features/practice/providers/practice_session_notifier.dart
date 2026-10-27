import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/app_language.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
import 'package:language_islands_app/core/services/audio_playback_service.dart';
import 'package:language_islands_app/core/services/audio_session_bootstrap.dart';
import 'package:language_islands_app/core/services/pip_service.dart';
import 'package:language_islands_app/features/collections/providers/collections_controller.dart';
import 'package:language_islands_app/features/metrics/providers/metrics_controller.dart';
import 'package:language_islands_app/features/practice/pause_between_reps.dart';
import 'package:language_islands_app/features/practice/playback_speed.dart';
import 'package:language_islands_app/features/practice/providers/practice_session_state.dart';
import 'package:language_islands_app/features/practice/recall_thinking_duration.dart';

final practiceSessionProvider =
    NotifierProvider<PracticeSessionNotifier, PracticeSessionState?>(
      PracticeSessionNotifier.new,
    );

class PracticeSessionNotifier extends Notifier<PracticeSessionState?> {
  int _loopToken = 0;
  bool _isLoopRunning = false;
  String? _manualSkipToSentenceId;
  late AudioPlaybackService _playback;

  @override
  PracticeSessionState? build() {
    _playback = ref.read(audioPlaybackServiceProvider);
    final pip = ref.read(pipServiceProvider);
    pip.onStartedExternally = _handlePipStartedExternally;
    pip.onStoppedExternally = _handlePipStoppedExternally;
    ref.onDispose(() {
      pip.onStartedExternally = null;
      pip.onStoppedExternally = null;
      unawaited(pip.stop());
    });
    ref.onDispose(_disposePlayback);
    return null;
  }

  PipService get _pip => ref.read(pipServiceProvider);

  void _disposePlayback() {
    _manualSkipToSentenceId = null;
    _loopToken++;
    _isLoopRunning = false;
    _playback.stop();
    unawaited(_playback.stopBackgroundKeepAlive());
    unawaited(releaseAppAudioSession());
  }

  void startSession(SentenceCollection collection) {
    final repo = ref.read(languageSettingsRepositoryProvider);
    final defaultTransLang = repo.currentDefaultTranslationLanguage;
    final defaultTargetLang = repo.currentDefaultTargetLanguage;

    final initialTargetLang = collection.targetLanguage ?? defaultTargetLang;
    final initialTransLang = collection.translationLanguage ?? defaultTransLang;

    state = PracticeSessionState(
      collection: collection,
      mode: PracticeMode.shadowing,
      activeSentenceId: collection.sentences.firstOrNull?.id,
      targetLanguage: initialTargetLang,
      translationLanguage: initialTransLang,
    );
  }

  void endSession() {
    pauseContinuousPlayback();
    unawaited(_pip.stop());
    state = null;
  }

  void setMode(PracticeMode mode) {
    final current = state;
    if (current == null) return;
    if (mode != current.mode) {
      pauseContinuousPlayback();
    }
    state = current.copyWith(
      mode: mode,
      revealedSentenceIds: {},
      clearAudioError: true,
    );
  }

  void toggleReveal(String sentenceId) {
    final current = state;
    if (current == null) return;
    final next = Set<String>.from(current.revealedSentenceIds);
    if (next.contains(sentenceId)) {
      next.remove(sentenceId);
    } else {
      next.add(sentenceId);
    }
    state = current.copyWith(revealedSentenceIds: next);
  }

  Future<void> playSentenceAudio(Sentence sentence) async {
    final current = state;
    if (current == null) return;

    if (current.isPlayingContinuous) {
      pauseContinuousPlayback();
    }

    state = current.copyWith(
      activeSentenceId: sentence.id,
      clearAudioError: true,
    );
    await _publishPipRevealed(sentence);

    try {
      final playback = ref.read(audioPlaybackServiceProvider);

      if (current.audioTranslationMode != AudioTranslationMode.disabled) {
        final translationPath = await _ensureTranslationAudioPath(sentence);
        if (translationPath != null) {
          state = state?.copyWith(
            activeAudioChannel: ActiveAudioChannel.translation,
          );
          final duration = await playback.playFileUntilComplete(
            translationPath,
            speed: current.playbackSpeed,
          );
          await _logListeningTime(duration);
          state = state?.copyWith(activeAudioChannel: ActiveAudioChannel.none);
          await Future<void>.delayed(current.pauseBetweenLanguages);
        } else {
          debugPrint(
            'Ostrzeżenie: Brak audio tłumaczenia dla zdania "${sentence.id}". '
            'Fallback do trybu Target-only.',
          );
        }
      }

      final targetPath = await _ensureTargetAudioPath(sentence);
      if (targetPath == null || state == null) return;

      state = state?.copyWith(activeAudioChannel: ActiveAudioChannel.target);
      final targetDuration = await playback.playFile(
        targetPath,
        speed: state!.playbackSpeed,
      );
      await _logListeningTime(targetDuration);
      state = state?.copyWith(activeAudioChannel: ActiveAudioChannel.none);
      ref.invalidate(collectionsControllerProvider);
    } catch (error) {
      state = state?.copyWith(
        audioError: error.toString(),
        activeAudioChannel: ActiveAudioChannel.none,
      );
    }
  }

  void updateActiveAudioChannel(ActiveAudioChannel channel) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(activeAudioChannel: channel);
  }

  void clearAudioError() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(clearAudioError: true);
  }

  Future<void> rateSentence(Sentence sentence, int stars) async {
    final current = state;
    if (current == null) return;

    final clamped = stars.clamp(0, 5);
    final updated = switch (current.mode) {
      PracticeMode.shadowing => sentence.copyWith(comprehensionScore: clamped),
      PracticeMode.recall => sentence.copyWith(speakingScore: clamped),
    };

    final repo = ref.read(collectionRepositoryProvider);
    await repo.updateSentence(current.collection.id, updated);
    final refreshed =
        await repo.getById(current.collection.id) ?? current.collection;

    if (current.mode == PracticeMode.recall) {
      await _logSpeakingRating(sentence.id, clamped);
    }
    await _logSentenceRating(
      sentence: sentence,
      stars: clamped,
      mode: current.mode == PracticeMode.shadowing
          ? 'Shadowing'
          : 'Active Recall',
    );

    var practiced = Set<String>.from(current.sessionPracticedSentenceIds);
    practiced.add(sentence.id);

    var mastered = Set<String>.from(current.sessionMasteredSentenceIds);
    if (current.mode == PracticeMode.recall && clamped == 5) {
      mastered.add(sentence.id);
    } else if (current.mode == PracticeMode.recall) {
      mastered.remove(sentence.id);
    }

    state = current.copyWith(
      collection: refreshed,
      sessionPracticedSentenceIds: practiced,
      sessionMasteredSentenceIds: mastered,
    );
    ref.invalidate(collectionsControllerProvider);
    ref.invalidate(metricsControllerProvider);
  }

  Future<void> updateSentenceNotes(String sentenceId, String? notes) async {
    final current = state;
    if (current == null) return;

    final index = current.collection.sentences.indexWhere(
      (s) => s.id == sentenceId,
    );
    if (index < 0) return;

    final sentence = current.collection.sentences[index];
    final trimmed = notes?.trim();
    final updated = sentence.copyWith(
      notes: trimmed,
      clearNotes: trimmed == null || trimmed.isEmpty,
    );

    final repo = ref.read(collectionRepositoryProvider);
    await repo.updateSentence(current.collection.id, updated);

    final refreshed =
        await repo.getById(current.collection.id) ?? current.collection;

    state = current.copyWith(collection: refreshed);
    ref.invalidate(collectionsControllerProvider);
  }

  Future<void> updateSentence(Sentence updatedSentence) async {
    final current = state;
    if (current == null) return;

    final repo = ref.read(collectionRepositoryProvider);
    await repo.updateSentence(current.collection.id, updatedSentence);

    final refreshed =
        await repo.getById(current.collection.id) ?? current.collection;

    state = current.copyWith(collection: refreshed);
    ref.invalidate(collectionsControllerProvider);
  }

  Future<void> addSentence(Sentence newSentence) async {
    final current = state;
    if (current == null) return;

    final repo = ref.read(collectionRepositoryProvider);
    await repo.addSentence(current.collection.id, newSentence);

    final refreshed =
        await repo.getById(current.collection.id) ?? current.collection;

    state = current.copyWith(collection: refreshed);
    ref.invalidate(collectionsControllerProvider);
  }

  Future<void> deleteSentence(String sentenceId) async {
    final current = state;
    if (current == null) return;

    final repo = ref.read(collectionRepositoryProvider);
    await repo.deleteSentence(current.collection.id, sentenceId);

    final refreshed =
        await repo.getById(current.collection.id) ?? current.collection;

    final nextActive =
        refreshed.sentences.any((s) => s.id == current.activeSentenceId)
        ? current.activeSentenceId
        : refreshed.sentences.firstOrNull?.id;

    state = current.copyWith(
      collection: refreshed,
      activeSentenceId: nextActive,
      clearActiveSentenceId: nextActive == null,
    );
    ref.invalidate(collectionsControllerProvider);
  }

  void setActiveSentenceIndex(int index) {
    final current = state;
    if (current == null) return;
    final sentences = current.visibleSentences;
    if (sentences.isEmpty) return;
    final clamped = index.clamp(0, sentences.length - 1);
    state = current.copyWith(activeSentenceId: sentences[clamped].id);
  }

  void toggleWeakSentencesFilter() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      filterOnlyWeakSentences: !current.filterOnlyWeakSentences,
    );
  }

  void cycleRecallThinkingDuration() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      recallThinkingDuration: RecallThinkingDuration.cycle(
        current.recallThinkingDuration,
      ),
    );
  }

  Future<void> revealSentenceForFocus(Sentence sentence) async {
    final current = state;
    if (current == null) return;

    final nextRevealed = Set<String>.from(current.revealedSentenceIds);
    final wasRevealed = nextRevealed.contains(sentence.id);
    if (!wasRevealed) {
      nextRevealed.add(sentence.id);
      state = current.copyWith(revealedSentenceIds: nextRevealed);
      if (current.mode == PracticeMode.recall) {
        await playSentenceAudio(sentence);
      }
      return;
    }

    await playSentenceAudio(sentence);
  }

  Future<void> startContinuousPlayback({String? startFromSentenceId}) async {
    final current = state;
    if (current == null || current.isPlayingContinuous || _isLoopRunning) {
      return;
    }

    _isLoopRunning = true;
    final token = _loopToken;
    state = current.copyWith(
      isPlayingContinuous: true,
      currentRep: 0,
      clearAudioError: true,
    );

    try {
      await ensureAppAudioSessionActive();
      unawaited(
        ref.read(audioPlaybackServiceProvider).startBackgroundKeepAlive(),
      );
      await _runContinuousLoop(token, startFromSentenceId);
    } finally {
      _isLoopRunning = false;
      if (token == _loopToken) {
        unawaited(
          ref.read(audioPlaybackServiceProvider).stopBackgroundKeepAlive(),
        );
      }
      final after = state;
      if (after != null && after.isPlayingContinuous && token == _loopToken) {
        state = after.copyWith(
          isPlayingContinuous: false,
          currentRep: 0,
          activeAudioChannel: ActiveAudioChannel.none,
        );
      }
    }
  }

  void pauseContinuousPlayback() {
    _manualSkipToSentenceId = null;
    _loopToken++;
    _isLoopRunning = false;
    final playback = ref.read(audioPlaybackServiceProvider);
    playback.stop();
    unawaited(playback.stopBackgroundKeepAlive());
    unawaited(releaseAppAudioSession());
    final current = state;
    if (current == null) return;
    unawaited(_pip.clearContent());
    state = current.copyWith(
      isPlayingContinuous: false,
      currentRep: 0,
      activeAudioChannel: ActiveAudioChannel.none,
    );
  }

  Future<void> togglePictureInPicture() async {
    final current = state;
    if (current == null) return;

    final pip = _pip;
    if (current.isPipActive) {
      await pip.stop();
      final after = state;
      if (after != null) {
        state = after.copyWith(isPipActive: false);
      }
      return;
    }

    await _publishPipStyle();
    final started = await pip.start();
    final after = state;
    if (after == null) {
      if (started) await pip.stop();
      return;
    }
    state = after.copyWith(isPipActive: started);
    if (!started) return;

    final sentence = _activeSentence();
    if (sentence == null) return;
    if (after.mode == PracticeMode.shadowing ||
        after.revealedSentenceIds.contains(sentence.id)) {
      await _publishPipRevealed(sentence);
    } else {
      await _publishPipThinking(sentence);
    }
  }

  void cyclePipWindowSize() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(pipWindowSize: current.pipWindowSize.next);
    unawaited(_publishPipStyle());
  }

  void cyclePipFontSize() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(pipFontSize: current.pipFontSize.next);
    unawaited(_publishPipStyle());
  }

  void cyclePipTranslationSize() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      pipTranslationSize: current.pipTranslationSize.next,
    );
    unawaited(_publishPipStyle());
  }

  void togglePipTranslationAlignment() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      pipTranslationUnderPhonetics: !current.pipTranslationUnderPhonetics,
    );
    unawaited(_publishPipStyle());
  }

  Future<void> _publishPipStyle() async {
    final current = state;
    if (current == null) return;
    await _pip.updateStyle(
      windowWidth: current.pipWindowSize.width,
      windowHeight:
          current.pipWindowSize.height +
          (current.pipTranslationSize.delta * 2.0),
      fontDelta: current.pipWindowSize.fontDelta + current.pipFontSize.delta,
      translationSizeDelta: current.pipTranslationSize.delta,
      alignUnderPhonetics: current.pipTranslationUnderPhonetics,
    );
  }

  void _handlePipStartedExternally() {
    final current = state;
    if (current == null || current.isPipActive) return;
    state = current.copyWith(isPipActive: true);
  }

  void _handlePipStoppedExternally() {
    final current = state;
    if (current == null || !current.isPipActive) return;
    state = current.copyWith(isPipActive: false);
  }

  Sentence? _activeSentence() {
    final current = state;
    if (current == null) return null;
    final sentences = current.visibleSentences;
    if (sentences.isEmpty) return null;
    final index = _sentenceIndexForId(sentences, current.activeSentenceId);
    return sentences[index];
  }

  Future<void> _publishPipRevealed(Sentence sentence) async {
    if (state?.isPipActive != true) return;
    await _pip.updateContent(
      primaryText: sentence.targetText,
      phoneticText: sentence.phoneticReading,
      translationText: sentence.sourceText,
    );
  }

  Future<void> _publishPipThinking(Sentence sentence) async {
    if (state?.isPipActive != true) return;
    await _pip.updateContent(
      primaryText: '???',
      translationText: sentence.sourceText,
    );
  }

  void setAudioTranslationMode(AudioTranslationMode mode) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(audioTranslationMode: mode);
  }

  void cycleAudioTranslationMode() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      audioTranslationMode: current.audioTranslationMode.next,
    );
  }

  Future<void> setTranslationLanguage(String langCode) async {
    final current = state;
    if (current == null) return;
    if (current.translationLanguage == langCode) return;

    state = current.copyWith(translationLanguage: langCode);

    final updatedCollection = current.collection.copyWith(
      translationLanguage: langCode,
    );
    final repo = ref.read(collectionRepositoryProvider);
    await repo.updateCollection(updatedCollection);
    state = state?.copyWith(collection: updatedCollection);
    ref.invalidate(collectionsControllerProvider);
  }

  Future<void> setTargetLanguage(String langCode) async {
    final current = state;
    if (current == null) return;
    if (current.targetLanguage == langCode) return;

    state = current.copyWith(targetLanguage: langCode);

    final updatedCollection = current.collection.copyWith(
      targetLanguage: langCode,
    );
    final repo = ref.read(collectionRepositoryProvider);
    await repo.updateCollection(updatedCollection);
    state = state?.copyWith(collection: updatedCollection);
    ref.invalidate(collectionsControllerProvider);
  }

  void setTargetReps(int reps) {
    setRepsPerSentence(reps);
  }

  void setRepsPerSentence(int reps) {
    final current = state;
    if (current == null) return;
    final clamped = reps.clamp(1, 5);
    state = current.copyWith(repsPerSentence: clamped);
  }

  void cycleRepsPerSentence() {
    final current = state;
    if (current == null) return;
    final next = (current.repsPerSentence % 5) + 1;
    setRepsPerSentence(next);
  }

  void setPauseBetweenLanguages(Duration duration) {
    final current = state;
    if (current == null) return;
    final clampedMs = duration.inMilliseconds.clamp(500, 3000);
    state = current.copyWith(
      pauseBetweenLanguages: Duration(milliseconds: clampedMs),
    );
  }

  void setPauseBetweenSentences(Duration duration) {
    final current = state;
    if (current == null) return;
    final clampedMs = duration.inMilliseconds.clamp(500, 4000);
    state = current.copyWith(
      pauseBetweenSentences: Duration(milliseconds: clampedMs),
    );
  }

  void setPauseBetweenReps(Duration duration) {
    final current = state;
    if (current == null) return;
    final clampedMs = duration.inMilliseconds.clamp(250, 4000);
    state = current.copyWith(
      pauseBetweenReps: Duration(milliseconds: clampedMs),
    );
  }

  void cyclePauseBetweenReps() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      pauseBetweenReps: PauseBetweenReps.cycle(current.pauseBetweenReps),
    );
  }

  void skipToNextSentence() {
    final current = state;
    if (current == null) return;
    final sentences = current.visibleSentences;
    if (sentences.isEmpty) return;

    final currentIndex = _sentenceIndexForId(
      sentences,
      current.activeSentenceId,
    );
    final nextIndex = (currentIndex + 1) % sentences.length;
    final nextSentence = sentences[nextIndex];

    if (current.isPlayingContinuous) {
      _manualSkipToSentenceId = nextSentence.id;
      state = current.copyWith(
        activeSentenceId: nextSentence.id,
        activeAudioChannel: ActiveAudioChannel.none,
      );
      ref.read(audioPlaybackServiceProvider).stop();
    } else {
      state = current.copyWith(activeSentenceId: nextSentence.id);
    }
  }

  void skipToPreviousSentence() {
    final current = state;
    if (current == null) return;
    final sentences = current.visibleSentences;
    if (sentences.isEmpty) return;

    final currentIndex = _sentenceIndexForId(
      sentences,
      current.activeSentenceId,
    );
    final prevIndex = (currentIndex - 1 + sentences.length) % sentences.length;
    final prevSentence = sentences[prevIndex];

    if (current.isPlayingContinuous) {
      _manualSkipToSentenceId = prevSentence.id;
      state = current.copyWith(
        activeSentenceId: prevSentence.id,
        activeAudioChannel: ActiveAudioChannel.none,
      );
      ref.read(audioPlaybackServiceProvider).stop();
    } else {
      state = current.copyWith(activeSentenceId: prevSentence.id);
    }
  }

  void setPlaybackSpeed(double speed) {
    final current = state;
    if (current == null) return;
    final snapped = PlaybackSpeed.snapToPreset(speed);
    state = current.copyWith(playbackSpeed: snapped);
    ref.read(audioPlaybackServiceProvider).setSpeed(snapped);
  }

  void cycleLoopMode() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(loopMode: current.loopMode.next);
  }

  bool _shouldContinueLoop(int token) {
    return state?.isPlayingContinuous == true &&
        token == _loopToken &&
        _manualSkipToSentenceId == null;
  }

  int _sentenceIndexForId(List<Sentence> sentences, String? id) {
    if (id == null) return 0;
    final index = sentences.indexWhere((s) => s.id == id);
    return index >= 0 ? index : 0;
  }

  Future<void> _runContinuousLoop(
    int token,
    String? startFromSentenceId,
  ) async {
    var currentId = startFromSentenceId ?? state!.activeSentenceId;

    if (state!.visibleSentences.isEmpty) {
      pauseContinuousPlayback();
      return;
    }

    while (_shouldContinueLoop(token)) {
      final sentences = state!.visibleSentences;
      if (sentences.isEmpty) {
        pauseContinuousPlayback();
        return;
      }

      final sentenceIndex = _sentenceIndexForId(sentences, currentId);
      final sentence = sentences[sentenceIndex];

      if (state!.mode == PracticeMode.recall) {
        await _runRecallSentence(sentence, token);
      } else {
        await _runShadowingSentence(sentence, token);
      }

      if (_manualSkipToSentenceId != null) {
        currentId = _manualSkipToSentenceId!;
        _manualSkipToSentenceId = null;
        continue;
      }
      if (!_shouldContinueLoop(token)) return;

      // Scenariusz A krok 4 / Scenariusz B krok 2: Odczekaj pauseBetweenSentencesMs i przejdź do następnego zdania
      await _interruptibleDelay(state!.pauseBetweenSentences, token);
      if (_manualSkipToSentenceId != null) {
        currentId = _manualSkipToSentenceId!;
        _manualSkipToSentenceId = null;
        continue;
      }
      if (!_shouldContinueLoop(token)) return;

      if (state!.mode == PracticeMode.shadowing &&
          state!.isSingleSentenceLoop) {
        currentId = sentence.id;
        continue;
      }

      final nextList = state!.visibleSentences;
      final idx = nextList.indexWhere((s) => s.id == sentence.id);
      if (idx < 0) {
        if (nextList.isEmpty) {
          pauseContinuousPlayback();
          return;
        }
        currentId = nextList.first.id;
        continue;
      }
      if (idx >= nextList.length - 1) {
        if (state!.isListLoopEnabled) {
          currentId = nextList.first.id;
          continue;
        }
        pauseContinuousPlayback();
        return;
      }
      currentId = nextList[idx + 1].id;
    }
  }

  Future<void> _runShadowingSentence(Sentence sentence, int token) async {
    state = state!.copyWith(activeSentenceId: sentence.id);
    await _publishPipRevealed(sentence);
    if (!_shouldContinueLoop(token)) return;

    await _runSentenceSequence(
      sentence: sentence,
      token: token,
      isRecallMode: false,
    );
  }

  Future<void> _runRecallSentence(Sentence sentence, int token) async {
    final hidden = Set<String>.from(state!.revealedSentenceIds)
      ..remove(sentence.id);
    state = state!.copyWith(
      activeSentenceId: sentence.id,
      revealedSentenceIds: hidden,
    );
    await _publishPipThinking(sentence);
    if (!_shouldContinueLoop(token)) return;

    await _runSentenceSequence(
      sentence: sentence,
      token: token,
      isRecallMode: true,
    );
  }

  Future<void> _runSentenceSequence({
    required Sentence sentence,
    required int token,
    required bool isRecallMode,
  }) async {
    try {
      final targetPath = await _ensureTargetAudioPath(sentence);
      if (!_shouldContinueLoop(token)) return;
      if (targetPath == null) {
        pauseContinuousPlayback();
        return;
      }

      final playback = ref.read(audioPlaybackServiceProvider);
      var translationMode = state!.audioTranslationMode;
      String? translationPath;

      if (translationMode != AudioTranslationMode.disabled) {
        translationPath = await _ensureTranslationAudioPath(sentence);
        if (!_shouldContinueLoop(token)) return;
        if (translationPath == null) {
          debugPrint(
            'Ostrzeżenie: Brak audio tłumaczenia dla zdania "${sentence.id}". '
            'Fallback do trybu Target-only.',
          );
          translationMode = AudioTranslationMode.disabled;
        }
      }

      final reps = state!.targetReps;

      switch (translationMode) {
        case AudioTranslationMode.prefix:
          // Scenariusz A: prefix (1x PL -> N x JP)
          // 1. Odtwórz translationAudio (1x)
          state = state!.copyWith(
            activeAudioChannel: ActiveAudioChannel.translation,
          );
          final tDuration = await playback.playFileUntilComplete(
            translationPath!,
            speed: state!.playbackSpeed,
          );
          await _logListeningTime(tDuration);
          state = state!.copyWith(activeAudioChannel: ActiveAudioChannel.none);
          if (!_shouldContinueLoop(token)) return;

          // 2. Odczekaj pauseBetweenLanguagesMs
          await _interruptibleDelay(state!.pauseBetweenLanguages, token);
          if (!_shouldContinueLoop(token)) return;

          // Odkryj zdanie w trybie recall po pauzie Active Recall
          if (isRecallMode) {
            final revealed = Set<String>.from(state!.revealedSentenceIds)
              ..add(sentence.id);
            state = state!.copyWith(revealedSentenceIds: revealed);
            await _publishPipRevealed(sentence);
            if (!_shouldContinueLoop(token)) return;
          }

          // 3. Pętla i od 1 do targetReps
          for (var rep = 1; rep <= reps; rep++) {
            if (!_shouldContinueLoop(token)) return;
            state = state!.copyWith(
              currentRep: rep,
              activeAudioChannel: ActiveAudioChannel.target,
            );

            final duration = await playback.playFileUntilComplete(
              targetPath,
              speed: state!.playbackSpeed,
            );
            state = state!.copyWith(
              activeAudioChannel: ActiveAudioChannel.none,
            );
            if (!_shouldContinueLoop(token)) return;

            await _logListeningTime(duration);
            await _incrementSentenceReps(sentence.id);
            if (!_shouldContinueLoop(token)) return;

            if (rep < reps) {
              await _interruptibleDelay(state!.pauseBetweenReps, token);
            }
          }
          break;

        case AudioTranslationMode.alternating:
          // Scenariusz B: alternating (PL -> JP -> PL -> JP...)
          for (var rep = 1; rep <= reps; rep++) {
            if (!_shouldContinueLoop(token)) return;
            state = state!.copyWith(currentRep: rep);

            // a. Odtwórz translationAudio
            state = state!.copyWith(
              activeAudioChannel: ActiveAudioChannel.translation,
            );
            final tDuration = await playback.playFileUntilComplete(
              translationPath!,
              speed: state!.playbackSpeed,
            );
            await _logListeningTime(tDuration);
            state = state!.copyWith(
              activeAudioChannel: ActiveAudioChannel.none,
            );
            if (!_shouldContinueLoop(token)) return;

            // b. Odczekaj pauseBetweenLanguagesMs
            await _interruptibleDelay(state!.pauseBetweenLanguages, token);
            if (!_shouldContinueLoop(token)) return;

            if (isRecallMode && rep == 1) {
              final revealed = Set<String>.from(state!.revealedSentenceIds)
                ..add(sentence.id);
              state = state!.copyWith(revealedSentenceIds: revealed);
              await _publishPipRevealed(sentence);
              if (!_shouldContinueLoop(token)) return;
            }

            // c. Odtwórz targetAudio
            state = state!.copyWith(
              activeAudioChannel: ActiveAudioChannel.target,
            );
            final duration = await playback.playFileUntilComplete(
              targetPath,
              speed: state!.playbackSpeed,
            );
            state = state!.copyWith(
              activeAudioChannel: ActiveAudioChannel.none,
            );
            if (!_shouldContinueLoop(token)) return;

            await _logListeningTime(duration);
            await _incrementSentenceReps(sentence.id);
            if (!_shouldContinueLoop(token)) return;

            // d. Jeśli i < targetReps, odczekaj pauseBetweenRepsMs
            if (rep < reps) {
              await _interruptibleDelay(state!.pauseBetweenReps, token);
            }
          }
          break;

        case AudioTranslationMode.disabled:
          // Tryb standardowy (tylko język docelowy)
          if (isRecallMode) {
            await _interruptibleDelay(state!.recallThinkingDuration, token);
            if (!_shouldContinueLoop(token)) return;

            final revealed = Set<String>.from(state!.revealedSentenceIds)
              ..add(sentence.id);
            state = state!.copyWith(revealedSentenceIds: revealed);
            await _publishPipRevealed(sentence);
            if (!_shouldContinueLoop(token)) return;
          }

          for (var rep = 1; rep <= reps; rep++) {
            if (!_shouldContinueLoop(token)) return;
            state = state!.copyWith(
              currentRep: rep,
              activeAudioChannel: ActiveAudioChannel.target,
            );

            final duration = await playback.playFileUntilComplete(
              targetPath,
              speed: state!.playbackSpeed,
            );
            state = state!.copyWith(
              activeAudioChannel: ActiveAudioChannel.none,
            );
            if (!_shouldContinueLoop(token)) return;

            await _logListeningTime(duration);
            await _incrementSentenceReps(sentence.id);
            if (!_shouldContinueLoop(token)) return;

            if (rep < reps) {
              await _interruptibleDelay(state!.pauseBetweenReps, token);
            }
          }
          break;
      }
    } catch (error) {
      state = state?.copyWith(
        audioError: error.toString(),
        activeAudioChannel: ActiveAudioChannel.none,
      );
      pauseContinuousPlayback();
    }
  }

  Future<void> _interruptibleDelay(Duration duration, [int? token]) async {
    final loopToken = token ?? _loopToken;
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      if (!_shouldContinueLoop(loopToken)) return;
      final remaining = end.difference(DateTime.now());
      final step = remaining > const Duration(milliseconds: 80)
          ? const Duration(milliseconds: 80)
          : remaining;
      if (step <= Duration.zero) return;
      await Future<void>.delayed(step);
    }
  }

  Future<String?> _ensureTargetAudioPath(Sentence sentence) async {
    final current = state;
    if (current == null) return null;

    if (sentence.hasCustomTargetAudio && sentence.targetAudioPath != null) {
      final file = File(sentence.targetAudioPath!);
      if (await file.exists()) {
        return file.path;
      }
    }

    final tts = ref.read(azureTtsServiceProvider);
    final repo = ref.read(collectionRepositoryProvider);

    final lang =
        AppLanguage.fromCode(current.targetLanguage) ??
        AppLanguage.fromCode('ja') ??
        AppLanguage.defaultLanguage;

    final path = await tts.ensureTargetAudio(
      sentence,
      targetLanguageCode: lang.code,
      voiceName: lang.voiceName,
      locale: lang.locale,
    );
    if (path != sentence.targetAudioPath) {
      final withPath = sentence.copyWith(targetAudioPath: path);
      await repo.updateSentence(current.collection.id, withPath);

      final refreshed =
          await repo.getById(current.collection.id) ?? current.collection;
      state = state?.copyWith(collection: refreshed);
      ref.invalidate(collectionsControllerProvider);
    }

    return path;
  }

  Future<String?> _ensureTranslationAudioPath(Sentence sentence) async {
    final current = state;
    if (current == null) return null;

    if (sentence.hasCustomTranslationAudio &&
        sentence.translationAudioPath != null) {
      final file = File(sentence.translationAudioPath!);
      if (await file.exists()) {
        return file.path;
      }
    }

    final tts = ref.read(azureTtsServiceProvider);
    final repo = ref.read(collectionRepositoryProvider);

    final lang =
        AppLanguage.fromCode(current.translationLanguage) ??
        AppLanguage.defaultLanguage;

    final path = await tts.ensureTranslationAudio(
      sentence,
      voiceName: lang.voiceName,
      locale: lang.locale,
    );
    if (path != null && path != sentence.translationAudioPath) {
      final withPath = sentence.copyWith(translationAudioPath: path);
      await repo.updateSentence(current.collection.id, withPath);

      final refreshed =
          await repo.getById(current.collection.id) ?? current.collection;
      state = state?.copyWith(collection: refreshed);
      ref.invalidate(collectionsControllerProvider);
    }

    return path;
  }

  Future<void> _incrementSentenceReps(String sentenceId) async {
    final current = state;
    if (current == null) return;

    final index = current.collection.sentences.indexWhere(
      (s) => s.id == sentenceId,
    );
    if (index < 0) return;
    final sentence = current.collection.sentences[index];

    final updated = sentence.copyWith(totalReps: sentence.totalReps + 1);
    final repo = ref.read(collectionRepositoryProvider);
    await repo.updateSentence(current.collection.id, updated);

    final refreshed =
        await repo.getById(current.collection.id) ?? current.collection;

    var practiced = Set<String>.from(state!.sessionPracticedSentenceIds);
    practiced.add(sentenceId);

    state = state!.copyWith(
      collection: refreshed,
      sessionPracticedSentenceIds: practiced,
      sessionRepsCount: state!.sessionRepsCount + 1,
    );
    await _logRepetition(
      sentenceId,
      targetText: sentence.targetText,
      sourceText: sentence.sourceText,
      mode: current.mode == PracticeMode.shadowing
          ? 'Shadowing'
          : 'Active Recall',
    );
    ref.invalidate(collectionsControllerProvider);
    ref.invalidate(metricsControllerProvider);
  }

  int _secondsFromDuration(Duration duration) {
    if (duration <= Duration.zero) return 0;
    final rounded = (duration.inMilliseconds / 1000).round();
    return rounded < 1 ? 1 : rounded;
  }

  Future<void> _logListeningTime(Duration duration) async {
    final seconds = _secondsFromDuration(duration);
    if (seconds <= 0) return;
    try {
      await ref
          .read(userMetricsRepositoryProvider)
          .logListeningTime(seconds: seconds);
      ref.invalidate(metricsControllerProvider);
    } on Object {
      return;
    }
  }

  Future<void> _logRepetition(
    String sentenceId, {
    String? targetText,
    String? sourceText,
    String? mode,
  }) async {
    try {
      await ref
          .read(userMetricsRepositoryProvider)
          .logRepetition(
            count: 1,
            sentenceId: sentenceId,
            targetText: targetText,
            sourceText: sourceText,
            mode: mode,
          );
      ref.invalidate(metricsControllerProvider);
    } on Object {
      return;
    }
  }

  Future<void> _logSentenceRating({
    required Sentence sentence,
    required int stars,
    required String mode,
  }) async {
    try {
      await ref
          .read(userMetricsRepositoryProvider)
          .logSentenceRating(
            sentenceId: sentence.id,
            targetText: sentence.targetText,
            sourceText: sentence.sourceText,
            stars: stars,
            mode: mode,
          );
      ref.invalidate(metricsControllerProvider);
    } on Object {
      return;
    }
  }

  Future<void> _logSpeakingRating(String sentenceId, int stars) async {
    try {
      await ref
          .read(userMetricsRepositoryProvider)
          .logSpeakingRating(sentenceId: sentenceId, stars: stars);
    } on Object {
      return;
    }
  }
}
