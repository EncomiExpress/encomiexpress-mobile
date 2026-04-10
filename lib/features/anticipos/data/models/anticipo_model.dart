import '../../domain/entities/anticipo.dart';

class AnticipoModel extends Anticipo {
  const AnticipoModel({
    required super.id,
    required super.tipo,
    required super.conductorNombre,
    required super.conductorId,
    required super.anticipo,
    required super.gastado,
    required super.estado,
    required super.fechaEntrega,
    required super.fechaLegalizacion,
    required super.fechaMaxima,
    super.soporte,
  });

  factory AnticipoModel.fromJson(Map<String, dynamic> json) {
    return AnticipoModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'conductorNombre': conductorNombre,
      'conductorId': conductorId,
      'anticipo': anticipo,
      'gastado': gastado,
      'estado': estado,
      'fechaEntrega': fechaEntrega,
      'fechaLegalizacion': fechaLegalizacion,
      'fechaMaxima': fechaMaxima,
      'soporte': soporte,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is String) return date;
    if (date is Map) {
      return date['date'] ?? date.toString();
    }
    return date.toString();
  }

  static AnticipoModel fromEntity(Anticipo anticipo) {
    return AnticipoModel(
      id: anticipo.id,
      tipo: anticipo.tipo,
      conductorNombre: anticipo.conductorNombre,
      conductorId: anticipo.conductorId,
      anticipo: anticipo.anticipo,
      gastado: anticipo.gastado,
      estado: anticipo.estado,
      fechaEntrega: anticipo.fechaEntrega,
      fechaLegalizacion: anticipo.fechaLegalizacion,
      fechaMaxima: anticipo.fechaMaxima,
      soporte: anticipo.soporte,
    );
  }
}