import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import 'theme_tokens.dart';

const _kDarkModeKey = 'theme_dark_mode';

// Equivalente a ThemeContext.jsx (frontend web): modo claro/oscuro,
// persistido, notificando a toda la app cuando cambia. Azul es el único
// color de marca (ver theme_tokens.dart) -- ya no hay paleta seleccionable.
class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  bool _darkMode = false;

  bool get darkMode => _darkMode;
  ThemeTokens get tokens => resolveTokens(_darkMode);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_kDarkModeKey) ?? false;
    AppColors.apply(tokens);
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    AppColors.apply(tokens);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, _darkMode);
  }
}
