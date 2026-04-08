import 'api_client.dart';
import '../models/models.dart';

class AnticipoService {
  ApiClient get _api => ApiClient();

  Future<List<Map<String, dynamic>>> getConductores() async {
    try {
      final response = await _api.get('/api/conductores');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => {
          'idConductor': json['idConductor']?.toString() ?? '',
          'nombre': json['usuario']?['nombre'] ?? json['nombre'] ?? '',
          'estado': json['estado'] ?? 'activo',
        }).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Anticipo>> getAnticipos({String? conductorId}) async {
    try {
      String endpoint = '/api/anticipos';
      if (conductorId != null && conductorId.isNotEmpty) {
        endpoint = '/api/anticipos?idConductor=$conductorId';
      }
      
      final response = await _api.get(endpoint);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((json) => _fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Anticipo?> getAnticipoById(String id) async {
    try {
      final response = await _api.get('/api/anticipos/$id');
      
      if (response.statusCode == 200) {
        return _fromJson(response.data['data'] ?? response.data);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> crearAnticipo(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/api/anticipos', data: data);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      
      return {'success': false, 'message': 'Error al crear anticipo'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> actualizarAnticipo(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/api/anticipos/$id', data: data);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      
      return {'success': false, 'message': 'Error al actualizar anticipo'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> liquidarAnticipo(String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/api/anticipos/liquidar/$id', data: data);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      
      return {'success': false, 'message': 'Error al liquidar anticipo'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> aprobarAnticipo(String id) async {
    try {
      final response = await _api.put('/api/anticipos/$id', data: {
        'estado': 'liquidado',
      });
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      
      return {'success': false, 'message': 'Error al approve anticipo'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rechazarAnticipo(String id) async {
    try {
      final response = await _api.put('/api/anticipos/$id', data: {
        'estado': 'rechazado',
      });
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      
      return {'success': false, 'message': 'Error al rechazar anticipo'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Anticipo _fromJson(Map<String, dynamic> json) {
    final conductorData = json['conductor'];
    String conductorNombre = '';
    String conductorId = '';
    if (conductorData != null) {
      final usuarioData = conductorData['usuario'];
      conductorNombre = conductorData['nombre'] ?? conductorData['usuario']?['nombre'] ?? usuarioData?['nombre'] ?? '';
      conductorId = conductorData['idConductor']?.toString() ?? conductorData['id']?.toString() ?? '';
    }
    
    return Anticipo(
      id: json['idAnticipoExcedente']?.toString() ?? json['idAnticipo']?.toString() ?? json['id']?.toString() ?? '',
      tipo: json['tipo'] ?? 'Anticipo',
      conductorNombre: conductorNombre,
      conductorId: conductorId,
      anticipo: _parseDouble(json['valorAnticipo'] ?? json['anticipo'] ?? json['monto']),
      gastado: _parseDouble(json['valorGastado'] ?? json['gastado'] ?? json['montoGastado']),
      estado: _mapEstado(json['estado'] ?? ''),
      fechaEntrega: _formatDate(json['fechaEntrega'] ?? json['fecha']),
      fechaLegalizacion: _formatDate(json['fechaLegalizacion']),
      fechaMaxima: _formatDate(json['fechaMaxima']),
      soporte: json['soporte'] ?? json['documento'],
    );
  }
  
  String _mapEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente': return 'Pendiente';
      case 'liquidado': return 'Pagado';
      case 'con excedente': return 'Activo';
      case 'excedente entregado': return 'Pagado';
      default: return estado.isEmpty ? 'Pendiente' : estado;
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is String) return date;
    if (date is Map) {
      return date['date'] ?? date.toString();
    }
    return date.toString();
  }
}
