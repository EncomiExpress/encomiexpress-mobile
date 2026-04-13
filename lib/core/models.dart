import 'package:flutter/material.dart';

class AppColors {
  static const adminGradStart = Color(0xFF7B2FBE);
  static const adminGradEnd   = Color(0xFF9B59B6);
  static const adminPrimary   = Color(0xFF7B2FBE);

  static const driverGradStart = Color(0xFF2563EB);
  static const driverGradEnd   = Color(0xFF3B82F6);
  static const driverPrimary   = Color(0xFF2563EB);

  static const loginGradStart = Color(0xFF3B5BDB);
  static const loginGradEnd   = Color(0xFF9B59B6);

  static const green    = Color(0xFF22C55E);
  static const greenBg  = Color(0xFFDCFCE7);
  static const orange   = Color(0xFFF59E0B);
  static const orangeBg = Color(0xFFFEF3C7);
  static const red      = Color(0xFFEF4444);
  static const redBg    = Color(0xFFFEE2E2);
  static const blue     = Color(0xFF3B82F6);
  static const blueBg   = Color(0xFFEFF6FF);
  static const purple   = Color(0xFF7B2FBE);
  static const purpleBg = Color(0xFFF3E8FF);

  static const bgGray   = Color(0xFFF5F6FA);
  static const cardBg   = Colors.white;
  static const textMain = Color(0xFF1E293B);
  static const textSub  = Color(0xFF64748B);
  static const border   = Color(0xFFE2E8F0);
}

class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final String rol;
  final String? conductorId;
  final String? documento;
  final String? fechaNacimiento;
  final String? direccion;
  final String? fotoPerfil;
  final String? placa;
  final String? marcaVehiculo;
  final String? modeloVehiculo;
  final String? anioVehiculo;
  final String? colorVehiculo;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.rol,
    this.conductorId,
    this.documento,
    this.fechaNacimiento,
    this.direccion,
    this.fotoPerfil,
    this.placa,
    this.marcaVehiculo,
    this.modeloVehiculo,
    this.anioVehiculo,
    this.colorVehiculo,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      telefono: json['telefono'] ?? json['phone'] ?? json['celular'] ?? json['numeroTelefono'] ?? json['numeroCelular'] ?? json['mobile'] ?? '',
      rol: json['rol'] ?? json['role'] ?? '',
      conductorId: json['conductorId']?.toString() ?? json['conductor']?['idConductor']?.toString(),
      documento: json['documento'] ?? json['numeroDocumento'] ?? json['cedula'],
      fechaNacimiento: json['fechaNacimiento'] ?? json['fecha_nacimiento'] ?? json['birthDate'],
      direccion: json['direccion'] ?? json['address'] ?? json['direccionResidencia'],
      fotoPerfil: json['fotoPerfil'] ?? json['foto_perfil'] ?? json['avatar'] ?? json['foto'],
      placa: json['placa'] ?? json['placaVehiculo'] ?? json['licensePlate'],
      marcaVehiculo: json['marcaVehiculo'] ?? json['marca'] ?? json['vehicleBrand'],
      modeloVehiculo: json['modeloVehiculo'] ?? json['modelo'] ?? json['vehicleModel'],
      anioVehiculo: json['anioVehiculo'] ?? json['anio'] ?? json['vehicleYear']?.toString(),
      colorVehiculo: json['colorVehiculo'] ?? json['color'] ?? json['vehicleColor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'conductorId': conductorId,
      'documento': documento,
      'fechaNacimiento': fechaNacimiento,
      'direccion': direccion,
      'fotoPerfil': fotoPerfil,
      'placa': placa,
      'marcaVehiculo': marcaVehiculo,
      'modeloVehiculo': modeloVehiculo,
      'anioVehiculo': anioVehiculo,
      'colorVehiculo': colorVehiculo,
    };
  }

  UserModel copyWith({
    String? id,
    String? nombre,
    String? email,
    String? telefono,
    String? rol,
    String? conductorId,
    String? documento,
    String? fechaNacimiento,
    String? direccion,
    String? fotoPerfil,
    String? placa,
    String? marcaVehiculo,
    String? modeloVehiculo,
    String? anioVehiculo,
    String? colorVehiculo,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      conductorId: conductorId ?? this.conductorId,
      documento: documento ?? this.documento,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      direccion: direccion ?? this.direccion,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      placa: placa ?? this.placa,
      marcaVehiculo: marcaVehiculo ?? this.marcaVehiculo,
      modeloVehiculo: modeloVehiculo ?? this.modeloVehiculo,
      anioVehiculo: anioVehiculo ?? this.anioVehiculo,
      colorVehiculo: colorVehiculo ?? this.colorVehiculo,
    );
  }
}

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

  factory Anticipo.fromJson(Map<String, dynamic> json) {
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
    return date.toString();
  }

  double get excedente => anticipo - gastado;
  bool get tieneDeficit => excedente < 0;
}

const List<Map<String, String>> usuariosDemo = [
  {
    'id': '1',
    'nombre': 'Administrador Sistema',
    'email': 'admin@test.com',
    'password': '123456',
    'telefono': '+57 300 000 0001',
    'rol': 'admin',
  },
  {
    'id': '2',
    'nombre': 'Juan Pérez',
    'email': 'conductor@test.com',
    'password': '123456',
    'telefono': '+57 300 123 4567',
    'rol': 'conductor',
  },
 ];

final List<Anticipo> anticiposDemo = [
  const Anticipo(
    id: 'A-001',
    tipo: 'Combustible',
    conductorNombre: 'Juan Pérez',
    conductorId: '2',
    anticipo: 500000,
    gastado: 450000,
    estado: 'Activo',
    fechaEntrega: '20/03/2026',
    fechaLegalizacion: '25/03/2026',
    fechaMaxima: '30/03/2026',
    soporte: 'factura_combustible.pdf',
  ),
  const Anticipo(
    id: 'A-002',
    tipo: 'Peajes',
    conductorNombre: 'Juan Pérez',
    conductorId: '2',
    anticipo: 200000,
    gastado: 220000,
    estado: 'Pendiente',
    fechaEntrega: '18/03/2026',
    fechaLegalizacion: '22/03/2026',
    fechaMaxima: '28/03/2026',
    soporte: 'recibo_peajes.jpg',
  ),
  const Anticipo(
    id: 'A-003',
    tipo: 'Viáticos',
    conductorNombre: 'María García',
    conductorId: '3',
    anticipo: 800000,
    gastado: 800000,
    estado: 'Pagado',
    fechaEntrega: '15/03/2026',
    fechaLegalizacion: '20/03/2026',
    fechaMaxima: '25/03/2026',
    soporte: 'viaticos_marzo.pdf',
  ),
  const Anticipo(
    id: 'A-004',
    tipo: 'Mantenimiento',
    conductorNombre: 'Juan Pérez',
    conductorId: '2',
    anticipo: 350000,
    gastado: 0,
    estado: 'Activo',
    fechaEntrega: '01/04/2026',
    fechaLegalizacion: '10/04/2026',
    fechaMaxima: '15/04/2026',
    soporte: null,
  ),
];

String formatCOP(double value) {
  final abs = value.abs();
  final formatted = abs.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return value < 0 ? '-\$$formatted' : '\$$formatted';
}

Color estadoColor(String estado) {
  switch (estado) {
    case 'Activo':   return AppColors.green;
    case 'Pendiente':return AppColors.orange;
    case 'Pagado':   return AppColors.blue;
    case 'Rechazado':return AppColors.red;
    default:         return AppColors.textSub;
  }
}

Color estadoBg(String estado) {
  switch (estado) {
    case 'Activo':   return AppColors.greenBg;
    case 'Pendiente':return AppColors.orangeBg;
    case 'Pagado':   return AppColors.blueBg;
    case 'Rechazado':return AppColors.redBg;
    default:         return AppColors.bgGray;
  }
}