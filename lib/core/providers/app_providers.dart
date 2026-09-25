import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/services/audio_playback_service.dart';
import 'package:language_islands_app/core/services/azure_tts_service.dart';
import 'package:language_islands_app/core/services/pip_service.dart';
import 'package:language_islands_app/data/repositories/collection_repository.dart';
import 'package:language_islands_app/data/repositories/schedule_repository.dart';
import 'package:language_islands_app/data/repositories/user_metrics_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  return CollectionRepository();
});

final userMetricsRepositoryProvider = Provider<UserMetricsRepository>((ref) {
  return UserMetricsRepository();
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository();
});

final azureTtsServiceProvider = Provider<AzureTtsService>((ref) {
  final service = AzureTtsService();
  ref.onDispose(service.dispose);
  return service;
});

final pipServiceProvider = Provider<PipService>((ref) {
  final service = PipService();
  ref.onDispose(service.stop);
  return service;
});

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  final service = AudioPlaybackService();
  ref.onDispose(() async {
    await service.dispose();
  });
  return service;
});
