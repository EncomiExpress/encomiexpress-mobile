import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/usecases/login.dart';
import '../../data/datasources/usuario_remote_datasource.dart';
import '../../data/repositories/usuario_repository_impl.dart';

class UsuarioProvider extends ChangeNotifier {
  late final Login _login;
  late final Dio _dio;
  final SharedPreferences _prefs;

  Usuario? _currentUser;
  bool _loading = false;
  String? _error;
  bool _isLoggedIn = false;

  UsuarioProvider({required SharedPreferences prefs, required Dio dio}) : _prefs = prefs, _dio = dio {
    final dataSource = UsuarioRemoteDataSourceImpl(
      dio: dio,
      prefs: prefs,
    );
    final repository = UsuarioRepositoryImpl(remoteDataSource: dataSource);
    _login = Login(repository);
  }

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

    try {
      final user = await _login.call(email, password);
      if (user != null) {
        _currentUser = user;
        _isLoggedIn = true;
        await _prefs.setString('user_data', user.toJson().toString());
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Credenciales incorrectas';
        _loading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
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