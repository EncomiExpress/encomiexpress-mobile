import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';
import '../models.dart';

class AnticipoService {
  ApiClient get _api => ApiClient();

  // Solo rutas donde tendría sentido asignar un anticipo — el backend igual
  // rechaza con 409 si la ruta elegida ya tiene un anticipo activo.
  //
  // Trae también el conductor de cada ruta (idConductor/conductorNombre) —
  // igual que `rutasNormalizadas` en el frontend web (AnticipoExcedenteContext.jsx).
  // El conductor de un anticipo nunca se elige aparte: sale siempre de la ruta
  // elegida, para que nunca queden desincronizados (mismo criterio que aplica
  // el backend en anticipoService.update()).
  Future<List<Map<String, dynamic>>> getRutas() async {
    try {
      final response = await _api.get('/api/rutas', queryParams: {'limit': 1000, 'habilitado': true});
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data
            .where((json) => json['estado'] != 'Cancelada' && json['estado'] != 'Completada')
            .map((json) {
              final conductorJson = json['conductor'] as Map<String, dynamic>?;
              final usuarioJson = conductorJson?['usuario'] as Map<String, dynamic>?;
              final conductorNombre = usuarioJson != null
                  ? '${usuarioJson['nombre'] ?? ''} ${usuarioJson['apellido'] ?? ''}'.trim()
                  : '';
              return {
                'idRuta': json['idRuta']?.toString() ?? '',
                'nombre': json['nombreRuta'] ?? 'Ruta #${json['idRuta']}',
                'idConductor': json['idConductor']?.toString() ?? '',
                'conductorNombre': conductorNombre,
              };
            })
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // GET /api/anticipos — listado general, solo para el panel admin
  // (exige el permiso 'listar_anticipo', que el rol conductor no tiene).
  Future<Map<String, dynamic>> getAnticipos({
    int page = 1,
    int limit = 10,
    String? estado,
    String? idConductor,
    String? anio,
    String? mes,
    String? q,
  }) async {
    try {
      final response = await _api.get('/api/anticipos', queryParams: {
        'page': page,
        'limit': limit,
        if (estado != null && estado.isNotEmpty) 'estado': estado,
        if (idConductor != null && idConductor.isNotEmpty) 'idConductor': idConductor,
        if (anio != null && anio.isNotEmpty) 'anio': anio,
        if (mes != null && mes.isNotEmpty) 'mes': mes,
        if (q != null && q.isNotEmpty) 'q': q,
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return {
          'data': data.map((json) => Anticipo.fromJson(json)).toList(),
          'total': response.data['total'] ?? data.length,
        };
      }
      return {'data': <Anticipo>[], 'total': 0};
    } catch (e) {
      return {'data': <Anticipo>[], 'total': 0};
    }
  }

  // GET /api/anticipos/anios-disponibles — años (descendente) en que hay
  // anticipos con fecha de entrega, para poblar el filtro "Año" — mismo
  // endpoint que usa el filtro de años en ListarAnticipoExcedente.jsx (web).
  Future<List<String>> getAniosDisponibles() async {
    try {
      final response = await _api.get('/api/anticipos/anios-disponibles');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // GET /api/conductores/mis-anticipos — lo que debe usar el conductor
  // autenticado para ver los suyos (el idConductor sale del token, no se manda).
  Future<List<Anticipo>> getMisAnticipos() async {
    try {
      final response = await _api.get('/api/conductores/mis-anticipos');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        return data.map((json) => Anticipo.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Anticipo?> getAnticipoById(int id) async {
    try {
      final response = await _api.get('/api/anticipos/$id');
      if (response.statusCode == 200) {
        return Anticipo.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Solo admin — POST /api/anticipos exige idRuta e idConductor.
  Future<Map<String, dynamic>> crearAnticipo({
    required String idConductor,
    required String idRuta,
    required double valorAnticipo,
    String? fechaEntrega,
  }) async {
    try {
      final response = await _api.post('/api/anticipos', data: {
        'idConductor': int.tryParse(idConductor),
        'idRuta': int.tryParse(idRuta),
        'valorAnticipo': valorAnticipo,
        if (fechaEntrega != null) 'fechaEntrega': fechaEntrega,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'anticipo': Anticipo.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': 'Error al crear anticipo'};
    } catch (e) {
      return {'success': false, 'message': _mensajeError(e)};
    }
  }

  // PUT /api/anticipos/:id — qué campos se aceptan depende del estado actual
  // (ver anticipoService.update() en el backend):
  //   Entregado        -> idRuta / valorAnticipo / fechaEntrega / soporte
  //   En Legalización   -> solo valorGastado (obligatorio) / soporte
  // El caller decide qué mandar; este método no filtra nada por su cuenta.
  Future<Map<String, dynamic>> actualizarAnticipo(int id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/api/anticipos/$id', data: data);
      if (response.statusCode == 200) {
        return {'success': true, 'anticipo': Anticipo.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': 'Error al actualizar anticipo'};
    } catch (e) {
      return {'success': false, 'message': _mensajeError(e)};
    }
  }

  // PATCH /api/anticipos/:id/entregar-excedente — solo admin, solo tiene
  // efecto cuando estado == 'Excedente pendiente' (excedente > 0).
  Future<Map<String, dynamic>> entregarExcedente(int id, {String? soporte}) async {
    try {
      final response = await _api.patch('/api/anticipos/$id/entregar-excedente', data: {
        if (soporte != null) 'soporte': soporte,
      });
      if (response.statusCode == 200) {
        return {'success': true, 'anticipo': Anticipo.fromJson(response.data['data'])};
      }
      return {'success': false, 'message': 'Error al confirmar la devolución'};
    } catch (e) {
      return {'success': false, 'message': _mensajeError(e)};
    }
  }

  // POST /api/anticipos/:id/soporte — sube uno o varios comprobantes a
  // Cloudinary; el backend los agrega al array `soporte` que ya tenía el
  // anticipo (nunca los reemplaza). Paso aparte de crear/editar porque ese
  // endpoint espera archivos multipart, no URLs de texto.
  Future<Map<String, dynamic>> subirSoporte(int id, List<PlatformFile> files) async {
    try {
      final formData = FormData.fromMap({
        'soporte': await Future.wait(
            files.map((f) => MultipartFile.fromFile(f.path!, filename: f.name))),
      });
      final response = await _api.post('/api/anticipos/$id/soporte', data: formData);
      if (response.statusCode == 200) {
        final soporte = (response.data['data']?['soporte'] as List?)?.map((e) => e.toString()).toList();
        return {'success': true, 'soporte': soporte ?? const <String>[]};
      }
      return {'success': false, 'message': 'Error al subir el soporte'};
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
