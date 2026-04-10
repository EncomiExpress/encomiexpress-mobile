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