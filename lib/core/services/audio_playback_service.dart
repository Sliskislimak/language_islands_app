import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:language_islands_app/core/services/audio_session_bootstrap.dart';

/// Serwis odtwarzacza audio dla języka docelowego.
///
/// Utrzymuje drugi, niesłyszalny odtwarzacz (_keepAlivePlayer), który zapętla
/// krótki plik WAV w tle. Zapobiega to usypianiu procesu (Process Suspension)
/// przez system iOS w trakcie przerw między powtórzeniami i zdaniami.
class AudioPlaybackService {
  AudioPlaybackService({AudioPlayer? player, AudioPlayer? keepAlivePlayer})
      : _player = player ?? AudioPlayer(),
        // ignore: prefer_initializing_formals
        _keepAlivePlayer = keepAlivePlayer;

  final AudioPlayer _player;
  AudioPlayer? _keepAlivePlayer;

  bool _keepAliveWanted = false;

  AudioPlayer get player => _player;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // ---------------------------------------------------------------------------
  // Keep-alive (cicha pętla w tle na iOS)
  // ---------------------------------------------------------------------------

  /// Uruchamia niesłyszalny odtwarzacz podtrzymujący proces w tle.
  /// Metoda jest bezpieczna i nieblokująca.
  Future<void> startBackgroundKeepAlive() async {
    _keepAliveWanted = true;
    try {
      await ensureAppAudioSessionActive();

      final keepAlive = _keepAlivePlayer ??= AudioPlayer();
      if (keepAlive.playing) return;

      final file = File('${Directory.systemTemp.path}/silence_keepalive.wav');
      if (!await file.exists()) {
        await file.writeAsBytes(_buildSilentWav(), flush: true);
      }

      await keepAlive.setFilePath(file.path);
      await keepAlive.setLoopMode(LoopMode.one);
      await keepAlive.setVolume(0.05);

      if (!_keepAliveWanted) return;

      // Startujemy bez await, aby nie blokować pętli odtwarzania zdań
      unawaited(keepAlive.play());
    } catch (_) {
      // Keep-alive działa na zasadzie best-effort: błąd nie zatrzymuje nauki
      _keepAliveWanted = false;
    }
  }

  Future<void> stopBackgroundKeepAlive() async {
    _keepAliveWanted = false;
    final keepAlive = _keepAlivePlayer;
    if (keepAlive == null) return;
    try {
      await keepAlive.stop();
    } catch (_) {}
  }

  /// 2 sekundy PCM 16-bit mono 44.1 kHz z minimalnym ditherem 40 Hz (1 LSB).
  /// Sygnał jest niesłyszalny dla ludzkiego ucha, lecz informuje CoreAudio o aktywnym strumieniu.
  static Uint8List _buildSilentWav() {
    const sampleRate = 44100;
    const channels = 1;
    const bitsPerSample = 16;
    const durationSeconds = 2;

    const frames = sampleRate * durationSeconds;
    const bytesPerFrame = channels * bitsPerSample ~/ 8;
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
    writeUint16(channels);
    writeUint32(sampleRate);
    writeUint32(sampleRate * bytesPerFrame);
    writeUint16(bytesPerFrame);
    writeUint16(bitsPerSample);
    writeAscii('data');
    writeUint32(dataSize);

    // Amplituda 1 LSB przy 40 Hz
    const amplitude = 1;
    for (var frame = 0; frame < frames; frame++) {
      final sample =
          (amplitude * math.sin(2 * math.pi * 40 * frame / sampleRate)).round();
      bytes.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return bytes.buffer.asUint8List();
  }

  // ---------------------------------------------------------------------------
  // Główne odtwarzanie zdań
  // ---------------------------------------------------------------------------

  Future<Duration> playFile(String filePath, {double speed = 1.0}) async {
    await ensureAppAudioSessionActive();
    await _player.setSpeed(speed.clamp(0.7, 1.5));
    await _player.setFilePath(filePath);
    final duration = _player.duration ?? Duration.zero;
    await _player.play();
    return duration;
  }

  /// Odtwarza plik i kończy Future dokładnie w momencie zakończenia dźwięku.
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

  /// Zatrzymuje główny odtwarzacz ORAZ cichy odtwarzacz keep-alive.
  Future<void> stop() async {
    unawaited(stopBackgroundKeepAlive());
    await _player.stop();
  }

  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed.clamp(0.7, 1.5));
  }

  Future<void> dispose() async {
    _keepAliveWanted = false;
    await _keepAlivePlayer?.dispose();
    _keepAlivePlayer = null;
    await _player.dispose();
  }
}