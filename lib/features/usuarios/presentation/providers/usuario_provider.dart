import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../../config/api_config.dart';
import '../../domain/entities/usuario.dart';

class UsuarioProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final Dio? _dio;

  Usuario? _currentUser;
  bool _loading = false;
  String? _error;
  bool _isLoggedIn = false;

  static final List<Map<String, String>> _usuariosDemo = [
    {'id': '1', 'nombre': 'Administrador', 'email': 'admin@test.com', 'telefono': '+57 300 000 0001', 'password': '123456', 'rol': 'admin'},
    {'id': '2', 'nombre': 'Juan Pérez', 'email': 'conductor@test.com', 'telefono': '+57 300 123 4567', 'password': '123456', 'rol': 'conductor'},
  ];

  UsuarioProvider({required SharedPreferences prefs, Dio? dio}) : _prefs = prefs, _dio = dio;

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

    bool loginExitoso = false;

    try {
      if (_dio != null) {
        final response = await _dio!.post(
          ApiConfig.loginEndpoint,
          data: {'email': email, 'password': password},
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = response.data['data'] ?? response.data;
          _currentUser = Usuario(
            id: data['id']?.toString() ?? '',
            nombre: data['nombre']?.toString() ?? '',
            email: data['email']?.toString() ?? '',
            telefono: data['telefono']?.toString() ?? '',
            rol: data['rol']?.toString() ?? 'conductor',
          );
          loginExitoso = true;
          await _prefs.setString('auth_token', data['token']?.toString() ?? '');
        }
      }
    } catch (e) {
      debugPrint('Error login API: $e');
    }

    if (!loginExitoso && _dio != null) {
      final found = _usuariosDemo.firstWhere(
        (u) => u['email'] == email.trim() && u['password'] == password,
        orElse: () => {},
      );

      if (found.isNotEmpty) {
        _currentUser = Usuario(
          id: found['id']!,
          nombre: found['nombre']!,
          email: found['email']!,
          telefono: found['telefono']!,
          rol: found['rol']!,
        );
        loginExitoso = true;
      }
    }

    if (!loginExitoso) {
      _error = 'Correo o contraseña incorrectos';
    }

    _isLoggedIn = loginExitoso;
    _loading = false;
    notifyListeners();
    return loginExitoso;
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
