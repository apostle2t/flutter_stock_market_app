import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

/// Holds the light/dark choice, swaps the active [AppColors] palette, and
/// persists the preference across launches. The app listens to this and
/// rebuilds (with a matching theme) whenever it changes.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  /// Shared app-wide instance.
  static final ThemeController instance = ThemeController._();

  static const String _prefKey = 'isDarkMode';

  bool _isDark = true;
  bool get isDark => _isDark;

  /// Loads the saved preference and applies the matching palette. Call once
  /// before `runApp`. Defaults to dark (the app's original look).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDark = prefs.getBool(_prefKey) ?? true;
    } catch (_) {
      _isDark = true;
    }
    AppColors.apply(_isDark ? darkPalette : lightPalette);
  }

  /// Sets dark (true) or light (false), re-themes the app, and persists.
  Future<void> setDark(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    AppColors.apply(value ? darkPalette : lightPalette);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {
      // Persistence is best-effort; the in-memory choice still applies.
    }
  }

  void toggle() => setDark(!_isDark);
}
