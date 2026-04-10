class Anticipo {
  final String id;
  final String tipo;
  final String conductorNombre;
  final String conductorId;
  final double anticipo;
  final double gastado;
  final String estado;
  final String fechaEntrega;
  final String fechaLegalizacion;
  final String fechaMaxima;
  final String? soporte;

  const Anticipo({
    required this.id,
    required this.tipo,
    required this.conductorNombre,
    required this.conductorId,
    required this.anticipo,
    required this.gastado,
    required this.estado,
    required this.fechaEntrega,
    required this.fechaLegalizacion,
    required this.fechaMaxima,
    this.soporte,
  });

  double get excedente => anticipo - gastado;
  bool get tieneDeficit => excedente < 0;
  
  Anticipo copyWith({
    String? id,
    String? tipo,
    String? conductorNombre,
    String? conductorId,
    double? anticipo,
    double? gastado,
    String? estado,
    String? fechaEntrega,
    String? fechaLegalizacion,
    String? fechaMaxima,
    String? soporte,
  }) {
    return Anticipo(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      conductorNombre: conductorNombre ?? this.conductorNombre,
      conductorId: conductorId ?? this.conductorId,
      anticipo: anticipo ?? this.anticipo,
      gastado: gastado ?? this.gastado,
      estado: estado ?? this.estado,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      fechaLegalizacion: fechaLegalizacion ?? this.fechaLegalizacion,
      fechaMaxima: fechaMaxima ?? this.fechaMaxima,
      soporte: soporte ?? this.soporte,
    );
  }
}