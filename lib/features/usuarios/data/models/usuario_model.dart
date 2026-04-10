import '../../domain/entities/usuario.dart';

class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    required super.nombre,
    required super.email,
    required super.telefono,
    required super.rol,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['idUsuario']?.toString() ?? json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      telefono: json['telefono'] ?? json['phone'] ?? '',
      rol: json['rol'] ?? json['role'] ?? 'conductor',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'rol': rol,
    };
  }

  static UsuarioModel fromEntity(Usuario usuario) {
    return UsuarioModel(
      id: usuario.id,
      nombre: usuario.nombre,
      email: usuario.email,
      telefono: usuario.telefono,
      rol: usuario.rol,
    );
  }
}