import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import 'theme_tokens.dart';

const _kDarkModeKey = 'theme_dark_mode';
const _kPaletteKey = 'theme_palette_key';

// Equivalente a ThemeContext.jsx (frontend web): modo claro/oscuro + paleta
// rojo/azul, persistidos, notificando a toda la app cuando cambian.
class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  bool _darkMode = false;
  String _paletteKey = 'red';

  bool get darkMode => _darkMode;
  String get paletteKey => _paletteKey;
  ThemeTokens get tokens => resolveTokens(_paletteKey, _darkMode);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_kDarkModeKey) ?? false;
    _paletteKey = prefs.getString(_kPaletteKey) ?? 'red';
    AppColors.apply(tokens);
  }

  Future<void> toggleDarkMode() async {
    _darkMode = !_darkMode;
    AppColors.apply(tokens);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, _darkMode);
  }

  Future<void> setPalette(String key) async {
    if (key == _paletteKey) return;
    _paletteKey = key;
    AppColors.apply(tokens);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPaletteKey, key);
  }
}
