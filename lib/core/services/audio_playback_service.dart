import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:language_islands_app/core/services/audio_session_bootstrap.dart';

/// Thin wrapper around [AudioPlayer] for target-language playback only.
///
/// A second, silent player runs in parallel during continuous practice. iOS
/// suspends the process when no CoreAudio stream is rendering, which kills the
/// pauses between reps; the looping silent buffer keeps the stream alive.
class AudioPlaybackService {
  AudioPlaybackService({AudioPlayer? player, AudioPlayer? keepAlivePlayer})
      : _player = player ?? AudioPlayer(),
        _keepAlivePlayer = keepAlivePlayer ?? AudioPlayer();

  final AudioPlayer _player;
  final AudioPlayer _keepAlivePlayer;

  bool _keepAliveRunning = false;

  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<Duration> playFile(String filePath, {double speed = 1.0}) async {
    await ensureAppAudioSessionActive();
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
    await ensureAppAudioSessionActive();
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

  /// Starts the looping inaudible buffer. Must be called from the foreground,
  /// before the first target sentence plays.
  Future<void> startBackgroundKeepAlive() async {
    if (_keepAliveRunning) return;
    _keepAliveRunning = true;
    try {
      await ensureAppAudioSessionActive();
      await _keepAlivePlayer.setLoopMode(LoopMode.all);
      await _keepAlivePlayer.setVolume(0.01);
      await _keepAlivePlayer.setAudioSource(_SilenceAudioSource());
      await _keepAlivePlayer.play();
    } on Object {
      _keepAliveRunning = false;
      await _keepAlivePlayer.stop();
    }
  }

  Future<void> stopBackgroundKeepAlive() async {
    if (!_keepAliveRunning) return;
    _keepAliveRunning = false;
    try {
      await _keepAlivePlayer.stop();
    } on Object {
      return;
    }
  }

  Future<void> dispose() async {
    _keepAliveRunning = false;
    await _keepAlivePlayer.dispose();
    await _player.dispose();
  }
}

/// In-memory WAV source: 2 s of 16-bit mono PCM at an amplitude below the
/// hearing threshold. Dithered rather than pure zeros so encoders and the OS
/// treat it as an active stream instead of digital silence.
// ignore_for_file: experimental_member_use
class _SilenceAudioSource extends StreamAudioSource {
  _SilenceAudioSource() : _bytes = _buildSilentWav();

  final Uint8List _bytes;

  static const int _sampleRate = 44100;
  static const int _channels = 1;
  static const int _bitsPerSample = 16;
  static const int _durationSeconds = 2;

  static Uint8List _buildSilentWav() {
    const frames = _sampleRate * _durationSeconds;
    const bytesPerFrame = _channels * _bitsPerSample ~/ 8;
    const dataSize = frames * bytesPerFrame;
    const headerSize = 44;

    final bytes = ByteData(headerSize + dataSize);
    var offset = 0;

    void writeAscii(String value) {
      for (final unit in value.codeUnits) {
        bytes.setUint8(offset++, unit);
      }
    }

    void writeUint32(int value) {
      bytes.setUint32(offset, value, Endian.little);
      offset += 4;
    }

    void writeUint16(int value) {
      bytes.setUint16(offset, value, Endian.little);
      offset += 2;
    }

    writeAscii('RIFF');
    writeUint32(36 + dataSize);
    writeAscii('WAVE');
    writeAscii('fmt ');
    writeUint32(16);
    writeUint16(1); // PCM
    writeUint16(_channels);
    writeUint32(_sampleRate);
    writeUint32(_sampleRate * bytesPerFrame);
    writeUint16(bytesPerFrame);
    writeUint16(_bitsPerSample);
    writeAscii('data');
    writeUint32(dataSize);

    // A single LSB at 40 Hz: inaudible, but non-zero PCM data.
    const amplitude = 1;
    for (var frame = 0; frame < frames; frame++) {
      final sample =
          (amplitude * math.sin(2 * math.pi * 40 * frame / _sampleRate))
              .round();
      bytes.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return bytes.buffer.asUint8List();
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final from = start ?? 0;
    final to = end ?? _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: to - from,
      offset: from,
      stream: Stream.value(_bytes.sublist(from, to)),
      contentType: 'audio/wav',
    );
  }
}
