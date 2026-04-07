import 'api_client.dart';
import '../models/models.dart';

class AnticipoService {
  final ApiClient _api = ApiClient();

  Future<List<Anticipo>> getAnticipos() async {
    try {
      final response = await _api.get('/api/anticipos');
      
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

  Anticipo _fromJson(Map<String, dynamic> json) {
    return Anticipo(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo'] ?? json['tipoAnticipo'] ?? '',
      conductorNombre: json['conductorNombre'] ?? json['conductor']?['nombre'] ?? '',
      conductorId: json['conductorId']?.toString() ?? json['conductor']?['id']?.toString() ?? '',
      anticipo: _parseDouble(json['anticipo'] ?? json['monto']),
      gastado: _parseDouble(json['gastado'] ?? json['montoGastado']),
      estado: json['estado'] ?? 'Pendiente',
      fechaEntrega: _formatDate(json['fechaEntrega'] ?? json['fecha']),
      fechaLegalizacion: _formatDate(json['fechaLegalizacion']),
      fechaMaxima: _formatDate(json['fechaMaxima']),
      soporte: json['soporte'] ?? json['documento'],
    );
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
