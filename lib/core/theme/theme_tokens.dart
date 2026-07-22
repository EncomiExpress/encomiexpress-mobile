import 'package:flutter/material.dart';

// Puerto directo de encomiexpress-frontend/src/shared/styles/theme.js —
// mismos valores hex, misma estructura (paleta rojo/azul × claro/oscuro).
// Si cambia algo allá, cambia acá.

class StatusColor {
  final Color bg;
  final Color color;
  const StatusColor(this.bg, this.color);
}

class ThemeTokens {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color primaryDarker;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final StatusColor success;
  final StatusColor warning;
  final StatusColor error;
  final StatusColor info;
  final StatusColor purple;
  final List<Color> gradientNavbar;
  final Color activeBg;

  const ThemeTokens({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.primaryDarker,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.purple,
    required this.gradientNavbar,
    required this.activeBg,
  });
}

const _redLight = ThemeTokens(
  primary: Color(0xFFCC1818),
  primaryLight: Color(0xFFFFE8E8),
  primaryDark: Color(0xFFB91C1C),
  primaryDarker: Color(0xFFA01212),
  secondary: Color(0xFF1A2E6E),
  background: Color(0xFFF5F6FA),
  surface: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF1A0E0C),
  textSecondary: Color(0xFF8A94A6),
  border: Color(0xFFE0E0E0),
  success: StatusColor(Color(0xFFE8F5E9), Color(0xFF2E7D32)),
  warning: StatusColor(Color(0xFFFFF8E1), Color(0xFFF57F17)),
  error: StatusColor(Color(0xFFFEE2E2), Color(0xFF991B1B)),
  info: StatusColor(Color(0xFFE3F2FD), Color(0xFF1565C0)),
  purple: StatusColor(Color(0xFFF3E5F5), Color(0xFF6A1B9A)),
  gradientNavbar: [Color(0xFF1A2E6E), Color(0xFFCC1818), Color(0xFF1A2E6E)],
  activeBg: Color.fromRGBO(204, 24, 24, 0.08),
);

const _redDark = ThemeTokens(
  primary: Color(0xFFE57373),
  primaryLight: Color(0xFFFFCDD2),
  primaryDark: Color(0xFFD32F2F),
  primaryDarker: Color(0xFFB71C1C),
  secondary: Color(0xFFC62828),
  background: Color(0xFF121212),
  surface: Color(0xFF1E1E1E),
  textPrimary: Color(0xFFE0E0E0),
  textSecondary: Color(0xFFB8B8B8),
  border: Color(0xFF444444),
  success: StatusColor(Color(0xFF1B5E20), Color(0xFF4CAF50)),
  warning: StatusColor(Color(0xFF4E3100), Color(0xFFFFB74D)),
  error: StatusColor(Color(0xFF4A1515), Color(0xFFEF5350)),
  info: StatusColor(Color(0xFF0D2B4E), Color(0xFF90CAF9)),
  purple: StatusColor(Color(0xFF2D1458), Color(0xFFCE93D8)),
  gradientNavbar: [Color(0xFF4FC3F7), Color(0xFFE57373), Color(0xFF4FC3F7)],
  activeBg: Color.fromRGBO(229, 115, 115, 0.15),
);

const _blueLight = ThemeTokens(
  primary: Color(0xFF1A2E6E),
  primaryLight: Color(0xFFE8EEFF),
  primaryDark: Color(0xFF0F1C45),
  primaryDarker: Color(0xFF091236),
  secondary: Color(0xFF1A2E6E),
  background: Color(0xFFF5F6FA),
  surface: Color(0xFFFFFFFF),
  textPrimary: Color(0xFF1A0E0C),
  textSecondary: Color(0xFF8A94A6),
  border: Color(0xFFE0E0E0),
  success: StatusColor(Color(0xFFE8F5E9), Color(0xFF2E7D32)),
  warning: StatusColor(Color(0xFFFFF8E1), Color(0xFFF57F17)),
  error: StatusColor(Color(0xFFFEE2E2), Color(0xFF991B1B)),
  info: StatusColor(Color(0xFFE3F2FD), Color(0xFF1565C0)),
  purple: StatusColor(Color(0xFFF3E5F5), Color(0xFF6A1B9A)),
  gradientNavbar: [Color(0xFFCC1818), Color(0xFF1A2E6E), Color(0xFFCC1818)],
  activeBg: Color.fromRGBO(26, 46, 110, 0.12),
);

const _blueDark = ThemeTokens(
  primary: Color(0xFF64BBE2),
  primaryLight: Color(0xFFBCE2F3),
  primaryDark: Color(0xFF257EAE),
  primaryDarker: Color(0xFF155587),
  secondary: Color(0xFFC62828),
  background: Color(0xFF121212),
  surface: Color(0xFF1E1E1E),
  textPrimary: Color(0xFFE0E0E0),
  textSecondary: Color(0xFFB8B8B8),
  border: Color(0xFF444444),
  success: StatusColor(Color(0xFF1B5E20), Color(0xFF4CAF50)),
  warning: StatusColor(Color(0xFF4E3100), Color(0xFFFFB74D)),
  error: StatusColor(Color(0xFF4A1515), Color(0xFFEF5350)),
  info: StatusColor(Color(0xFF0D2B4E), Color(0xFF90CAF9)),
  purple: StatusColor(Color(0xFF2D1458), Color(0xFFCE93D8)),
  gradientNavbar: [Color(0xFFE57373), Color(0xFF64BBE2), Color(0xFFE57373)],
  activeBg: Color.fromRGBO(100, 187, 226, 0.15),
);

ThemeTokens resolveTokens(String paletteKey, bool darkMode) {
  if (paletteKey == 'blue') return darkMode ? _blueDark : _blueLight;
  return darkMode ? _redDark : _redLight;
}
