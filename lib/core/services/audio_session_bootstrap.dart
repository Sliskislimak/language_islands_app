import 'package:audio_session/audio_session.dart';

/// iOS [UIBackgroundModes] audio + playback category (via [speech()]) for lock
/// screen, background continuation, and silent-switch playback.
/// Do not set [AVAudioSessionCategoryOptions.defaultToSpeaker] with playback —
/// iOS returns OSStatus -50 (kAudio_ParamError).
const AudioSessionConfiguration _appAudioSessionConfiguration =
    AudioSessionConfiguration.speech();

AudioSession? _cachedSession;

Future<AudioSession> _session() async {
  _cachedSession ??= await AudioSession.instance;
  return _cachedSession!;
}

/// Call once at app startup before any playback.
Future<void> configureAppAudioSession() async {
  final session = await _session();
  await session.configure(_appAudioSessionConfiguration);
  await session.setActive(true);
}

/// Keeps the OS audio session active for shadowing loops and recall gaps.
Future<void> ensureAppAudioSessionActive() async {
  final session = await _session();
  if (!session.isConfigured) {
    await session.configure(_appAudioSessionConfiguration);
  }
  await session.setActive(true);
}

/// Releases the session when continuous practice stops.
Future<void> releaseAppAudioSession() async {
  final session = await _session();
  if (!session.isConfigured) return;
  await session.setActive(false);
}
