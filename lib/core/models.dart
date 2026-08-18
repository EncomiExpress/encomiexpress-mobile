import 'package:flutter/material.dart';
import 'theme/theme_tokens.dart';

// Antes eran `static const` (un solo esquema fijo, morado para admin / azul
// para conductor). Ahora son mutables — ThemeController.apply() los
// reasigna cada vez que cambia el modo claro/oscuro o la paleta rojo/azul,
// igual que theme.js en el frontend web. admin/driver ya no tienen colores
// de marca propios: los dos leen la misma paleta activa, como en la web.
class AppColors {
  static Color adminGradStart = _initial.primary;
  static Color adminGradEnd   = _initial.primaryDark;
  static Color adminPrimary   = _initial.primary;

  static Color driverGradStart = _initial.primary;
  static Color driverGradEnd   = _initial.primaryDark;
  static Color driverPrimary   = _initial.primary;

  static Color loginGradStart = _initial.primary;
  static Color loginGradEnd   = _initial.primaryDark;

  static Color green    = _initial.success.color;
  static Color greenBg  = _initial.success.bg;
  static Color orange   = _initial.warning.color;
  static Color orangeBg = _initial.warning.bg;
  static Color red      = _initial.error.color;
  static Color redBg    = _initial.error.bg;
  static Color blue     = _initial.info.color;
  static Color blueBg   = _initial.info.bg;
  static Color purple   = _initial.purple.color;
  static Color purpleBg = _initial.purple.bg;

  static Color bgGray   = _initial.background;
  static Color cardBg   = _initial.surface;
  static Color textMain = _initial.textPrimary;
  static Color textSub  = _initial.textSecondary;
  static Color border   = _initial.border;
  static Color secondary = _initial.secondary;
  static Color activeBg = _initial.activeBg;

  static List<Color> gradientNavbar = _initial.gradientNavbar;

  static const _initial = ThemeTokens(
    primary: Color(0xFFCC1818),
    primaryLight: Color(0xFFFFE8E8),
    primaryDark: Color(0xFFB91C1C),
    primaryDarker: Color(0xFFA01212),
    secondary: Color(0xFF1A2E6E),
    background: Color(0xFFF5F6FA),
    surface: Colors.white,
    textPrimary: Color(0xFF1A0E0C),
    textSecondary: Color(0xFF8A94A6),
    border: Color(0xFFE0E0E0),
    success: StatusColor(Color(0xFFE8F5E9), Color(0xFF2E7D32)),
    warning: StatusColor(Color(0xFFFFF8E1), Color(0xFFF57F17)),
    error: StatusColor(Color(0xFFFEE2E2), Color(0xFF991B1B)),
    info: StatusColor(Color(0xFFE3F2FD), Color(0xFF1565C0)),
    purple: StatusColor(Color(0xFFF3E5F5), Color(0xFF6A1B9A)),
    gradientNavbar: [Color(0xFF1A2E6E), Color(0xFFCC1818), Color(0xFF1A2E6E)],
    activeBg: Color.fromRGBO(204, 24, 24, 0.08),
  );

  static void apply(ThemeTokens t) {
    adminGradStart = t.primary;
    adminGradEnd = t.primaryDark;
    adminPrimary = t.primary;
    driverGradStart = t.primary;
    driverGradEnd = t.primaryDark;
    driverPrimary = t.primary;
    loginGradStart = t.primary;
    loginGradEnd = t.primaryDark;
    green = t.success.color;
    greenBg = t.success.bg;
    orange = t.warning.color;
    orangeBg = t.warning.bg;
    red = t.error.color;
    redBg = t.error.bg;
    blue = t.info.color;
    blueBg = t.info.bg;
    purple = t.purple.color;
    purpleBg = t.purple.bg;
    bgGray = t.background;
    cardBg = t.surface;
    textMain = t.textPrimary;
    textSub = t.textSecondary;
    border = t.border;
    secondary = t.secondary;
    activeBg = t.activeBg;
    gradientNavbar = t.gradientNavbar;
  }
}

// 'Buenos días,' / 'Buenas tardes,' / 'Buenas noches,' — igual que
// getGreeting() en shared/components/Header.jsx del frontend.
String greeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Buenos días,';
  if (hour >= 12 && hour < 18) return 'Buenas tardes,';
  return 'Buenas noches,';
}

const _dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
];

// 'Lunes, 18 de julio  •  09:41 a. m.' — igual que formatDateTime() en
// shared/hooks/useDateTime.js del frontend web.
String formatDateTime(DateTime date) {
  final dia = _dias[date.weekday % 7];
  final mes = _meses[date.month - 1];
  final hora12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minuto = date.minute.toString().padLeft(2, '0');
  final ampm = date.hour < 12 ? 'a. m.' : 'p. m.';
  return '$dia, ${date.day} de $mes  •  $hora12:$minuto $ampm';
}

// Cada categoría de licencia del conductor trae su propia fecha de
// vencimiento (categoriasLicencia es JSONB en el backend: [{categoria, vencimiento}]).
class LicenciaCategoria {
  final String categoria;
  final String? vencimiento;

  const LicenciaCategoria({required this.categoria, this.vencimiento});

  factory LicenciaCategoria.fromJson(Map<String, dynamic> json) => LicenciaCategoria(
        categoria: json['categoria']?.toString() ?? '',
        vencimiento: json['vencimiento']?.toString(),
      );

  bool get vencida {
    if (vencimiento == null) return false;
    final fecha = DateTime.tryParse(vencimiento!);
    return fecha != null && fecha.isBefore(DateTime.now());
  }
}

class UserModel {
  final String id;
  final String nombre;
  final String? apellido;
  final String email;
  final String telefono;
  final String rol;
  final String? conductorId;
  final String? documento;
  final String? tipoDocumento;
  final String? fechaNacimiento;
  final String? direccion;
  final String? fotoPerfil;
  final String? numeroLicencia;
  final List<LicenciaCategoria> categoriasLicencia;

  const UserModel({
    required this.id,
    required this.nombre,
    this.apellido,
    required this.email,
    required this.telefono,
    required this.rol,
    this.conductorId,
    this.documento,
    this.tipoDocumento,
    this.fechaNacimiento,
    this.direccion,
    this.fotoPerfil,
    this.numeroLicencia,
    this.categoriasLicencia = const [],
  });

  // Nombre completo mostrado como "Nombre Apellido" — el backend guarda
  // nombre y apellido por separado.
  String get nombreCompleto =>
      apellido != null && apellido!.isNotEmpty ? '$nombre $apellido' : nombre;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? json['name'] ?? '',
      apellido: json['apellido'],
      email: json['email'] ?? '',
      telefono: json['telefono'] ?? json['phone'] ?? json['celular'] ?? json['numeroTelefono'] ?? json['numeroCelular'] ?? json['mobile'] ?? '',
      rol: json['rol'] ?? json['role'] ?? '',
      conductorId: json['conductorId']?.toString() ?? json['conductor']?['idConductor']?.toString(),
      documento: json['documento'] ?? json['numeroIdentificacion'] ?? json['numeroDocumento'] ?? json['cedula'],
      tipoDocumento: json['tipoIdentificacion'],
      fechaNacimiento: json['fechaNacimiento'] ?? json['fecha_nacimiento'] ?? json['birthDate'],
      direccion: json['direccion'] ?? json['address'] ?? json['direccionResidencia'],
      fotoPerfil: json['fotoPerfil'] ?? json['foto_perfil'] ?? json['avatar'] ?? json['foto'],
      numeroLicencia: json['numeroLicencia'],
      categoriasLicencia: (json['categoriasLicencia'] as List?)
              ?.map((e) => LicenciaCategoria.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'telefono': telefono,
      'rol': rol,
      'conductorId': conductorId,
      'documento': documento,
      'tipoIdentificacion': tipoDocumento,
      'fechaNacimiento': fechaNacimiento,
      'direccion': direccion,
      'fotoPerfil': fotoPerfil,
      'numeroLicencia': numeroLicencia,
      'categoriasLicencia': categoriasLicencia,
    };
  }

  UserModel copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? email,
    String? telefono,
    String? rol,
    String? conductorId,
    String? documento,
    String? tipoDocumento,
    String? fechaNacimiento,
    String? direccion,
    String? fotoPerfil,
    String? numeroLicencia,
    List<LicenciaCategoria>? categoriasLicencia,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      conductorId: conductorId ?? this.conductorId,
      documento: documento ?? this.documento,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      direccion: direccion ?? this.direccion,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      numeroLicencia: numeroLicencia ?? this.numeroLicencia,
      categoriasLicencia: categoriasLicencia ?? this.categoriasLicencia,
    );
  }
}

// Estados reales de AnticipoExcedente en el backend (encomiexpress-backend,
// src/models/anticipoExcedente.js + anticipoService.js). El ciclo de vida es
// lineal: Entregado -> En Legalización -> (Excedente pendiente | Completado).
class EstadoAnticipo {
  static const entregado = 'Entregado';
  static const enLegalizacion = 'En Legalización';
  static const excedentePendiente = 'Excedente pendiente';
  static const completado = 'Completado';

  static const todos = [entregado, enLegalizacion, excedentePendiente, completado];
}

class Anticipo {
  final int id;
  final int idConductor;
  final int idRuta;
  final double valorAnticipo;
  final double valorGastado;
  final double excedente;
  final String estado;
  final bool habilitado;
  // Array de URLs de Cloudinary — un anticipo puede tener varios comprobantes.
  final List<String> soporte;
  final String? fechaEntrega;
  final String? fechaLegalizacion;
  final String? fechaEntregaExcedente;
  final String conductorNombre;
  final String? nombreRuta;
  final String? destinoTexto;

  const Anticipo({
    required this.id,
    required this.idConductor,
    required this.idRuta,
    required this.valorAnticipo,
    required this.valorGastado,
    required this.excedente,
    required this.estado,
    required this.habilitado,
    this.soporte = const [],
    this.fechaEntrega,
    this.fechaLegalizacion,
    this.fechaEntregaExcedente,
    this.conductorNombre = '',
    this.nombreRuta,
    this.destinoTexto,
  });

  Anticipo copyWith({List<String>? soporte}) => Anticipo(
        id: id,
        idConductor: idConductor,
        idRuta: idRuta,
        valorAnticipo: valorAnticipo,
        valorGastado: valorGastado,
        excedente: excedente,
        estado: estado,
        habilitado: habilitado,
        soporte: soporte ?? this.soporte,
        fechaEntrega: fechaEntrega,
        fechaLegalizacion: fechaLegalizacion,
        fechaEntregaExcedente: fechaEntregaExcedente,
        conductorNombre: conductorNombre,
        nombreRuta: nombreRuta,
        destinoTexto: destinoTexto,
      );

  // Forma real de una fila devuelta por GET /api/anticipos, GET /api/anticipos/:id
  // o GET /api/conductores/mis-anticipos (esta última sin `conductor` anidado,
  // porque ya se sabe de quién son). El anticipo cuelga directo de una `ruta`
  // (ver anticipoService.js: ANTICIPO_INCLUDE) — no hay una "programación"
  // separada; el nombre de ruta y el destino se leen de ruta / ruta.destino.
  factory Anticipo.fromJson(Map<String, dynamic> json) {
    final conductorJson = json['conductor'] as Map<String, dynamic>?;
    final usuarioJson = conductorJson?['usuario'] as Map<String, dynamic>?;
    final rutaJson = json['ruta'] as Map<String, dynamic>?;
    final destinoJson = rutaJson?['destino'] as Map<String, dynamic>?;

    String? destinoTexto;
    if (destinoJson != null) {
      final ciudad = destinoJson['ciudad'] ?? '';
      final departamento = destinoJson['departamento'] ?? '';
      destinoTexto = [ciudad, departamento].where((s) => (s as String).isNotEmpty).join(', ');
    }

    return Anticipo(
      id: int.tryParse(json['idAnticipoExcedente']?.toString() ?? '') ?? 0,
      idConductor: int.tryParse(json['idConductor']?.toString() ?? '') ?? 0,
      idRuta: int.tryParse(json['idRuta']?.toString() ?? '') ?? 0,
      valorAnticipo: _parseDouble(json['valorAnticipo']),
      valorGastado: _parseDouble(json['valorGastado']),
      excedente: _parseDouble(json['excedente']),
      estado: json['estado'] ?? EstadoAnticipo.entregado,
      habilitado: json['habilitado'] ?? true,
      // Subidas viejas hechas antes de corregir el backend (guardaba `undefined`
      // en vez de la URL real) quedaron como `null` sueltos dentro del array —
      // se descartan acá para no mostrar tarjetas de "soporte" sin URL real.
      soporte: (json['soporte'] as List?)?.where((e) => e != null).map((e) => e.toString()).toList() ?? const [],
      fechaEntrega: json['fechaEntrega']?.toString(),
      fechaLegalizacion: json['fechaLegalizacion']?.toString(),
      fechaEntregaExcedente: json['fechaEntregaExcedente']?.toString(),
      conductorNombre: usuarioJson != null
          ? '${usuarioJson['nombre'] ?? ''} ${usuarioJson['apellido'] ?? ''}'.trim()
          : '',
      nombreRuta: rutaJson?['origen'],
      destinoTexto: destinoTexto,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get tieneDeficit => excedente < 0;
  // Usado solo por el listado del admin (admin_home.dart) para habilitar el
  // ícono "Editar" — el admin únicamente gestiona el anticipo mientras sigue
  // "Entregado"; de ahí en adelante es tarea exclusiva del conductor. Mismo
  // criterio que el ícono deshabilitado en ListarAnticipoExcedente.jsx (web).
  bool get esEditable => estado == EstadoAnticipo.entregado;
}

// 'YYYY-MM-DD' (como llegan los campos DATEONLY del backend) -> 'DD/MM/YYYY'.
String formatFecha(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  final partes = iso.split('-');
  if (partes.length != 3) return iso;
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}

String formatCOP(double value) {
  final abs = value.abs();
  final formatted = abs.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return value < 0 ? '-\$$formatted' : '\$$formatted';
}

// Misma paleta de estado que usa el frontend web (getAnticipoEstadoDot en
// shared/utils/estadoColors.js), sobre los tokens ya existentes en AppColors.
Color estadoColor(String estado) {
  switch (estado) {
    case EstadoAnticipo.entregado:          return AppColors.purple;
    case EstadoAnticipo.enLegalizacion:     return AppColors.blue;
    case EstadoAnticipo.excedentePendiente: return AppColors.orange;
    case EstadoAnticipo.completado:         return AppColors.green;
    default:                                return AppColors.textSub;
  }
}

Color estadoBg(String estado) {
  switch (estado) {
    case EstadoAnticipo.entregado:          return AppColors.purpleBg;
    case EstadoAnticipo.enLegalizacion:     return AppColors.blueBg;
    case EstadoAnticipo.excedentePendiente: return AppColors.orangeBg;
    case EstadoAnticipo.completado:         return AppColors.greenBg;
    default:                                return AppColors.bgGray;
  }
}

// Paleta de estado para paquete.estado — los 4 valores reales que maneja el
// backend (ver src/services/paqueteStateUtils.js): Por entregar, En reparto,
// Entregado, Devuelto.
Color estadoPaqueteColor(String estado) {
  switch (estado) {
    case 'Por entregar': return AppColors.blue;
    case 'En reparto':   return AppColors.orange;
    case 'Entregado':    return AppColors.green;
    case 'Devuelto':     return AppColors.purple;
    default:              return AppColors.textSub;
  }
}

Color estadoPaqueteBg(String estado) {
  switch (estado) {
    case 'Por entregar': return AppColors.blueBg;
    case 'En reparto':   return AppColors.orangeBg;
    case 'Entregado':    return AppColors.greenBg;
    case 'Devuelto':     return AppColors.purpleBg;
    default:              return AppColors.bgGray;
  }
}