import 'package:audio_session/audio_session.dart';

/// Configures OS audio session for speech playback (shadowing / recall).
/// Required on iOS for lock-screen and background continuation with [UIBackgroundModes].
Future<void> configureAppAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.speech());
}
