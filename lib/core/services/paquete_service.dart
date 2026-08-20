import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';

class PaqueteService {
  ApiClient get _api => ApiClient();

  // GET /api/paquetes?idConductor= — un conductor autenticado siempre ve solo
  // los suyos, sin importar el idConductor que se mande (ver getByConductor
  // en paqueteController.js).
  Future<List<dynamic>> getPaquetesPorConductor(int idConductor) async {
    final resp = await _api.get('/api/paquetes', queryParams: {'idConductor': idConductor.toString()});
    if (resp.statusCode == 200) return resp.data['data'] as List<dynamic>;
    return [];
  }

  // PATCH /api/paquetes/:id/evidencia — sube la foto de evidencia (form-data)
  // y deja el paquete en 'Entregado' o 'Devuelto' (ver paqueteController.subirEvidencia).
  Future<Map<String, dynamic>> subirEvidencia(
    int idPaquete, {
    required String estado,
    required PlatformFile foto,
    String observacion = '',
  }) async {
    try {
      final formData = FormData.fromMap({
        'estado': estado,
        'observacion': observacion,
        'file': await MultipartFile.fromFile(foto.path!, filename: foto.name),
      });
      final resp = await _api.patch('/api/paquetes/$idPaquete/evidencia', data: formData);
      if (resp.statusCode == 200) return {'success': true, 'data': resp.data['data']};
      return {'success': false, 'message': 'No se pudo actualizar el paquete'};
    } catch (e) {
      return {'success': false, 'message': _mensajeError(e)};
    }
  }

  String _mensajeError(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      return e.response?.data['message'] ?? 'Error de conexión';
    }
    return 'Error de conexión';
  }
}
