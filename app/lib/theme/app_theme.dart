import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChronicoColors {
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceBright = Color(0xFF393939);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);

  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFC2C6D5);

  static const Color primary = Color(0xFFADC6FF);
  static const Color onPrimary = Color(0xFF002E69);
  static const Color primaryContainer = Color(0xFF4D8EFE);
  static const Color onPrimaryContainer = Color(0xFF00285C);

  static const Color secondary = Color(0xFFC1C7CD);
  static const Color onSecondary = Color(0xFF2B3136);
  static const Color secondaryContainer = Color(0xFF41474D);
  static const Color onSecondaryContainer = Color(0xFFB0B6BC);

  static const Color tertiary = Color(0xFFFFB780);
  static const Color onTertiary = Color(0xFF4E2600);
  static const Color tertiaryContainer = Color(0xFFDB760F);
  static const Color onTertiaryContainer = Color(0xFF442000);

  static const Color error = Color(0xFFFF3B30);
  static const Color onError = Color(0xFF000000);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color outline = Color(0xFF8C909F);
  static const Color outlineVariant = Color(0xFF424753);
}

class ChronicoTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ChronicoColors.background,
      colorScheme: const ColorScheme.dark(
        background: ChronicoColors.background,
        surface: ChronicoColors.surface,
        surfaceContainerLowest: ChronicoColors.surfaceContainerLowest,
        surfaceContainerLow: ChronicoColors.surfaceContainerLow,
        surfaceContainer: ChronicoColors.surfaceContainer,
        surfaceContainerHigh: ChronicoColors.surfaceContainerHigh,
        surfaceContainerHighest: ChronicoColors.surfaceContainerHighest,
        onSurface: ChronicoColors.onSurface,
        onSurfaceVariant: ChronicoColors.onSurfaceVariant,
        primary: ChronicoColors.primary,
        onPrimary: ChronicoColors.onPrimary,
        primaryContainer: ChronicoColors.primaryContainer,
        onPrimaryContainer: ChronicoColors.onPrimaryContainer,
        secondary: ChronicoColors.secondary,
        onSecondary: ChronicoColors.onSecondary,
        secondaryContainer: ChronicoColors.secondaryContainer,
        onSecondaryContainer: ChronicoColors.onSecondaryContainer,
        tertiary: ChronicoColors.tertiary,
        onTertiary: ChronicoColors.onTertiary,
        tertiaryContainer: ChronicoColors.tertiaryContainer,
        onTertiaryContainer: ChronicoColors.onTertiaryContainer,
        error: ChronicoColors.error,
        onError: ChronicoColors.onError,
        errorContainer: ChronicoColors.errorContainer,
        onErrorContainer: ChronicoColors.onErrorContainer,
        outline: ChronicoColors.outline,
        outlineVariant: ChronicoColors.outlineVariant,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 48,
          color: ChronicoColors.onSurface,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01 * 32,
          color: ChronicoColors.onSurface,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: ChronicoColors.onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ChronicoColors.onSurface,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ChronicoColors.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.55,
          color: ChronicoColors.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: ChronicoColors.onSurface,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ChronicoColors.onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.01 * 14,
          color: ChronicoColors.onSurface,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02 * 12,
          color: ChronicoColors.onSurfaceVariant,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ChronicoColors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ChronicoColors.primary),
      ),
      cardTheme: CardThemeData(
        color: ChronicoColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ChronicoColors.outlineVariant, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ChronicoColors.surfaceContainerHighest,
        hintStyle: const TextStyle(color: ChronicoColors.onSurfaceVariant),
        labelStyle: const TextStyle(color: ChronicoColors.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronicoColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronicoColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronicoColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChronicoColors.primaryContainer,
          foregroundColor: ChronicoColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
