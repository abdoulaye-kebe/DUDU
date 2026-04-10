import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thème global DUDU Pro (clair / sombre / système), persisté localement.
class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'pro_theme_mode';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  /// À appeler depuis `main()` après `ensureInitialized` pour éviter un flash de thème incorrect.
  Future<void> loadFromPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(_prefKey);
      if (v == 'dark') {
        _mode = ThemeMode.dark;
      } else if (v == 'light') {
        _mode = ThemeMode.light;
      } else {
        _mode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setTheme(ThemeMode m) async {
    _mode = m;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      final s = m == ThemeMode.dark
          ? 'dark'
          : m == ThemeMode.light
              ? 'light'
              : 'system';
      await p.setString(_prefKey, s);
    } catch (_) {}
  }

  String get modeLabel {
    switch (_mode) {
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.system:
        return 'Système';
    }
  }
}
