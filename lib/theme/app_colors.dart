import 'package:flutter/material.dart';

/// A complete set of semantic colours for one theme (light or dark).
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.positive,
    required this.negative,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.gold,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color positive;
  final Color negative;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color gold;
}

/// The dark theme (the app's original look).
const AppPalette darkPalette = AppPalette(
  brightness: Brightness.dark,
  background: Color(0xFF0A0B0F),
  surface: Color(0xFF15171F),
  surfaceVariant: Color(0xFF1E212B),
  border: Color(0xFF272A35),
  primary: Color(0xFF5B5FE3),
  primaryDark: Color(0xFF4044C9),
  accent: Color(0xFF7C5CFC),
  positive: Color(0xFF26C281),
  negative: Color(0xFFF0556C),
  textPrimary: Color(0xFFF4F5F7),
  textSecondary: Color(0xFF9498A6),
  textTertiary: Color(0xFF626675),
  gold: Color(0xFFE9B949),
);

/// The light theme. Brand hues are kept; neutrals and text invert, and the
/// market greens/reds are darkened slightly for contrast on white.
const AppPalette lightPalette = AppPalette(
  brightness: Brightness.light,
  background: Color(0xFFF4F6FA),
  surface: Color(0xFFFFFFFF),
  surfaceVariant: Color(0xFFEDEFF5),
  border: Color(0xFFE0E3EC),
  primary: Color(0xFF5B5FE3),
  primaryDark: Color(0xFF4044C9),
  accent: Color(0xFF7C5CFC),
  positive: Color(0xFF15A06A),
  negative: Color(0xFFE03B57),
  textPrimary: Color(0xFF14161C),
  textSecondary: Color(0xFF5B6170),
  textTertiary: Color(0xFF99A0AE),
  gold: Color(0xFFB8860B),
);

/// Centralised colour access for the app.
///
/// Colours are exposed as getters that read the currently active [palette], so
/// the whole UI re-themes when [apply] swaps it (light ⇄ dark) — call sites
/// keep using `AppColors.background` etc. unchanged. Because these are runtime
/// values they can't be used in `const` expressions.
abstract final class AppColors {
  static AppPalette _palette = darkPalette;

  /// The active palette.
  static AppPalette get palette => _palette;

  /// Swaps the active palette (call before rebuilding the app).
  static void apply(AppPalette value) => _palette = value;

  static Brightness get brightness => _palette.brightness;

  // Backgrounds & surfaces.
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get surfaceVariant => _palette.surfaceVariant;
  static Color get border => _palette.border;

  // Brand / accent.
  static Color get primary => _palette.primary;
  static Color get primaryDark => _palette.primaryDark;
  static Color get accent => _palette.accent;

  // Semantic market colours.
  static Color get positive => _palette.positive;
  static Color get negative => _palette.negative;

  // Text.
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textTertiary => _palette.textTertiary;

  // Misc.
  static Color get gold => _palette.gold;

  /// Brand gradient used on primary call-to-action surfaces.
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, accent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  /// Returns [positive] for a non-negative [value], otherwise [negative].
  static Color forChange(double value) => value >= 0 ? positive : negative;
}
