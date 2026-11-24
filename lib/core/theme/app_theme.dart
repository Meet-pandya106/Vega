import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neo-Banking Minimalist Palette (Exact to Reference UI)
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121214);
  static const Color surfaceVariant = Color(0xFF1C1C1E);
  static const Color surfaceElevated = Color(0xFF2C2C2E);

  // Distinct Card Palette
  static const Color cardYellow = Color(0xFFF6C84C);
  static const Color cardPurple = Color(0xFF8B4DF5);
  static const Color cardPurpleDark = Color(0xFF7A3BE6);

  // Floating Dock & Pill Accents
  static const Color dockBackground = Color(0xFF161618);
  static const Color activePillWhite = Color(0xFFFFFFFF);
  static const Color activePillText = Color(0xFF000000);

  // High-Contrast Financial Colors
  static const Color profit = Color(0xFF30D158); // Apple / Neo-fintech Green
  static const Color loss = Color(0xFFFF453A); // Apple Crimson Red

  static const Color dhanTeal = Color(0xFF00E5BC);

  // Clean Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted = Color(0xFF636366);

  static const Color borderSubtle = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.10)

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: cardPurple,
        secondary: cardYellow,
        surface: surface,
        error: loss,
        onSurface: textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: cardPurple, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
    );
  }
}
