import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Port of the website's `ThemeService`: light/dark chosen by the user, remembered across
/// restarts, falling back to the OS preference on first launch.
///
/// The site stores this under `market_theme` in localStorage; we keep the same key name so the
/// intent is obvious when comparing the two codebases.
class ThemeController extends ChangeNotifier {
  ThemeController();

  static const _storageKey = 'market_theme';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = switch (prefs.getString(_storageKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      // No stored choice: follow the system, exactly like the site's prefers-color-scheme check.
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  Future<void> toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await prefs.remove(_storageKey);
    } else {
      await prefs.setString(_storageKey, mode == ThemeMode.dark ? 'dark' : 'light');
    }
  }
}
