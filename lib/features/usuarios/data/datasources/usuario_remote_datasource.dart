import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';

abstract class UsuarioRemoteDataSource {
  Future<UsuarioModel?> login(String email, String password);
  Future<void> logout();
  Future<UsuarioModel?> getCurrentUser();
}

class UsuarioRemoteDataSourceImpl implements UsuarioRemoteDataSource {
  final SharedPreferences prefs;

  UsuarioRemoteDataSourceImpl({
    required this.prefs,
  });

  @override
  Future<UsuarioModel?> login(String email, String password) async {
    // Demo users for testing
    if (email == 'admin@encomiexpress.com' && password == 'admin123') {
      return UsuarioModel(
        id: '1',
        nombre: 'Administrador',
        email: 'admin@encomiexpress.com',
        telefono: '+57 300 000 0001',
        rol: 'admin',
      );
    }
    if (email == 'conductor@encomiexpress.com' && password == 'conductor123') {
      return UsuarioModel(
        id: '2',
        nombre: 'Juan Pérez',
        email: 'conductor@encomiexpress.com',
        telefono: '+57 300 123 4567',
        rol: 'conductor',
      );
    }

    return null;
  }

  @override
  Future<void> logout() async {
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  @override
  Future<UsuarioModel?> getCurrentUser() async {
    final userData = prefs.getString('user_data');
    if (userData != null) {
      try {
        return UsuarioModel.fromJson(
            Map<String, dynamic>.from(_parseJsonString(userData)));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  dynamic _parseJsonString(String jsonString) {
    if (jsonString.startsWith('{')) {
      return _parseMapString(jsonString);
    }
    return {};
  }

  Map<String, dynamic> _parseMapString(String str) {
    final result = <String, dynamic>{};
    final content = str.substring(1, str.length - 1);
    final pairs = <String>[];
    var depth = 0;
    var current = '';

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '{' || char == '[') depth++;
      if (char == '}' || char == ']') depth--;
      if (char == ',' && depth == 0) {
        pairs.add(current.trim());
        current = '';
      } else {
        current += char;
      }
    }
    if (current.isNotEmpty) pairs.add(current.trim());

    for (final pair in pairs) {
      final colonIndex = pair.indexOf(':');
      if (colonIndex > 0) {
        final key = pair.substring(0, colonIndex).trim().replaceAll('"', '');
        final value = pair.substring(colonIndex + 1).trim().replaceAll('"', '');
        result[key] = value;
      }
    }
    return result;
  }
}