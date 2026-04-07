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

  const UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.rol,
  });
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