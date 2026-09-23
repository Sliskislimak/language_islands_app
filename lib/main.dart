import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:language_islands_app/core/services/audio_session_bootstrap.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/presentation/collections_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Próbujemy zainicjować sesję audio dla trybu w tle
    await configureAppAudioSession();
  } catch (e) {
    // Ignorujemy błędy wtyczki audio podczas startu aplikacji,
    // aby zapobiec zawieszeniu się UI (White Screen of Death).
    debugPrint('Błąd inicjalizacji sesji audio: $e');
  }

  runApp(const ProviderScope(child: LanguageIslandsApp()));
}

class LanguageIslandsApp extends StatelessWidget {
  const LanguageIslandsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Islands',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.japaneseDarkTheme,
      home: const CollectionsScreen(),
    );
  }
}
