import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/models/practice_mode.dart';
import 'package:language_islands_app/core/models/sentence.dart';
import 'package:language_islands_app/core/models/sentence_collection.dart';
import 'package:language_islands_app/core/providers/app_providers.dart';
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

  @override
  PracticeSessionState? build() {
    final pip = ref.read(pipServiceProvider);
    pip.onStoppedExternally = _handlePipStoppedExternally;
    ref.onDispose(() {
      pip.onStoppedExternally = null;
      unawaited(pip.stop());
    });
    ref.onDispose(_disposePlayback);
    return null;
  }

  PipService get _pip => ref.read(pipServiceProvider);

  void _disposePlayback() {
    _loopToken++;
    _isLoopRunning = false;
    final playback = ref.read(audioPlaybackServiceProvider);
    playback.stop();
    unawaited(playback.stopBackgroundKeepAlive());
    unawaited(releaseAppAudioSession());
  }

  void startSession(SentenceCollection collection) {
    state = PracticeSessionState(
      collection: collection,
      mode: PracticeMode.shadowing,
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
      final path = await _ensureTargetAudioPath(sentence);
      if (path == null || state == null) return;

      final playback = ref.read(audioPlaybackServiceProvider);
      final duration = await playback.playFile(
        path,
        speed: state!.playbackSpeed,
      );
      await _logListeningTime(duration);
      ref.invalidate(collectionsControllerProvider);
    } catch (error) {
      state = state?.copyWith(audioError: error.toString());
    }
  }

  Future<void> rateSentence(Sentence sentence, int stars) async {
    final current = state;
    if (current == null) return;

    final clamped = stars.clamp(0, 5);
    final updated = switch (current.mode) {
      PracticeMode.shadowing =>
        sentence.copyWith(comprehensionScore: clamped),
      PracticeMode.recall => sentence.copyWith(speakingScore: clamped),
    };

    final repo = ref.read(collectionRepositoryProvider);
    await repo.updateSentence(current.collection.id, updated);
    final refreshed =
        await repo.getById(current.collection.id) ?? current.collection;

    if (current.mode == PracticeMode.recall) {
      await _logSpeakingRating(sentence.id, clamped);
    }

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
      // Keep-alive uruchamiamy asynchronicznie, by pętla odtwarzania ruszyła natychmiast
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
      if (after != null &&
          after.isPlayingContinuous &&
          token == _loopToken) {
        state = after.copyWith(
          isPlayingContinuous: false,
          currentRep: 0,
        );
      }
    }
  }

  void pauseContinuousPlayback() {
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
    );
  }

  /// Opens or closes the native floating PiP bar (iOS 15+ only).
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

  /// Full sentence data: target text, phonetics and the Polish meaning.
  Future<void> _publishPipRevealed(Sentence sentence) async {
    if (state?.isPipActive != true) return;
    await _pip.updateContent(
      primaryText: sentence.targetText,
      phoneticText: sentence.phoneticReading,
      translationText: sentence.sourceText,
    );
  }

  /// Recall thinking phase: the answer stays hidden behind a prompt marker.
  Future<void> _publishPipThinking(Sentence sentence) async {
    if (state?.isPipActive != true) return;
    await _pip.updateContent(
      primaryText: '???',
      translationText: sentence.sourceText,
    );
  }

  void setRepsPerSentence(int reps) {
    if (reps != 1 && reps != 2 && reps != 3 && reps != 5) return;
    final current = state;
    if (current == null) return;
    state = current.copyWith(repsPerSentence: reps);
  }

  void cycleRepsPerSentence() {
    final current = state;
    if (current == null) return;
    final next = switch (current.repsPerSentence) {
      1 => 2,
      2 => 3,
      3 => 5,
      _ => 1,
    };
    setRepsPerSentence(next);
  }

  void setPauseBetweenReps(Duration duration) {
    final current = state;
    if (current == null) return;
    if (!PauseBetweenReps.presets.contains(duration)) return;
    state = current.copyWith(pauseBetweenReps: duration);
  }

  void cyclePauseBetweenReps() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      pauseBetweenReps: PauseBetweenReps.cycle(current.pauseBetweenReps),
    );
  }

  void setPlaybackSpeed(double speed) {
    final current = state;
    if (current == null) return;
    final snapped = PlaybackSpeed.snapToPreset(speed);
    state = current.copyWith(playbackSpeed: snapped);
    ref.read(audioPlaybackServiceProvider).setSpeed(snapped);
  }

  void toggleSingleSentenceLoop() {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      isSingleSentenceLoop: !current.isSingleSentenceLoop,
    );
  }

  bool _shouldContinueLoop(int token) {
    return state?.isPlayingContinuous == true && token == _loopToken;
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

    try {
      final path = await _ensureTargetAudioPath(sentence);
      if (!_shouldContinueLoop(token)) return;
      if (path == null) {
        pauseContinuousPlayback();
        return;
      }

      final reps = state!.repsPerSentence;
      for (var rep = 1; rep <= reps; rep++) {
        if (!_shouldContinueLoop(token)) return;

        state = state!.copyWith(currentRep: rep);

        final playback = ref.read(audioPlaybackServiceProvider);
        final duration = await playback.playFileUntilComplete(
          path,
          speed: state!.playbackSpeed,
        );
        if (!_shouldContinueLoop(token)) return;

        await _logListeningTime(duration);
        await _incrementSentenceReps(sentence.id);
        if (!_shouldContinueLoop(token)) return;

        await _interruptibleDelay(state!.pauseBetweenReps, token);
      }
    } catch (error) {
      state = state?.copyWith(audioError: error.toString());
      pauseContinuousPlayback();
    }
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

    await _interruptibleDelay(state!.recallThinkingDuration, token);
    if (!_shouldContinueLoop(token)) return;

    final revealed = Set<String>.from(state!.revealedSentenceIds)
      ..add(sentence.id);
    state = state!.copyWith(revealedSentenceIds: revealed);
    await _publishPipRevealed(sentence);
    if (!_shouldContinueLoop(token)) return;

    try {
      final path = await _ensureTargetAudioPath(sentence);
      if (!_shouldContinueLoop(token)) return;
      if (path == null) {
        pauseContinuousPlayback();
        return;
      }

      final playback = ref.read(audioPlaybackServiceProvider);
      final duration = await playback.playFileUntilComplete(
        path,
        speed: state!.playbackSpeed,
      );
      if (!_shouldContinueLoop(token)) return;

      await _logListeningTime(duration);
      await _incrementSentenceReps(sentence.id);
      if (!_shouldContinueLoop(token)) return;

      await _interruptibleDelay(state!.pauseBetweenReps, token);
    } catch (error) {
      state = state?.copyWith(audioError: error.toString());
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

    final tts = ref.read(azureTtsServiceProvider);
    final repo = ref.read(collectionRepositoryProvider);

    final path = await tts.ensureTargetAudio(sentence);
    final withPath = sentence.copyWith(targetAudioPath: path);
    await repo.updateSentence(current.collection.id, withPath);

    final refreshed =
        await repo.getById(current.collection.id) ?? current.collection;
    state = state!.copyWith(collection: refreshed);
    ref.invalidate(collectionsControllerProvider);

    return path;
  }

  Future<void> _incrementSentenceReps(String sentenceId) async {
    final current = state;
    if (current == null) return;

    final index =
        current.collection.sentences.indexWhere((s) => s.id == sentenceId);
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
    await _logRepetition(sentenceId);
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
      await ref.read(userMetricsRepositoryProvider).logListeningTime(
            seconds: seconds,
          );
      ref.invalidate(metricsControllerProvider);
    } on Object {
      return;
    }
  }

  Future<void> _logRepetition(String sentenceId) async {
    try {
      await ref.read(userMetricsRepositoryProvider).logRepetition(
            count: 1,
            sentenceId: sentenceId,
          );
      ref.invalidate(metricsControllerProvider);
    } on Object {
      return;
    }
  }

  Future<void> _logSpeakingRating(String sentenceId, int stars) async {
    try {
      await ref.read(userMetricsRepositoryProvider).logSpeakingRating(
            sentenceId: sentenceId,
            stars: stars,
          );
    } on Object {
      return;
    }
  }
}