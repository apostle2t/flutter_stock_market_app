import 'package:flutter/material.dart';

/// Centralised colour palette for the AetherVest dark theme.
///
/// Keeping every colour in one place means the whole app can be re-themed
/// from a single file and avoids magic colour literals scattered across
/// widgets.
abstract final class AppColors {
  // Backgrounds & surfaces.
  static const Color background = Color(0xFF0A0B0F);
  static const Color surface = Color(0xFF15171F);
  static const Color surfaceVariant = Color(0xFF1E212B);
  static const Color border = Color(0xFF272A35);

  // Brand / accent.
  static const Color primary = Color(0xFF5B5FE3);
  static const Color primaryDark = Color(0xFF4044C9);
  static const Color accent = Color(0xFF7C5CFC);

  // Semantic market colours.
  static const Color positive = Color(0xFF26C281);
  static const Color negative = Color(0xFFF0556C);

  // Text.
  static const Color textPrimary = Color(0xFFF4F5F7);
  static const Color textSecondary = Color(0xFF9498A6);
  static const Color textTertiary = Color(0xFF626675);

  // Misc.
  static const Color gold = Color(0xFFE9B949);

  /// Brand gradient used on primary call-to-action surfaces.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Returns [positive] for a non-negative [value], otherwise [negative].
  static Color forChange(double value) => value >= 0 ? positive : negative;
}
