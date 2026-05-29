// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFFBA0013); // Primary red
  static const Color primaryContainer = Color(
    0xFFE31E24,
  ); // Primary container red
  static const Color secondary = Color(0xFF5D5E61); // Cool gray
  static const Color secondaryContainer = Color(0xFFE2E2E5);

  // Dark Mode Palette (adapted for new system or fallback)
  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1E1E22);
  static const Color darkSurfaceCard = Color(0xFF26262B);
  static const Color darkTextPrimary = Color(0xFFF1F1F5);
  static const Color darkTextSecondary = Color(0xFFA5A5B1);

  // Light Mode Palette (KitchenSync core)
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(
    0xFFFFFFFF,
  ); // Pure white as per specification Level 1
  static const Color lightTextPrimary = Color(0xFF191C1D);
  static const Color lightTextSecondary = Color(0xFF5D5E61);

  // Semantic Colors
  static const Color success = Color(0xFF2EC4B6); // Clean teal
  static const Color error = Color(0xFFBA1A1A); // Crimson error
  static const Color warning = Color(0xFFFF9F1C); // Amber warning
  static const Color info = Color(0xFF00536E); // Info blue

  // Neutral borders
  static const Color darkBorder = Color(0xFF2C2C35);
  static const Color lightBorder = Color(
    0xFFE1E3E4,
  ); // surface-container-highest
}
