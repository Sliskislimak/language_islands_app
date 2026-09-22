import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Thin wrapper around [AudioPlayer] for target-language playback only.
class AudioPlaybackService {
  AudioPlaybackService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<Duration> playFile(String filePath, {double speed = 1.0}) async {
    await _player.setSpeed(speed.clamp(0.7, 1.5));
    await _player.setFilePath(filePath);
    final duration = _player.duration ?? Duration.zero;
    await _player.play();
    return duration;
  }

  /// Plays [filePath] and completes when playback finishes or the player stops.
  Future<Duration> playFileUntilComplete(
    String filePath, {
    double speed = 1.0,
  }) async {
    await _player.setSpeed(speed.clamp(0.7, 1.5));
    await _player.setFilePath(filePath);
    final duration = _player.duration ?? Duration.zero;
    final completer = Completer<void>();
    var playbackStarted = false;
    late final StreamSubscription<PlayerState> subscription;
    subscription = _player.playerStateStream.listen((playerState) {
      if (playerState.playing) {
        playbackStarted = true;
      }
      if (!playbackStarted) return;

      final done = playerState.processingState == ProcessingState.completed ||
          (playerState.processingState == ProcessingState.idle &&
              !playerState.playing);
      if (done) {
        subscription.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
    await _player.play();
    await completer.future;
    return duration;
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.7, 1.5));
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
