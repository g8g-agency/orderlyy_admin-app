// lib/core/theme/app_text_styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get displayLg => GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 48 / 40,
    letterSpacing: -0.02 * 40,
  );

  static TextStyle get headlineLg => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
  );

  static TextStyle get headlineLgMobile => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
  );

  static TextStyle get headlineMd => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  static TextStyle get titleLg => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.05 * 12,
  );

  static TextStyle get button =>
      GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600);

  // ── Backward Compatibility Aliases ──────────────────────────────────────────
  static TextStyle get h1 => headlineLg;
  static TextStyle get h2 => headlineMd;
  static TextStyle get h3 => titleLg;
  static TextStyle get caption => bodySmall;
}
