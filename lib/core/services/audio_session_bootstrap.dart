import 'package:audio_session/audio_session.dart';

/// iOS [UIBackgroundModes] audio + [AVAudioSessionCategory.playback] for lock
/// screen, background continuation, and silent-switch playback.
const AudioSessionConfiguration _appAudioSessionConfiguration =
    AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.playback,
  avAudioSessionCategoryOptions:
      AVAudioSessionCategoryOptions.defaultToSpeaker,
  avAudioSessionMode: AVAudioSessionMode.spokenAudio,
  androidAudioAttributes: AndroidAudioAttributes(
    contentType: AndroidAudioContentType.speech,
    usage: AndroidAudioUsage.media,
  ),
  androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
  androidWillPauseWhenDucked: true,
);

AudioSession? _cachedSession;

Future<AudioSession> _session() async {
  _cachedSession ??= await AudioSession.instance;
  return _cachedSession!;
}

/// Call once at app startup before any playback.
Future<void> configureAppAudioSession() async {
  final session = await _session();
  await session.configure(_appAudioSessionConfiguration);
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
