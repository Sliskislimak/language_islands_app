import 'package:flutter/material.dart';

class AppTheme {
  // --- BAZA I TŁO (Minimalistyczny ciemny łupek) ---
  static const Color bgDark = Color(0xFF0F141C);
  static const Color surface = Color(0xFF19202E);
  static const Color surfaceElevated = Color(0xFF232B3D);
  static const Color surfaceBorder = Color(0xFF2B3547);

  // --- KOGNITYWNY SYSTEM KOLORÓW (Japoński + Teoria Notatek) ---
  
  // 1. Sakura Pink - Uwaga / Język docelowy (Kanji & Kana)
  static const Color sakuraPrimary = Color(0xFFF4A7B9);
  static const Color sakuraAccent = Color(0xFFFF8DA1);
  static const Color sakuraMuted = Color(0xFFD497A5);

  // 2. Light Green (Matcha/Mint) - Aplikacja / Sukces / Mastered (5 gwiazdek)
  static const Color greenMatcha = Color(0xFF86EFAC);
  static const Color greenMatchaLight = Color(0xFFA7F3D0);

  // 3. Recall Amber/Yellow - Pytania / Monity / Tap to reveal
  static const Color yellowPrompt = Color(0xFFFDE047);

  // 4. Neutralne teksty
  static const Color textLight = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color phoneticText = Color(0xFFE2B6C3); // Stonowany róż pod kanji

  static ThemeData get japaneseDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: sakuraPrimary,
        secondary: greenMatcha,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textLight),
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceBorder,
        thickness: 1,
      ),
    );
  }
}