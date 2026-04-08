import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  ApiClient get _api => ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['token'] ?? data['data']?['token'];
        
        if (token != null) {
          await _saveToken(token);
          _api.setToken(token);
        }
        
        return {'success': true, 'data': data};
      }
      
      return {'success': false, 'message': 'Error en el login'};
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _api.get('/api/auth/profile');
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      
      return {'success': false, 'message': 'Error al obtener perfil'};
    } catch (e) {
      return _handleError(e);
    }
  }

  Future<void> logout() async {
    _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Map<String, dynamic> _handleError(dynamic e) {
    String message = 'Error de conexión';
    
    if (e is Exception) {
      if (e.toString().contains('SocketException')) {
        message = 'No se puede conectar al servidor';
      } else if (e.toString().contains('401')) {
        message = 'Credenciales incorrectas';
      } else if (e.toString().contains('403')) {
        message = 'Acceso denegado';
      } else if (e.toString().contains('500')) {
        message = 'Error del servidor';
      }
    }
    
    return {'success': false, 'message': message, 'error': e.toString()};
  }
}
