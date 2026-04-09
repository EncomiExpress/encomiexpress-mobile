import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';
import '../models/models.dart';

class ConductorService {
  ApiClient get _api => ApiClient();

  Future<Map<String, dynamic>> updatePerfil({
    String? nombre,
    String? telefono,
    String? email,
    String? documento,
    String? fechaNacimiento,
    String? direccion,
    String? fotoPerfil,
    String? placa,
    String? marcaVehiculo,
    String? modeloVehiculo,
    String? anioVehiculo,
    String? colorVehiculo,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (nombre != null) data['nombre'] = nombre;
      if (telefono != null) data['telefono'] = telefono;
      if (email != null) data['email'] = email;
      if (documento != null) data['documento'] = documento;
      if (fechaNacimiento != null) data['fechaNacimiento'] = fechaNacimiento;
      if (direccion != null) data['direccion'] = direccion;
      if (fotoPerfil != null) data['fotoPerfil'] = fotoPerfil;
      if (placa != null) data['placa'] = placa;
      if (marcaVehiculo != null) data['marcaVehiculo'] = marcaVehiculo;
      if (modeloVehiculo != null) data['modeloVehiculo'] = modeloVehiculo;
      if (anioVehiculo != null) data['anioVehiculo'] = anioVehiculo;
      if (colorVehiculo != null) data['colorVehiculo'] = colorVehiculo;

      print('DEBUG updatePerfil - data: $data');
      final response = await _api.put('/api/conductores/perfil', data: data);
      print('DEBUG updatePerfil - response: ${response.statusCode}, data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      
      return {'success': false, 'message': 'Error al actualizar perfil: ${response.statusCode}'};
    } catch (e) {
      print('DEBUG updatePerfil - error: $e');
      if (e is DioException && e.response != null) {
        return {'success': false, 'message': 'Error: ${e.response?.data}'};
      }
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadFotoPerfil(PlatformFile file) async {
    try {
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      });

      final response = await _api.post('/api/conductores/perfil/foto', data: formData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      
      return {'success': false, 'message': 'Error al subir foto'};
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