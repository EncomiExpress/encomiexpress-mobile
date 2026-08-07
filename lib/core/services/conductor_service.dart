import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models.dart';

class ConductorService {
  ApiClient get _api => ApiClient();

  // Solo nombre/apellido/telefono/email/numeroIdentificacion — tipo de
  // identificación y licencia son datos de verificación que solo el admin
  // gestiona desde el módulo de Conductores en la web (ver actualizarMiPerfil
  // en el backend, que a propósito no acepta esos dos campos).
  Future<Map<String, dynamic>> updatePerfil({
    String? nombre,
    String? apellido,
    String? telefono,
    String? email,
    String? documento,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (nombre != null) data['nombre'] = nombre;
      if (apellido != null) data['apellido'] = apellido;
      if (telefono != null) data['telefono'] = telefono;
      if (email != null) data['email'] = email;
      if (documento != null) data['numeroIdentificacion'] = documento;

      final response = await _api.put('/api/conductores/perfil', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }

      return {'success': false, 'message': 'Error al actualizar perfil: ${response.statusCode}'};
    } catch (e) {
      if (e is DioException && e.response != null) {
        return {'success': false, 'message': 'Error: ${e.response?.data}'};
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<UserModel?> getPerfil() async {
    try {
      final response = await _api.get('/api/conductores/perfil');
      
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['data'] ?? response.data);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}