import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modus_pampa_v3/main.dart'; // Para acceder a sharedPreferences

// Clave para guardar el estado del tema en SharedPreferences.
const String themePrefsKey = 'isDarkMode';

// StateNotifier para gestionar el estado del tema.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  // Carga el tema guardado en SharedPreferences al iniciar.
  void _loadTheme() {
    final isDarkMode = sharedPreferences.getBool(themePrefsKey) ?? false;
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Cambia el tema y guarda la preferencia.
  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    sharedPreferences.setBool(themePrefsKey, state == ThemeMode.dark);
  }
}

// El provider que expondremos a la UI para interactuar con el ThemeNotifier.
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
