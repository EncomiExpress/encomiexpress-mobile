import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';

class PaqueteService {
  ApiClient get _api => ApiClient();

  // GET /api/paquetes?idConductor= — un conductor autenticado siempre ve solo
  // los suyos, sin importar el idConductor que se mande (ver getByConductor
  // en paqueteController.js).
  Future<List<dynamic>> getPaquetesPorConductor(int idConductor) async {
    final resp = await _api.get(
      '/api/paquetes',
      queryParams: {'idConductor': idConductor.toString()},
    );
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
      final resp = await _api.patch(
        '/api/paquetes/$idPaquete/evidencia',
        data: formData,
      );
      if (resp.statusCode == 200)
        return {'success': true, 'data': resp.data['data']};
      return {'success': false, 'message': 'No se pudo actualizar el paquete'};
    } catch (e) {
      return {'success': false, 'message': _mensajeError(e)};
    }
  }

  // PATCH /api/paquetes/sede — el conductor del tramo troncal marca DE UNA VEZ
  // todos los paquetes "Por entregar" de una sede (parada o destino final) como
  // "En sede de destino". Foto y novedades son opcionales (ver dejarPaquetesEnSede).
  Future<Map<String, dynamic>> dejarEnSede({
    required int idRuta,
    required int idDestino,
    String novedades = '',
    PlatformFile? foto,
  }) async {
    try {
      final map = <String, dynamic>{
        'idRuta': idRuta.toString(),
        'idDestino': idDestino.toString(),
        'novedades': novedades,
      };
      if (foto != null && foto.path != null) {
        map['file'] = await MultipartFile.fromFile(
          foto.path!,
          filename: foto.name,
        );
      }
      final resp = await _api.patch(
        '/api/paquetes/sede',
        data: FormData.fromMap(map),
      );
      if (resp.statusCode == 200) {
        return {
          'success': true,
          'data': resp.data['data'],
          'message': resp.data['message'],
        };
      }
      return {
        'success': false,
        'message': 'No se pudo legalizar la entrega en sede',
      };
    } catch (e) {
      return {'success': false, 'message': _mensajeError(e)};
    }
  }

  // GET /api/paquetes/sede — paquetes "En sede de destino" de las sedes que
  // cubre el distribuidor autenticado (el idUsuario sale del token).
  Future<List<dynamic>> getPaquetesEnSede() async {
    final resp = await _api.get('/api/paquetes/sede');
    if (resp.statusCode == 200) return resp.data['data'] as List<dynamic>;
    return [];
  }

  // GET /api/paquetes/sede/historial — paquetes que el distribuidor autenticado
  // ya cerró (Entregado/Devuelto). Ver getHistorialSedeDistribuidor() y
  // LOGICA.md, "Historial de entrega final — tab del distribuidor".
  Future<List<dynamic>> getHistorialSede() async {
    final resp = await _api.get('/api/paquetes/sede/historial');
    if (resp.statusCode == 200) return resp.data['data'] as List<dynamic>;
    return [];
  }

  // GET /api/paquetes/:id/historial-entrega — historial completo (cada
  // Intento/Entregado/Devuelto) de UN paquete puntual, con su propia novedad/
  // foto/fecha cada uno -- distinto de getHistorialSede (esa lista TODOS los
  // paquetes ya cerrados). Mismo endpoint que usa la web (ModalHistorialEntrega.jsx);
  // acá solo puede verlo si cubre la sede de ese paquete. Ver
  // encomiendaService.distribuidorCubrePaquete.
  Future<List<dynamic>> getHistorialEntrega(int idPaquete) async {
    final resp = await _api.get('/api/paquetes/$idPaquete/historial-entrega');
    if (resp.statusCode == 200) return resp.data['data'] as List<dynamic>;
    return [];
  }

  // PATCH /api/paquetes/:id/entrega-final — el distribuidor registra la entrega
  // final: accion = 'Entregado' | 'Devuelto' | 'Intento'. Foto y novedad
  // OBLIGATORIAS en las 3 (ver LOGICA.md, "Evidencia de entrega final obligatoria").
  Future<Map<String, dynamic>> registrarEntregaFinal(
    int idPaquete, {
    required String accion,
    String novedad = '',
    PlatformFile? foto,
  }) async {
    try {
      final map = <String, dynamic>{'accion': accion, 'novedad': novedad};
      if (foto != null && foto.path != null) {
        map['file'] = await MultipartFile.fromFile(
          foto.path!,
          filename: foto.name,
        );
      }
      final resp = await _api.patch(
        '/api/paquetes/$idPaquete/entrega-final',
        data: FormData.fromMap(map),
      );
      if (resp.statusCode == 200) {
        return {
          'success': true,
          'data': resp.data['data'],
          'message': resp.data['message'],
        };
      }
      return {'success': false, 'message': 'No se pudo registrar la entrega'};
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
