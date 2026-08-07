import 'package:dio/dio.dart';
import 'api_client.dart';

class PaqueteService {
  ApiClient get _api => ApiClient();

  Future<List<dynamic>> getPaquetesPorConductor(int idConductor) async {
    final resp = await _api.get('/paquetes', queryParams: {'idConductor': idConductor.toString()});
    if (resp.statusCode == 200) return resp.data['data'] as List<dynamic>;
    return [];
  }

  Future<Map<String, dynamic>> subirEvidencia(int idPaquete, FormData data) async {
    final resp = await _api.patch('/paquetes/$idPaquete/evidencia', data: data);
    return resp.data as Map<String, dynamic>;
  }
}

/**
 * Nota: `ApiClient` es el wrapper de Dio presente en el proyecto.
 */
