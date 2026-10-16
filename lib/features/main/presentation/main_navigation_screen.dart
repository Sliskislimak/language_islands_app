import 'package:flutter/material.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';
import 'package:language_islands_app/features/collections/presentation/collections_screen.dart';
import 'package:language_islands_app/features/hiragana/presentation/screens/hiragana_screen.dart';
import 'package:language_islands_app/features/kanji/presentation/screens/kanji_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: switch (_currentIndex) {
        0 => const CollectionsScreen(),
        1 => const HiraganaScreen(),
        2 => const KanjiScreen(),
        _ => const CollectionsScreen(),
      },
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.surfaceBorder, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: AppTheme.surface,
          indicatorColor: AppTheme.sakuraPrimary.withValues(alpha: 0.2),
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.waves_rounded, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.waves_rounded, color: AppTheme.sakuraPrimary),
              label: 'Shadowing',
            ),
            NavigationDestination(
              icon: Icon(Icons.translate_rounded, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.translate_rounded, color: AppTheme.sakuraPrimary),
              label: 'Hiragana',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_rounded, color: AppTheme.textMuted),
              selectedIcon: Icon(Icons.auto_stories_rounded, color: AppTheme.sakuraPrimary),
              label: 'Kanji',
            ),
          ],
        ),
      ),
    );
  }
}
