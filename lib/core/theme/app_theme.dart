import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Orderlli Design System — "The Culinary Architect"
/// Based on Stitch orderlli_crimson design tokens.
class AppTheme {
  // ── Primary Palette ───────────────────────────────────────────────────────
  static const Color primary = Color(0xFFBA0013);
  static const Color primaryContainer = Color(0xFFE31E24);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryFixed = Color(0xFFFFDAD6);
  static const Color primaryFixedDim = Color(0xFFFFB4AB);
  static const Color onPrimaryFixed = Color(0xFF410002);
  static const Color onPrimaryFixedVariant = Color(0xFF93000D);

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF5D5E61);
  static const Color secondaryContainer = Color(0xFFE2E2E5);
  static const Color onSecondaryContainer = Color(0xFF636467);

  // ── Tertiary ──────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF545C64);
  static const Color tertiaryContainer = Color(0xFF6C757D);

  // ── Surface Hierarchy ─────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F5);
  static const Color surfaceContainer = Color(0xFFEDEEEF);
  static const Color surfaceContainerHigh = Color(0xFFE7E8E9);
  static const Color surfaceContainerHighest = Color(0xFFE1E3E4);
  static const Color surfaceBright = Color(0xFFF8F9FA);
  static const Color surfaceDim = Color(0xFFD9DADB);

  // ── On-Surface ────────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF191C1D);
  static const Color onSurfaceVariant = Color(0xFF5D3F3C);
  static const Color onBackground = Color(0xFF191C1D);

  // ── Error ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);

  // ── Outline ───────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF926F6B);
  static const Color outlineVariant = Color(0xFFE7BDB8);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const Color inverseSurface = Color(0xFF2E3132);
  static const Color inverseOnSurface = Color(0xFFF0F1F2);
  static const Color inversePrimary = Color(0xFFFFB4AB);
  static const Color surfaceTint = Color(0xFFC00014);

  // ── Shadow ────────────────────────────────────────────────────────────────
  /// Crimson-tinted shadow used for floating elements (KitchenSync premium aesthetic)
  static const List<BoxShadow> crimsonShadow = [
    BoxShadow(
      color: Color(0x0DBA0013), // rgba(186,0,19,0.05)
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> crimsonShadowLight = [
    BoxShadow(
      color: Color(0x08BA0013), // rgba(186,0,19,0.03)
      blurRadius: 32,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
  ];

  // ── Text Styles ───────────────────────────────────────────────────────────
  static TextStyle get displayLg => GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: onSurface,
    height: 48 / 40,
    letterSpacing: -0.02 * 40,
  );

  static TextStyle get headlineLg => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: onSurface,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
  );

  static TextStyle get headlineMd => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: onSurface,
    height: 32 / 24,
  );

  static TextStyle get titleLg => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: onSurface,
    height: 28 / 20,
  );

  static TextStyle get titleMd => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: onSurface,
  );

  static TextStyle get titleSm => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: onSurface,
  );

  static TextStyle get bodyMd => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: onSurface,
    height: 1.6,
  );

  static TextStyle get bodySm => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: secondary,
    height: 1.5,
  );

  static TextStyle get labelMd => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: secondary,
    letterSpacing: 0.05 * 12,
  );

  static TextStyle get labelSm => GoogleFonts.plusJakartaSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: secondary,
    letterSpacing: 0.8,
  );

  /// JetBrains Mono for technical data (IDs, prices, table numbers)
  static TextStyle get monoMd => GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.6,
  );

  static TextStyle get monoLg => GoogleFonts.jetBrainsMono(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  // ── Radius ────────────────────────────────────────────────────────────────
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(4)); // 0.25rem = 4px
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(8)); // DEFAULT = 8px
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(16)); // 1rem = 16px
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(24)); // 1.5rem = 24px
  static const BorderRadius radiusFull = BorderRadius.all(
    Radius.circular(9999),
  );

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get light {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        surface: surface,
        onSurface: onSurface,
        error: error,
        errorContainer: errorContainer,
        onError: onError,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainerLowest,
        foregroundColor: onSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        iconTheme: const IconThemeData(color: secondary),
      ),
      textTheme: base.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: onSurface,
          letterSpacing: -1.0,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: onSurface,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: secondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: secondary,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: secondary,
          letterSpacing: 0.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: secondary),
        labelStyle: const TextStyle(
          color: secondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: secondary,
        suffixIconColor: secondary,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: surfaceContainerHigh, width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: surfaceContainerHigh, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryContainer, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: error, width: 2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // 0.5rem = 8px
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryContainer,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: primaryContainer, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryContainer,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Level 1 Card is 16px = 1rem radius
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedItemColor: primaryContainer,
        unselectedItemColor: secondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerColor: surfaceContainerHighest,
      dividerTheme: const DividerThemeData(
        color: surfaceContainerHighest,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
