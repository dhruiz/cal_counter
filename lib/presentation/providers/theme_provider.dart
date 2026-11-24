import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for theme mode state management
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Modo de tema persistido. Sin preferencia guardada sigue al sistema
/// (`ThemeMode.system`, índice 0), igual que antes; el estado inicial es el
/// mismo para no mostrar un tema y saltar a otro al terminar la carga.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    if (!mounted) return;
    // Un índice fuera de rango (dato corrupto) lanzaba RangeError.
    state = (themeIndex >= 0 && themeIndex < ThemeMode.values.length)
        ? ThemeMode.values[themeIndex]
        : ThemeMode.system;
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  /// Modo oscuro activado o no, según lo que se ve en pantalla. Con
  /// `ThemeMode.system` el interruptor debe reflejar el brillo del sistema:
  /// antes mostraba "claro" con el tema oscuro y el primer toque no cambiaba
  /// nada visible.
  void setDark(bool dark) => setTheme(dark ? ThemeMode.dark : ThemeMode.light);

  /// Set specific theme mode
  void setTheme(ThemeMode mode) {
    state = mode;
    _saveTheme(state);
  }

  /// Oscuro efectivo para [platformBrightness] (el del sistema).
  static bool isDarkFor(ThemeMode mode, Brightness platformBrightness) =>
      mode == ThemeMode.dark ||
      (mode == ThemeMode.system && platformBrightness == Brightness.dark);
}
