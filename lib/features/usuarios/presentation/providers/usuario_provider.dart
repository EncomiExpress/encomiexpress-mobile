import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/usuario.dart';

class UsuarioProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  Usuario? _currentUser;
  bool _loading = false;
  String? _error;
  bool _isLoggedIn = false;

  static final List<Map<String, String>> usuariosDemo = [
    {'id': '1', 'nombre': 'Administrador', 'email': 'admin@test.com', 'telefono': '+57 300 000 0001', 'password': '123456', 'rol': 'admin'},
    {'id': '2', 'nombre': 'Juan Pérez', 'email': 'conductor@test.com', 'telefono': '+57 300 123 4567', 'password': '123456', 'rol': 'conductor'},
  ];

  UsuarioProvider({required SharedPreferences prefs}) : _prefs = prefs;

  Usuario? get currentUser => _currentUser;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isConductor => _currentUser?.isConductor ?? false;

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    final found = usuariosDemo.firstWhere(
      (u) => u['email'] == email.trim() && u['password'] == password,
      orElse: () => {},
    );

    if (found.isEmpty) {
      _error = 'Correo o contraseña incorrectos';
      _loading = false;
      notifyListeners();
      return false;
    }

    _currentUser = Usuario(
      id: found['id']!,
      nombre: found['nombre']!,
      email: found['email']!,
      telefono: found['telefono']!,
      rol: found['rol']!,
    );
    _isLoggedIn = true;
    
    _loading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final userData = _prefs.getString('user_data');
    if (userData != null) {
      try {
        final data = _parseJsonString(userData);
        if (data.isNotEmpty) {
          _currentUser = _currentUserFromMap(data);
          _isLoggedIn = true;
          notifyListeners();
        }
      } catch (e) {
        await logout();
      }
    }
  }

  Map<String, dynamic> _parseJsonString(String str) {
    final result = <String, dynamic>{};
    if (str.startsWith('{') && str.endsWith('}')) {
      final content = str.substring(1, str.length - 1);
      final pairs = content.split(',');
      for (final pair in pairs) {
        final colonIndex = pair.indexOf(':');
        if (colonIndex > 0) {
          final key = pair.substring(0, colonIndex).trim();
          final value = pair.substring(colonIndex + 1).trim();
          result[key] = value;
        }
      }
    }
    return result;
  }

  Usuario? _currentUserFromMap(Map<String, dynamic> map) {
    try {
      return Usuario(
        id: map['id']?.toString() ?? '',
        nombre: map['nombre']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        telefono: map['telefono']?.toString() ?? '',
        rol: map['rol']?.toString() ?? 'conductor',
      );
    } catch (e) {
      return null;
    }
  }
}
